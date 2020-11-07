use Module2Rpm::Role::Download;

class Module2Rpm::Download::Git does Module2Rpm::Role::Download {
    method Download(Str $url, IO::Path $path) {
        # Git complains when the $path exists and is not empty. So check for more than '.' and '..'.
        die "$path already exists and is not empty" if $path.e and $path.dir.elems > 2;

        my $proc = run <git clone>, $url, $path.absolute, :out, :merge;
        die "Could not clone $url: {$proc.out.slurp(:close)}" if $proc.exitcode;
    }
}
