use Logger;

use Module2Rpm::Role::Archive;

=begin pod
=head1 Module2Rpm::Archive::Tar

Class to wrap commandline 'tar' command.

=head1 DESCRIPTION

This is used to create archives with the help of the commandline tool 'tar'. New archives are created in the
parent directory of the target directory. Extracting is done in the same directory as the archive file is.

=head1 SYNOPSYS

=begin code
my $tar = Module2Rpm::Archive::Tar.new;
my $archive-file = $tar.Compress("directory path".IO, "archiveName.tar.xz");

$tar.Extract($archive-file);
=end code

=head2 Used tar parameters
=begin code
    -c  --create    Creates a new archive
    -t  --list      Lists the content of an archive.
    -x  --extract   Extract files from an archive.
    -J  --xz        Filter the archive through xz.
    -C              Change working directory before do work.
    --exclude-vcs   Ignore vcs files. E.g.: .ignore for git repositories. Not
                        working in pipelines with docker and BusyBox v1.34.1. Use --exclude instead
=end code

=head2 Methods

=head3 Extract(IO::Path $path)

Extract the archive given by the $path parmater.

=head3 Compress(IO::Path $path, Str $name --> IO::Path)

Creates an archive from the given directory. The archive is created in the parent directory of the target directory
and xz compression is used.

=head3 List(IO::Path $path)

Returns all files in an archive.

=end pod

class Module2Rpm::Archive::Tar does Module2Rpm::Role::Archive {
    has $!log = Logger.get;

    method Extract(IO::Path $path) {
        $!log.debug("Extract $path");
        my $proc = run 'tar', '-xf', $path.absolute, :cwd($path.parent);

        die "Tar extract failed for '{$path.absolute}'" if $proc.exitcode;
    }

    method Compress(IO::Path $path, Str $name --> IO::Path) {
        $!log.debug("Compress $path with name $name");
        my $proc = run <tar --exclude=.git -cJf>, $name, "-C", $path.parent.absolute, $path.basename, :cwd($path.parent);

        die "Tar compress failed for '$path'" if $proc.exitcode;

        return $path.parent.add($name);
    }

    method List(IO::Path $path --> Seq) {
        $!log.debug("List $path");
        my $proc = run(<tar -tf>, $path.absolute, :out);

        die "Tar list archive failed for '$path'" if $proc.exitcode;

        return $proc.out.lines;
    }
}
