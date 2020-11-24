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

    method create-package(Module2Rpm::Package :$package) {
        my $xml = qq:to/END/;
        <package name="{$package.module-name}" project="$!project">
            <title>{$package.module-name}</title>
            <description>{$package.spec.get-summary()}</description>
        </package>
        END
        my $url = $!api-url ~ "/source/" ~ $!project  ~ "/" ~ $package.module-name ~ "/_meta";
        $!client.put($url, content-type => "application/xml", body => $xml);
    }

    method delete-package(Module2Rpm::Package :$package!) {
        my $url = $!api-url ~ "/source/" ~ $!project ~ "/" ~ $package.module-name;
        $!client.delete($url);
    }

    method upload-files(Module2Rpm::Package :$package!) {
        if self.package-exists($package.module-name) {
            self.delete-package(:$package);
        }
        self.create-package(:$package);

        my $url-source-archive = $!api-url ~ "/source/" ~ $!project ~ "/" ~ $package.module-name ~ "/" ~ $package.tar-name;
        my $url-spec-file = $!api-url ~ "/source/" ~ $!project ~ "/" ~ $package.module-name ~ "/" ~ $package.spec-file-name;

        my $tar-archive-binary-content = $package.tar-archive-path.slurp(:bin, :close);
        my $spec-file-content = $package.spec-file-path.slurp(:close);

        $!client.put($url-source-archive,
            content-type => "application/octet-stream",
            body => $tar-archive-binary-content
        );

        $!client.put($url-spec-file,
            content-type => "text/html",
            body => $spec-file-content
        );
    }
    method get($url = "" --> XML::Document) {
        my $body = $!client.get($url);

        if $body ~~ Buf {
            my $str = $body.decode;
            return from-xml($str);
        }

        if $body ~~ Str {
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
