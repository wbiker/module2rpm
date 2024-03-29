use Cro::WebApp::Template;
use Logger;

use Module2Rpm::Role::FindLibraryName;
use Module2Rpm::FindLibraryNameWithFindProvides;
use Module2Rpm::FindLibraryNameForOpenSuse;

=begin pod

=head1 Module2Rpm::Spec

Wrapper about all the data needed in an OBS spec file.

=head1 DESCRIPTION

This provides methods to get information about the data of a module.

=head2 Methods

=head3 get-spec-file(:$readme-file --> Str) {

Returns the spec file content as Str.

=end pod

class Module2Rpm::Spec {
    has $log = Logger.get;
    has $.metadata is required;
    has $.requires = 'raku >= 2016.12';
    has $.build-requires = "rakudo >= 2017.04.2";
    has Module2Rpm::Role::FindLibraryName $.find-rpm = Module2Rpm::FindLibraryNameForOpenSuse.new;

    method get-source-url( --> Str) {
        return $!metadata<source-url> || $!metadata<support><source>;
    }

    #| Returns the module name changed to raku-<module name with '::' replaced by '-'>.
    method get-name( --> Str) {
        die "Spec: Metadata does not provide module name!\n" ~ $!metadata.raku unless $!metadata<name>;

        return "raku-{ $!metadata<name>.subst: /'::'/, '-', :g }"
    }

    #| Returns the version found in the metadata. For '*' versions 0.1 is returned.
    method get-version() {
        die "Spec: No version found in metadata" unless $!metadata<version>;

        return $!metadata<version> eq '*' ?? '0.1' !! $!metadata<version>;
    }

    #| Returns a list of the provided files with the pattern:
    #| Provides:       raku(<name of the provided file>)
    method provides() {
        die "Spec: Metadata does not provide a module name" unless $!metadata<name>;

        return ($!metadata<name>, |$!metadata<provides>.keys).unique.sort.map({"Provides:       raku($_)\nProvides:       perl6($_)"}).join("\n");
    }

    #| Returns a list of the required modules with the pattern:
    #| Requires:       <name of the requirement>
    method requires() {
        my @requires = $!requires;

        if $!metadata<depends> {
            @requires.append: flat $!metadata<depends>.map({ self.map-dependency($_) })
                    if $!metadata<depends> ~~ Positional;
            @requires.append: flat $!metadata<depends><runtime><requires>.map({ self.map-dependency($_) })
                    if $!metadata<depends> ~~ Associative;
        }

        return @requires.grep( {$_} ).map({"Requires:       $_"});
    }

    method test-requires() {
        my @requires;

        if $!metadata<test-depends>  {
            @requires.append: flat $!metadata<test-depends>.map({ self.map-dependency($_) });
        }

        if $!metadata<depends><test><requires> {
            @requires.append: flat $!metadata<depends><test><requires>.map({ self.map-dependency($_) });
        }

        return @requires;
    }

    #| Returns a list of the build requirements with the pattern:
    #| BuildRequires:  <name of the build requirement>
    method build-requires()  {
        my @requires = $!build-requires;

        if $!metadata<depends> and $!metadata<depends> ~~ Positional {
            @requires.append: flat $!metadata<depends>.map({ self.map-dependency($_) })
        }

        if $!metadata<depends> and $!metadata<depends> ~~ Associative and $!metadata<depends><build><requires> {
            @requires.append: flat $!metadata<depends><build><requires>.map({ self.map-dependency($_) })
        }

        @requires.append: flat $!metadata<build-depends>.map({ self.map-dependency($_) }) if $!metadata<build-depends>;

        # Looks like the modules in the "builder" key can be also find in the depends<build><requires>
        # hash of the metadata. At least for Inline::Perl5. Disable it for now until I find a solution for that.
        #@requires.push: 'Distribution::Builder' ~ $!metadata<builder> if $!metadata<builder>;
        return @requires.grep( {$_} ).map({"BuildRequires:  $_"});
    }

    #| Obsoletes the old package before the Perl6 -> Raku rename
    method obsoletes( --> Str) {
        die "Spec: Metadata does not provide module name!\n" ~ $!metadata.raku unless $!metadata<name>;

        return "Obsoletes:      perl6-{ $!metadata<name>.subst: /'::'/, '-', :g }"
    }

    method map-dependency($requires is copy)  {
        $!log.debug("SPEC.map-dependency: '$requires'");
        # Ignoring certain modules, otherwise OBS would complain about missing requirements.
        return if self.is-ignored($requires);

        # This makes problems when trying to build Inline::Perl5
        # "depends": {
        #     "build": {
        #       "requires": [
        #         "Distribution::Builder::MakeFromJSON:ver<0.6+>",
        #         {
        #           "from": "bin",
        #           "name": "perl"
        #         }
        #       ]
        #     },

        my %adverbs;
        given $requires {
            when Str { %adverbs = flat ($requires ~~ s:g/':' $<key> = (\w+) '<' $<value> = (<-[>]>+) '>'//)
                .map({$_<key>.Str, $_<value>.Str}); }
                $!log.debug("SPEC.map-dependency: Transformed Requires into Hash");
            when Hash {
                $!log.debug("SPEC.map-dependency: Requires is already a Hash: {$requires.raku}'");
                %adverbs = $requires.Hash;
            }
        }

        $!log.debug("Found adverbs for module: " ~ %adverbs.raku);

        given %adverbs<from> {
            when 'native' {
                $!log.debug("Spec.map-dependency: Look for native library name: $requires");
                return $!find-rpm.find-rpm(:%adverbs, requires => $requires.IO);
            }
            when 'bin'    {
                if %adverbs<name> eq 'perl' {
                    $!log.debug("Bin requires: perl");
                    return "perl";
                }

                my $req ~= '%{_bindir}/' ~ %adverbs<name>;
                $!log.debug("Bin requires: $req");

                return $req;
            }
            default       {
                my $req = "raku($requires)";
                $!log.debug("Default requires: $req");
                return $req;
            }
        }

        $!log.debug("Spec.map-dependency: Library name '$requires'");
    }

    method is-ignored($requires) {
        # Ignore core modules:
        return True if $requires eq 'NativeCall'|'Test';

        return False;
    }

    method get-summary() {
        my $summary = $!metadata<description>;
        $summary.=chop if $summary and $summary.ends-with('.');
        return $summary;
    }

    #| Returns the spec file as String.
    method get-spec-file(:$readme-file, :$license-file, :$build-file --> Str) {
        $!log.debug("Metadata: " ~ $!metadata.raku);

        my $build-command = $build-file ?? "rakudo -e 'require Build:file(\"" ~ $build-file.basename ~ '".IO.absolute); ::("Build").build($*CWD.Str)\'' !! '';

        my %data;
        my $package-name = self.get-name();
        my $version = self.get-version();
        my $tar-name = "{$package-name}-$version.tar.xz";
        %data<package-name> = $package-name;
        %data<version> = $version;
        %data<license> = $!metadata<license> // 'Artistic-2.0';
        %data<summary> = self.get-summary();
        %data<source-url> = $!metadata<source-url> || $!metadata<support><source>;
        %data<tar-name> = $tar-name;
        %data<requires> = self.requires();
        %data<build-requires> = self.build-requires();
        %data<provides> = self.provides();
        %data<obsoletes> = self.obsoletes();
        %data<license_file> = $license-file ?? "\n%license {$license-file.basename}" !! '';
        %data<readme> = $readme-file ?? $readme-file.basename !! "";
        %data<build-file> = $build-command;

        my $spec_file_template = %?RESOURCES<spec_file.crotmp>.IO;
        my $spec_file_content = render-template($spec_file_template, %data);

        return $spec_file_content;
    }
}
