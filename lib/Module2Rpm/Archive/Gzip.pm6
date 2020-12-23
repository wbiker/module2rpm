use Module2Rpm::Role::Archive;

class Module2Rpm::Archive::Gzip does Module2Rpm::Role::Archive {
    method Compress(IO::Path $path, Str $name --> IO::Path) { die "Compress not implemented for gzip" }
    method List(IO::Path $path --> Seq) { die "List not implemented for gzip" }

    method Extract(IO::Path $path --> IO::Path) {
        die "$path does not exists" unless $path.e;

        my $proc = run "gzip", "-d", $path, :out, :merge;

        if $proc.exitcode != 0 {
            die "Could not decompress Library package file '$path': {$proc.out.slurp}";
        }

        my $compressed-file-name = $path.basename;
        $compressed-file-name ~~ s/'.gz'$//;

        my $extracted_file = $path.sibling($compressed-file-name).slurp(:close);
        die "Extracted gzip file not found: $extracted_file" unless $extracted_file.e;

        return $extracted_file;
    }
}

