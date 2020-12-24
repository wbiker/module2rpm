use Module2Rpm::Role::Archive;

class Module2Rpm::Archive::Gzip does Module2Rpm::Role::Archive {
    method Compress(IO::Path $path, Str $name --> IO::Path) { die "Compress not implemented for gzip" }
    method List(IO::Path $path --> Seq) { die "List not implemented for gzip" }

    method Extract(IO::Path $path) {
        die "Gzip: $path does not exists" unless $path.e;

        my $proc = run "gzip", "-d", $path, :out, :merge;

        if $proc.exitcode != 0 {
            die "Gzip: Could not decompress Library package file '$path': {$proc.out.slurp}";
        }

        my $compressed-file-name = $path.basename;
        $compressed-file-name ~~ s/'.gz'$//;

        my $extracted_file_io = $path.sibling($compressed-file-name);
        die "Gzip: Extracted gzip file not found: $extracted_file_io" unless $extracted_file_io.e;

        return $extracted_file_io.slurp;
    }
}

