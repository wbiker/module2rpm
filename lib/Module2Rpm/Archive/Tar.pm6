use Module2Rpm::Role::Archive;

=begin pod

=TITLE
Module2Rpm::Role::Archive

Used tar parameters
=code
    -c  --create    Creates a new archive
    -t  --list      Lists the content of an archive.
    -x  --extract   Extract files from an archive.
    -J  --xz        Filter the archive through xz.
    -C              Change working directory before do work.

=end pod

class Module2Rpm::Archive::Tar does Module2Rpm::Role::Archive {
    method Extract(IO::Path $path) {
        my $proc = run 'tar', '-xf', $path.absolute, :cwd($path.parent);

        die "Tar extract failed for '{$path.absolute}'" if $proc.exitcode;
    }

    method Compress(IO::Path $path, Str $name --> IO::Path) {
        my $proc = run <tar --exclude-vcs -cJf>, $name, "-C", $path.parent.absolute, $path.basename, :cwd($path.parent);

        die "Tar compress failed for '$path'" if $proc.exitcode;

        return $path.parent.add($name);
    }

    method List(IO::Path $path --> Seq) {
        my $proc = run(<tar -tf>, $path.absolute, :out);

        die "Tar list archive failed for '$path'" if $proc.exitcode;

        return $proc.out.lines; #.map(*.substr($path.parent.chars));
    }
}
