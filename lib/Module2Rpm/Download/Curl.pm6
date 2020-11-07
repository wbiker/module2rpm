use Module2Rpm::Role::Download;

class Module2Rpm::Download::Curl does Module2Rpm::Role::Download {
    #| Curl commando with default parameter:
    #| -s silent
    has @curl-parameter = <curl -s>;

    method Download(Str $url, IO::Path $path?) {
        unless $path {
            my $proc = run @!curl-parameter, "--", $url, :out, :merge;
            die "Could not download '$url' with curl: {$proc.out.slurp(:close)}"  if $proc.exitcode;

            return $proc.out.slurp(:close);
        }

        my $proc = run @!curl-parameter, "-o", $path.absolute, "--", $url, :out, :merge;
        die "Could not download '$url' with curl: {$proc.out.slurp(:close)}"  if $proc.exitcode;
    }
}
