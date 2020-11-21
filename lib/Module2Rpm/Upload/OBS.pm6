use XML;
use Module2Rpm::Role::Upload;
=begin pod

=head1 Module2Rpm::Upload::OBS

=head2 More Infos
    L<https://build.opensuse.org/apidocs/index>

=end pod

class Module2Rpm::Upload::OBS {
    has Module2Rpm::Role::Upload $.client is required;
    has $.project is required;
    has Set $.packages;
    has $.api-url = 'https://api.opensuse.org';

    method package-exists(Str $package-name --> Bool) {
        self.get-packages();

        return $!packages{$package-name};
    }

    method delete-source-file(Module2Rpm::Package :$package) {
        my $url = $!api-url ~ "/source/" ~ $package.module-name ~ "/" ~ $package.tar-name;
        my $response = $!client.delete($url);

        say $response.status;
    }

    method get($url = "" --> XML::Document) {
        my $body = $!client.get($url);

        if $body ~~ Buf {
            my $str = $body.decode;
            say "appliaction/xml: ", $str;
            return from-xml($str);
        }

        if $body ~~ Str {
            say "text/xml: ", $body;
            return from-xml($body);
        }

        die "Unknown type received: {$body.WHAT}";
    }

    method get-packages() {
        return $!packages if $!packages;

        my $xml = self.get($!api-url ~ "/source/" ~ $!project);
        my @packages;
        for $xml.root -> $note {
            for $note.elements -> $element {
                @packages.push: $element.attribs<name>;
            }
        }

        $!packages = Set.new(@packages);
    }
}
