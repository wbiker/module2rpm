use Logger;

=begin pod

=head1 Module2Rpm::Metadata

Wrapper about the package's metadata

=head1 DESCRIPTION

This provides methods to get information about the data of a module.

=head2 Methods

=end pod

class Module2Rpm::Requires {
    has $.name;
    has %.adverbs;
}

class Module2Rpm::Metadata {
    has $.log = Logger.get;
    has $.metadata is required;

    method get-source-url( --> Str) {
        return $!metadata<source-url> || $!metadata<support><source>;
    }

    method get-name( --> Str) {
        $!metadata<name> // die "Spec: Metadata does not provide a module name: " ~ $!metadata.raku
    }

    method get-provides( --> Hash) {
        $!metadata<provides>
    }

    method get-license( --> Str) {
        $!metadata<license> // 'Artistic-2.0';
    }

    #| Returns the module name changed to raku-<module name with '::' replaced by '-'>.
    method get-package-name( --> Str) {
        die "Metadata does not provide module name!\n" ~ $!metadata.raku unless $!metadata<name>;

        return "raku-{ $!metadata<name>.subst: /'::'/, '-', :g }"
    }

    #| Returns the version found in the metadata. For '*' versions 0.1 is returned.
    method get-version() {
        die "No version found in metadata" unless $!metadata<version>;

        return $!metadata<version> eq '*' ?? '0.1' !! $!metadata<version>;
    }

    method get-summary() {
        my $summary = $!metadata<description>;
        $summary.=chop if $summary and $summary.ends-with('.');
        return $summary;
    }

    #| Returns a list of the required modules with the pattern:
    #| Requires:       <name of the requirement>
    method requires() {
        my @requires;

        if $!metadata<depends> {
            @requires.append: flat $!metadata<depends>.map({ self.normalize-dependency($_) })
                    if $!metadata<depends> ~~ Positional;
            @requires.append: flat $!metadata<depends><runtime><requires>.map({ self.normalize-dependency($_) })
                    if $!metadata<depends> ~~ Associative;
        }

        @requires.grep( {$_} )
    }

    method test-requires() {
        my @requires;

        if $!metadata<test-depends>  {
            @requires.append: flat $!metadata<test-depends>.map({ self.normalize-dependency($_) });
        }

        if $!metadata<depends><test><requires> {
            @requires.append: flat $!metadata<depends><test><requires>.map({ self.normalize-dependency($_) });
        }

        @requires.grep( {$_} )
    }

    #| Returns a list of the build requirements with the pattern:
    #| BuildRequires:  <name of the build requirement>
    method build-requires()  {
        my @requires;

        if $!metadata<depends> and $!metadata<depends> ~~ Positional {
            @requires.append: flat $!metadata<depends>.map({ self.normalize-dependency($_) })
        }

        if $!metadata<depends> and $!metadata<depends> ~~ Associative and $!metadata<depends><build><requires> {
            @requires.append: flat $!metadata<depends><build><requires>.map({ self.normalize-dependency($_) })
        }

        @requires.append: flat $!metadata<build-depends>.map({ self.normalize-dependency($_) }) if $!metadata<build-depends>;
        # Looks like the modules in the "builder" key can be also find in the depends<build><requires>
        # hash of the metadata. At least for Inline::Perl5. Disable it for now until I find a solution for that.
        #@requires.push: 'Distribution::Builder' ~ $!metadata<builder> if $!metadata<builder>;

        @requires.grep( {$_} )
    }

    method normalize-dependency($requires is copy) {
        $!log.debug("Metadata.normalize-dependency: '$requires'");

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
            when Str {
                $!log.debug("Metadata.normalize-dependency: Transformed Requires into Hash");
                %adverbs =
                    flat ($requires ~~ s:g/':' $<key> = (\w+) '<' $<value> = (<-[>]>+) '>'//)
                    .map({$_<key>.Str, $_<value>.Str});
                %adverbs<name> //= $requires;
            }
            when Hash {
                $!log.debug("Metadata.normalize-dependency: Requires is already a Hash: {$requires.raku}'");
                %adverbs = $requires.Hash;
                $requires = %adverbs<name>;
            }
        }

        $!log.debug("Found adverbs for module: " ~ %adverbs.raku);

        # Ignoring certain modules, otherwise OBS would complain about missing requirements.
        return if self.is-ignored($requires);

        Module2Rpm::Requires.new(:name($requires), :%adverbs)
    }

    method is-ignored(Str $requires) {
        # Ignore core modules:
        return True if $requires eq 'NativeCall'|'Test';

        return False;
    }
}
