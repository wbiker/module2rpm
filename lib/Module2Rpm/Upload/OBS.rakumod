use XML;
use Logger;

use Module2Rpm::Role::Internet;
use Module2Rpm::Package;

=begin pod

=head1 Module2Rpm::Upload::OBS

=head2 More Infos
    L<https://build.opensuse.org/apidocs/index>

=head3 Methods

=head4 create-package(Module2Rpm::Package :$package)

Creates a package via API at https://build.opensuse.org/apidocs/index

=head4 upload-files(Module2Rpm::Package :$package!)

Uploads the source tar archive file and the spec file of a package.

=end pod

class Module2Rpm::Upload::OBS {
    has $!log = Logger.get;
    has Module2Rpm::Role::Internet $.client is required;
    has $.project is required;
    has Set $.packages;
    has $.api-url = 'https://api.opensuse.org';

    method package-exists(Str $package-name --> Bool) {
        self.get-packages();
        return $!packages{$package-name};
    }

    method create-package(Module2Rpm::Package :$package) {
        # Have to filter the description otherwise special characters like $ will break
        # the api.opensuse.org verifying check:
        # <status code="validation_failed">
        #  <summary>package validation error: 3:36: FATAL: xmlParseEntityRef: no name</summary>
        #</status>
        my $description = $package.metadata.get-summary();
        $description ~~ s:g/<-[\s \w]>+//;

        my $xml = qq:to/END/;
        <package name="{$package.module-name}" project="$!project">
            <title>{$package.module-name}</title>
            <description>{$description}</description>
        </package>
        END
        my $url = $!api-url ~ "/source/" ~ $!project  ~ "/" ~ $package.module-name ~ "/_meta";
        $!log.debug("Create package '$url'");
        $!client.put($url, content-type => "application/xml", body => $xml);
    }

    method delete-package(Module2Rpm::Package :$package!) {
        my $url = $!api-url ~ "/source/" ~ $!project ~ "/" ~ $package.module-name;
        $!log.debug("Delete package $url");
        $!client.delete($url);
    }

    method delete-all-packages() {
        self.get-packages();
        for $!packages.keys -> $package {
            $!log.info("Delete $package");
            my $url = $!api-url ~ "/source/" ~ $!project ~ "/" ~ $package;
            $!client.delete($url);
        }
    }

    method upload-files(Module2Rpm::Package :$package!) {
        if not self.package-exists($package.module-name) {
            $!log.debug("Create package {$package.module-name}");
            self.create-package(:$package);
        }

        for $package.source-files -> $name {
            my $url = $!api-url ~ "/source/" ~ $!project ~ "/" ~ $package.module-name ~ "/" ~ $name;
            my $content = $package.path.add($name).slurp(:bin, :close);
            $!log.info("{$package.module-name}: Upload file $name");
            $!client.put($url, content-type => "application/octet-stream", body => $content);
        }
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
        if $!packages.defined {
            $!log.debug("packages already cached. Skip download");
            return $!packages;
        }

        my $url = $!api-url ~ "/source/" ~ $!project;
        $!log.debug("Fetch packages from '$url'");
        my $xml = self.get($url);

        my @packages;
        for $xml.root -> $note {
            for $note.elements -> $element {
                @packages.push: $element.attribs<name>;
            }
        }

        $!packages = Set.new(@packages);
    }
}
