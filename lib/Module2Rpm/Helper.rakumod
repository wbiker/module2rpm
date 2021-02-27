use JSON::Fast;
use LWP::Simple;

use Module2Rpm::Role::Download;
use Module2Rpm::Cro::Client;
use Module2Rpm::Spec;
use Module2Rpm::Package;
use Module2Rpm::Internet::LWP;

=begin pod

=head1 Module2Rpm::Helper

Helper class for the module2rpm main script.

=head2 Methods

=head3 fetch-metadata()

Downloads the metadata for Raku modules from the ecosystem and returns a hash with them. Keys are module names.

=head3 create-packages(IO::Path :$path, IO::Path :$file)

Goes through a given file and handles each line that does not start with an '#' as either metadata url or Raku module name.
With the metadata a packages is created and finally all packages are returned as array.

=end pod

class Module2Rpm::Helper {
    has @metadata-sources =
            'https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/cpan1.json',
            'https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/p6c1.json';

    # Issue: https://github.com/croservices/cro-http/issues/122
    # FIX failing Cro::HTTP::Client here. For whatever reason the Cro::HTTP::Client dies to download one of the json
    # file. The error is:
    # Header table index 82 out of range
    #      in method resolve-decoded-index at /home/wolf/.rakubrew/versions/moar-2020.09/install/share/perl6/site/sources/4CC285A8AB160824E5A42DC6EF776B610FCEB2F9 (HTTP::HPACK) line 258
    #      in block  at /home/wolf/.rakubrew/versions/moar-2020.09/install/share/perl6/site/sources/4CC285A8AB160824E5A42DC6EF776B610FCEB2F9 (HTTP::HPACK) line 286
    #      in method decode-headers at /home/wolf/.rakubrew/versions/moar-2020.09/install/share/perl6/site/sources/4CC285A8AB160824E5A42DC6EF776B610FCEB2F9 (HTTP::HPACK) line 282
    #      in method set-headers at /home/wolf/.rakubrew/versions/moar-2020.09/install/share/perl6/site/sources/3523BF185071CC5AB875D8D00C04E400CF5777AB (Cro::HTTP2::GeneralParser) line 187
    #      in block  at /home/wolf/.rakubrew/versions/moar-2020.09/install/share/perl6/site/sources/3523BF185071CC5AB875D8D00C04E400CF5777AB (Cro::HTTP2::GeneralParser) line 101
    #      in block  at /home/wolf/.rakubrew/versions/moar-2020.09/install/share/perl6/site/sources/2FD61B909A901DA559CEDBC72E222C0CE26736D7 (Cro::HTTP2::FrameParser) line 93
    #      in block  at /home/wolf/.rakubrew/versions/moar-2020.09/install/share/perl6/site/sources/2FD61B909A901DA559CEDBC72E222C0CE26736D7 (Cro::HTTP2::FrameParser) line 45
    #      in block  at /home/wolf/.rakubrew/versions/moar-2020.09/install/share/perl6/site/sources/DDDD3607B617AC6B7DCA0D086AD3F4247AC394E9 (Cro::TLS) line 88
    # The fix is just to use LWP instead.
    #has Module2Rpm::Role::Internet $.client = Module2Rpm::Cro::Client.new();
    has Module2Rpm::Role::Internet $.client = Module2Rpm::Internet::LWP.new(lwp => LWP::Simple.new);

    method fetch-metadata( --> Hash) {
        my %all-metadata;
        my @all-metadata-unfiltered;
        for @!metadata-sources -> $url {
            #say "Fetch $url";
            my $json = $!client.get($url);
            #say "JSON: ", $json.raku;
            my $obj = from-json($json);
            #say "OBJ: ", $obj.raku;
            @all-metadata-unfiltered.append: $obj.flat;
            #say "all: ", @all-metadata-unfiltered.raku;
        }

        # my @all-metadata-unfiltered = @!metadata-sources
        #     .map({ from-json($!client.get($_))})
        #     .flat;

        # Filter for versions, otherwise not the metadata with the latest version could be in %all-metadata.
        for @all-metadata-unfiltered -> $metadata {
            if not %all-metadata{$metadata<name>}:exists {
               %all-metadata{$metadata<name>} = $metadata;
                next;
            }

            if Version.new($metadata<version>) > Version.new(%all-metadata{$metadata<name>}<version>)  {
                %all-metadata{$metadata<name>} = $metadata;
            }
        }

        return %all-metadata;
    }

    method create-packages(IO::Path :$path, IO::Path :$file) {
        die "$file does not exists" unless $file.e;

        my %all-metadata = self.fetch-metadata();

        my @packages;
        for $file.slurp.lines -> $line {
            next if self.is-comment($line);

            if self.is-meta-url($line) {
                say "Download metadata: '$line'";
                my $metadata = from-json($!client.get($line));
                my $spec = Module2Rpm::Spec.new(metadata => $metadata);
                my $package = Module2Rpm::Package.new(spec => $spec, path => $path);
                @packages.push: $package;
                next;
            }

            if self.is-module-name($line) {
                my $module-metadata = %all-metadata{$line.chomp};
                unless $module-metadata {
                    warn "Did not find metadata for module '$line'";
                    next;
                }

                my $spec = Module2Rpm::Spec.new(metadata => $module-metadata);
                my $package = Module2Rpm::Package.new(spec => $spec, path => $path);
                @packages.push: $package;
                next;
            }

            warn "Could not figure out whether '$line' is a source-url or module name";
        }

        return @packages;
    }

    method is-comment(Str $item) {
        return $item.starts-with('#');
    }

    method is-meta-url(Str $item) {
        return ($item.starts-with('http') and $item.ends-with('.meta') );
    }

    method is-module-name(Str $item) {
        return True if $item.contains('::');

        return False if self.is-meta-url($item);

        # Module names can be Module::Name or just ModuleName. So, when not a source url I expect them to be names.
        return True;
    }
}
