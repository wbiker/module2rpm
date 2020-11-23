use File::Temp;

use Module2Rpm::Spec;
use Module2Rpm::Archive::Tar;
use Module2Rpm::Download::Git;
use Module2Rpm::Download::Curl;
use Module2Rpm::Role::Download;

class Module2Rpm::Package {
    #| Class that handles spec file parameter.
    has Module2Rpm::Spec $.spec is required;
    #| The path where the module source tarball and spec file are created.
    has IO::Path $.path;
    #| Name of the module with the pattern: perl6-<module name with :: replaced by ->.
    has Str $.module-name;
    #| Module name with version: perl6-<module-name>-<version>
    has Str $.module-name-with-version;
    #| The tarball file name with the pattern: perl6-<module name>-<version>.tar.xz.
    has Str $.tar-name;
    #| The source url found in the metadata.
    has Str $.source-url;
    #| The spec file name.
    has Str $.spec-file-name;
    #| Path of the local tar archive.
    has IO::Path $.tar-archive-path;
    #| Path of the local spec file.
    has IO::Path $.spec-file-path;
    #| The readme file of the package.
    has IO::Path $.readme-file;

    #| Class used to download via Curl.
    has Module2Rpm::Role::Download $.curl;
    #| Class used to clone with Git.
    has Module2Rpm::Role::Download $.git;
    #| Class used to compress, extract and list with Tar.
    has Module2Rpm::Role::Archive $.tar;

    submethod BUILD(Module2Rpm::Spec :$spec,
            IO::Path :$path,
            Module2Rpm::Role::Download :$curl = Module2Rpm::Download::Curl.new,
            Module2Rpm::Role::Download :$git = Module2Rpm::Download::Git.new,
            Module2Rpm::Role::Archive :$tar = Module2Rpm::Archive::Tar.new) {

        $!spec = $spec;
        $path.mkdir unless $path.e;

        $!module-name = $spec.get-name();
        $!module-name-with-version = $!module-name ~ "-" ~ $!spec.get-version;
        $!path = $path.add($!module-name);
        $!path.mkdir unless $!path.e;

        $!tar-name = "{$!module-name}-{$!spec.get-version()}.tar.xz";
        $!source-url = $!spec.get-source-url();

        $!spec-file-name = $!module-name ~ ".spec";
        $!spec-file-path = $!path.add($!spec-file-name);
        $!tar-archive-path = $!path.add($!tar-name);

        $!curl = $curl;
        $!git = $git;
        $!tar = $tar;
    };

    #| Downloads the source in a temporary folder and uses tar to create a compressed archive of it.
    #| In case of a tarball file as source, the archive is extracted an the root folder is renamed to the module name.
    #| Then the root folder is compressed with tar again and the archive file is copied to the destination.
    method Download() {
        my $download-dir = tempdir().IO;
        my $downloaded-item = $download-dir.add($!module-name ~ ".tmp");

        if self.is-git-repository() {
            $!git.Download($!source-url, $downloaded-item);
            my $git-repo-tar-archive-path = $!tar.Compress($downloaded-item, $!tar-name);
            $git-repo-tar-archive-path.copy($!tar-archive-path);
            return;
        }

        # Download source as .tar.gz archive file in an temporary folder and extract it.
        $!curl.Download($!source-url, $downloaded-item);
        $!tar.Extract($downloaded-item);

        # Rename the root folder of the extracted archive to: perl6-<module-name>.
        my @top-level-dirs = $download-dir.dir.grep(* ~~ :d);
        die "Too many top level directories: @top-level-dirs" if @top-level-dirs.elems != 1;
        my $top-level-dir = @top-level-dirs[0].basename;
        my $module-name-path = $download-dir.add($!module-name-with-version);
        @top-level-dirs[0].rename($module-name-path);
        $!readme-file = self.get-readme($module-name-path);

        # Compress sources with renamed folder as perl6-<module name>-<version>.tar.xz.
        my $tmp-tar-archive-path = $!tar.Compress($module-name-path, $!tar-name);
        $tmp-tar-archive-path.copy($!tar-archive-path);
    }

    method write-spec-file() {
        my $spec-file-content = $!spec.get-spec-file(readme-file => $!readme-file);
        $!spec-file-path.spurt($spec-file-content);
    }

    method is-git-repository() {
        return ($!source-url.starts-with('git://') or $!source-url.ends-with('.git'));
    }

    method get-readme(IO::Path $path) {
       for $path.dir -> $item {
           return $item if $item.basename ~~ /'README'/;
       }
    }
}
