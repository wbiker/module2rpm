use File::Temp;
use Logger;

use Module2Rpm::Spec;
use Module2Rpm::Archive::Tar;
use Module2Rpm::Download::Git;
use Module2Rpm::Role::Download;
use Module2Rpm::Role::Internet;
use Module2Rpm::Cro::Client;

=begin pod

=head1 Module2Rpm::Package

This represents a Open Build Service package. See L<https://build.opensuse.org> for more information about OBS.
A OBS package contains a tar archive with the source code and a spec file with the needed information for building RPM packages.

=end pod

class Module2Rpm::Package {
    #| Logging
    has $!log = Logger.get;

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

    #| The license file of the package.
    has IO::Path $.license-file;

    #| Class used to download via Cro::HTTP::Client.
    has Module2Rpm::Role::Internet $.client;

    #| Class used to clone with Git.
    has Module2Rpm::Role::Download $.git;

    #| Class used to compress, extract and list with Tar.
    has Module2Rpm::Role::Archive $.tar;

    submethod BUILD(Module2Rpm::Spec :$spec,
            IO::Path :$path,
            Module2Rpm::Role::Internet :$client = Module2Rpm::Cro::Client.new,
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

        $!client = $client;
        $!git = $git;
        $!tar = $tar;
    };

    #| Downloads the source in a temporary folder and uses tar to create a compressed archive of it.
    #| In case of a tarball file as source, the archive is extracted an the root folder is renamed to the module name.
    #| Then the root folder is compressed with tar again and the archive file is copied to the destination.
    method Download() {
        my $download-dir = tempdir().IO;
        $!log.debug("Temporary download folder: $download-dir");
        my $downloaded-item;

        if self.is-git-repository() {
            $!log.debug("Git repository found");
            $downloaded-item = $download-dir.add($!module-name-with-version);
            $!log.debug("Download $!source-url to $downloaded-item");
            $!git.Download($!source-url, $downloaded-item);
            my $git-repo-tar-archive-path = $!tar.Compress($downloaded-item, $!tar-name);
            $git-repo-tar-archive-path.copy($!tar-archive-path);
            return;
        }

        $downloaded-item = $download-dir.add($!module-name ~ ".tmp");
        $!log.debug("Download tar.gz file to $downloaded-item");
        # Download source as .tar.gz archive file in an temporary folder and extract it.
        my $file-content;
        try {
            $!log.debug("Fetch $!source-url");
            $file-content = $!client.get($!source-url);

            CATCH { default { die "Could not download module source: {$!source-url} - {$_.message()}" }; }
        }

        $downloaded-item.spurt($file-content);
        $!tar.Extract($downloaded-item);

        # Rename the root folder of the extracted archive to: perl6-<module-name>.
        my @top-level-dirs = $download-dir.dir.grep(* ~~ :d);
        die "Too many top level directories: @top-level-dirs" if @top-level-dirs.elems != 1;
        my $module-name-path = $download-dir.add($!module-name-with-version);
        @top-level-dirs[0].rename($module-name-path);

        # Store readme file name for adding it to the spec file.
        self.set-readme($module-name-path);

        # Store license file name for adding it to the spec file.
        self.set-license-file($module-name-path);

        # Compress sources with renamed folder as perl6-<module name>-<version>.tar.xz.
        self.compress($module-name-path);
    }

    #| Writes the spec file in the given path.
    method write-spec-file() {
        my $spec-file-content = $!spec.get-spec-file(
            readme-file  => $!readme-file.IO,
            license-file => $!license-file.IO
        );
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

    method get-license-file(IO::Path $path) {
       for $path.dir -> $item {
           return $item if $item.basename ~~ /'LICENSE'/;
       }
    }

    method set-readme(IO::Path $path) {
        $!readme-file = self.get-readme($path);
    }

    method set-license-file(IO::Path $path) {
        $!license-file = self.get-license-file($path);
    }

    method compress($module-name-path) {
        my $tmp-tar-archive-path = $!tar.Compress($module-name-path, $!tar-name);
        $tmp-tar-archive-path.copy($!tar-archive-path);
    }
}
