use LogP6;

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

class Module2Rpm::Spec:ver<0.0.3> {
    has $!log = get-logger($?CLASS.^name);
    has $.metadata is required;
    has $.requires = 'perl6 >= 2016.12';
    has $.build-requires = "rakudo >= 2017.04.2";
    has Module2Rpm::Role::FindLibraryName $.find-rpm = Module2Rpm::FindLibraryNameForOpenSuse.new;

    method get-source-url( --> Str) {
        return $!metadata<source-url> || $!metadata<support><source>;
    }

    #| Returns the module name changed to perl6-<module name with '::' replaced by '-'>.
    method get-name( --> Str) {
        die "Spec: Metadata does not provide module name!\n" ~ $!metadata.raku unless $!metadata<name>;

        return "perl6-{ $!metadata<name>.subst: /'::'/, '-', :g }"
    }

    #| Returns the version found in the metadata. For '*' versions 0.1 is returned.
    method get-version() {
        die "Spec: No version found in metadata" unless $!metadata<version>;

        return $!metadata<version> eq '*' ?? '0.1' !! $!metadata<version>;
    }

    #| Returns a list of the provided files with the pattern:
    #| Provides:       perl6(<name of the provided file>)
    method provides() {
        die "Spec: Metadata does not provide a module name" unless $!metadata<name>;

        return ($!metadata<name>, |$!metadata<provides>.keys).unique.sort.map({"Provides:       perl6($_)"}).join("\n");
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

        return @requires.grep( {$_} ).map({"Requires:       $_"}).join("\n");
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
        return @requires.grep( {$_} ).map({"BuildRequires:  $_"}).join("\n");
    }

    method map-dependency($requires is copy)  {
        $!log.debug("SPEC.map-dependency: '$requires'");
        # Ignoring certain modules, otherwise OBS would complain about missing requirements.
        return if self.is-ignored($requires);

        if $requires ~~ Hash {
            # If dependency comes as Hash I do not know what I should do whith that.
            return "";
        }

        my %adverbs = flat ($requires ~~ s:g/':' $<key> = (\w+) '<' $<value> = (<-[>]>+) '>'//).map({$_<key>.Str => $_<value>.Str});

        $!log.debug("Found adverbs for module: " ~ %adverbs.raku);

        given %adverbs<from> {
            when 'native' {
                $!log.debug("Spec.map-dependency: Look for native library name: $requires");
                return $!find-rpm.find-rpm(:%adverbs, requires => $requires.IO);
            }
            when 'bin'    {
                my $req = '%{_bindir}/' ~ $requires;
                $!log.debug("Bin requires: $req");
                return $req;
            }
            default       {
                my $req = "perl6($requires)";
                $!log.debug("Default requires: $req");
                return $req;
            }
        }

        $!log.debug("Spec.map-dependency: Library name '$requires'");
    }

    method is-ignored($requires) {
        # Ignore core modules:
        return True if $requires ~~ /'NativeCall' | 'Test' /;

        return False;
    }

    method get-summary() {
        my $summary = $!metadata<description>;
        $summary.=chop if $summary and $summary.ends-with('.');
        return $summary;
    }

    #| Returns the spec file as String.
    method get-spec-file(:$readme-file, :$license-file --> Str) {
        $!log.debug("Metadata: " ~ $!metadata.raku);

        my $package-name = self.get-name();
        my $version = self.get-version();
        my $license = $!metadata<license> // 'Artistic-2.0';
        my $summary = self.get-summary();
        my $source-url = $!metadata<source-url> || $!metadata<support><source>;
        my $tar-name = "{$package-name}-$version.tar.xz";
        my $requires = self.requires();
        my $build-requires = self.build-requires();
        my $provides = self.provides();
        my $LICENSE = $license-file ?? "\n%license {$license-file.basename}" !! '';
        my $RPM_BUILD_ROOT = '$RPM_BUILD_ROOT'; # Workaround for https://rt.perl.org/Ticket/Display.html?id=127226
        my $readme = $readme-file ?? $readme-file.basename !! "";

        my $template = q:s:to/TEMPLATE/;
        #
        # spec file for package $package-name
        #
        # Copyright (c) 2017 SUSE LINUX Products GmbH, Nuernberg, Germany.
        #
        # All modifications and additions to the file contributed by third parties
        # remain the property of their copyright owners, unless otherwise agreed
        # upon. The license for this file, and modifications and additions to the
        # file, is the same license as for the pristine package itself (unless the
        # license for the pristine package is not an Open Source License, in which
        # case the license is the MIT License). An "Open Source License" is a
        # license that conforms to the Open Source Definition (Version 1.9)
        # published by the Open Source Initiative.
        # Please submit bugfixes or comments via http://bugs.opensuse.org/
        #
        Name:           $package-name
        Version:        $version
        Release:        1.1
        License:        $license
        Summary:        $summary
        Url:            $source-url
        Group:          Development/Languages/Other
        Source0:        $tar-name
        BuildRequires:  fdupes
        $build-requires
        $requires
        $provides
        BuildRoot:      %{_tmppath}/%{name}-%{version}-build
        %description
        $summary
        %prep
        %setup -q
        %build
        %install
        RAKUDO_MODULE_DEBUG=1 RAKUDOE_PRECOMP_VERBOSE=1 RAKUDO_RERESOLVE_DEPENDENCIES=0 raku --ll-exception %{_datadir}/perl6/bin/install-perl6-dist \\
                --to=$RPM_BUILD_ROOT%{_datadir}/perl6/vendor \\
                --for=vendor \\
                --from=.
        %fdupes %{buildroot}/%{_datadir}/perl6/vendor
        rm -f %{buildroot}%{_datadir}/perl6/vendor/bin/*-j
        rm -f %{buildroot}%{_datadir}/perl6/vendor/bin/*-js
        find %{buildroot}/%{_datadir}/perl6/vendor/bin/ -type f -exec sed -i -e '1s:!/usr/bin/env :!/usr/bin/:' '{}' \;
        %files
        %defattr(-,root,root)
        %doc $readme$LICENSE
        %{_datadir}/perl6/vendor
        %changelog
        TEMPLATE
    }
}
