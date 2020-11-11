use File::Temp;

use Module2Rpm::Spec;
use Module2Rpm::Metadata;
use Module2Rpm::Archive::Tar;
use Module2Rpm::Download::Git;
use Module2Rpm::Download::Curl;

class Module2Rpm::Package {
    #| Class that handles spec file parameter.
    has Module2Rpm::Spec $.spec is required;
    #| The path where the module source tarball and spec file are created.
    has IO::Path $.path;
    #| Name of the module with the pattern: perl6-<module name with :: replaced by ->.
    has Str $.module-name;
    #| The tarball file name with the pattern: perl6-<module name>-<version>.tar.xz.
    has Str $.tar-name;
    #| The source url found in the metadata.
    has Str $.source-url;

    submethod BUILD(Module2Rpm::Spec :$spec, IO::Path :$path) {
        $!spec = $spec;
        $path.mkdir unless $path.e;

        $!module-name = $spec.get-name();
        $!path = $path.add($!module-name);
        $!path.mkdir unless $!path.e;

        $!tar-name = "{$!module-name}-{$!spec.get-version()}.tar.xz";
        $!source-url = $!spec.get-source-url();
    };

    #| Downloads the source and uses tar to create a compressed archive of it.
    method Download() {
        my $tar = Module2Rpm::Archive::Tar.new;

        if self.is-git-repository() {
            my $temp-dir = tempdir().IO;
            my $git-repo-dir = $temp-dir.add($!module-name);
            Module2Rpm::Download::Git.new.Download($!source-url, $git-repo-dir);
            my $git-repo-tar-archive-path = $tar.Compress($git-repo-dir, $!tar-name);
            $git-repo-tar-archive-path.copy($!path.add($!tar-name));
            return;
        }

        # Download source as .tar.gz archive file and extract it.
        my $download-path = tempdir().IO;
        my $downloaded-file-path = $download-path.add('downloadfile.gz');
        Module2Rpm::Download::Curl.new.Download($!source-url, $downloaded-file-path);
        $tar.Extract($downloaded-file-path);

        # Rename the root folder of the extracted archive to: perl6-<module-name>.
        my @top-level-dirs = $download-path.dir.grep(* ~~ :d);
        die "Too many top level directories: @top-level-dirs" if @top-level-dirs.elems != 1;
        my $top-level-dir = @top-level-dirs[0].basename;
        my $module-name-path = $download-path.add($!spec.get-name());
        @top-level-dirs[0].rename($module-name-path);

        # Compress sources with renamed folder as perl6-<module name>-<version>.tar.xz.
        my $tar-archive-path = $tar.Compress($module-name-path, $!tar-name);
        $tar-archive-path.copy($!path.add($!tar-name));
    }

    method write-spec-file() {
        my $spec-file-content = $!spec.get-spec-file();
        $!path.add($!module-name ~ ".spec").spurt($spec-file-content);
    }

    method is-git-repository() {
        return ($!source-url.starts-with('git://') or $!source-url.ends-with('.git'));
    }
}
