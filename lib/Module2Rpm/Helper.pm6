use JSON::Fast;

use Module2Rpm::Role::Download;
use Module2Rpm::Cro::Client;
use Module2Rpm::Spec;
use Module2Rpm::Package;

class Module2Rpm::Helper {
    has @metadata-sources =
            'https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/cpan1.json',
            'https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/p6c1.json';

    has Module2Rpm::Role::Internet $.client = Module2Rpm::Cro::Client.new;

    method fetch-metadata( --> Hash) {
        my %all-metadata = @!metadata-sources
                .map({from-json($!client.get($_))})
                .flat
                .map({$_<name> => $_ }).Hash;

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
