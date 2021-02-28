use LogP6;

use Module2Rpm::Role::Download;

=begin pod

=head1 Module2Rpm::Download::Git

Clones a git repository into a given path.

=head1 SYNOPSIS

=begin code
Module2Rpm::Download::Git.new.Download($url, $path);
=end code

=end pod

class Module2Rpm::Download::Git does Module2Rpm::Role::Download {
    has $!log = get-logger($?CLASS.^name);

    method Download(Str $url, IO::Path $path) {
        # Git complains when the $path exists and is not empty. So check for more than '.' and '..'.
        $!log.debug("Clone $url");
        die "$path already exists and is not empty" if $path.e and $path.dir.elems > 2;

        my $proc = run <git clone>, $url, $path.absolute, :out, :merge;
        die "Could not clone $url: {$proc.out.slurp(:close)}" if $proc.exitcode;
    }
}
