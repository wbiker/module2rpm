use Module2Rpm::Metadata;

class Module2Rpm::Spec {
    has $.requires = 'perl6 >= 2016.12';
    has $.build-requires = 'rakudo >= 2017.04.2';

    method get-name(:$meta --> Str) {
        die "Metadata does not provide module name!" unless $meta<name>;

        return "perl6-{ $meta<name>.subst: /'::'/, '-', :g }"
    }

    method get-version(:$meta) {
        die "No version found in metadata" unless $meta<version>;

        return $meta<version> eq '*' ?? '0.1' !! $meta<version>;
    }

    method provides(:$meta!) {
        die "Metadata does not provide a module name" unless $meta<name>;

        return ($meta<name>, |$meta<provides>.keys).unique.sort.map({"Provides:       perl6($_)"}).join("\n");
    }

    method requires(:$meta!) is export {
        my @requires = $!requires;

        if $meta<depends> {
            @requires.append: flat $meta<depends>.map({ self.map-dependency($_) })
                    if $meta<depends> ~~ Positional;
            @requires.append: flat $meta<depends><runtime><requires>.map({ self.map-dependency($_) })
                    if $meta<depends> ~~ Associative;
        }

        return @requires.map({"Requires:       $_"}).join("\n");
    }

    method build-requires(:$meta!) is export {
        my @requires = $!build-requires;

        if $meta<depends> {
            @requires.append: flat $meta<depends>.map({ self.map-dependency($_) })
                    if $meta<depends> ~~ Positional;
            @requires.append: flat $meta<depends><build><requires>.map({ self.map-dependency($_) })
                    if $meta<depends> ~~ Associative;
        }

        @requires.append: flat $meta<build-depends>.map({ self.map-dependency($_) })
                if $meta<build-depends>;
        @requires.push: 'Distribution::Builder' ~ $meta<builder> if $meta<builder>;
        return @requires.map({"BuildRequires:  $_"}).join("\n");
    }

    method map-dependency($requires is copy) is export {
        my %adverbs = flat ($requires ~~ s:g/':' $<key> = (\w+) '<' $<value> = (<-[>]>+) '>'//)
                .map({$_<key>.Str, $_<value>.Str});
        given %adverbs<from> {
            when 'native' {
                if %adverbs<ver> {
                    my $lib = $*VM.platform-library-name($requires.IO, :version(Version.new(%adverbs<ver>)));
                    my $path = </usr/lib64 /lib64 /usr/lib /lib>.first({$_.IO.add($lib).e});
                    if $path {
                        my $proc = run '/usr/lib/rpm/find-provides', :in, :out;
                        $proc.in.say($path.IO.add($lib).resolve.Str);
                        $proc.in.close;
                        $proc.out.lines;
                    }
                    else {
                        note "Falling back to depending on the library path as I couldn't find $lib";
                        '%{_libdir}/' ~ $*VM.platform-library-name($requires.IO)
                    }
                }
                else {
                    note "Package doesn't specify a library version, so I have to fall back to depending on library path.";
                    '%{_libdir}/' ~ $*VM.platform-library-name($requires.IO)
                }
            }
            when 'bin'    { '%{_bindir}/' ~ $requires }
            default       { "perl6($requires)" }
        }
    }

    method get-spec-file(Hash $meta --> Str) {
        my $package-name = self.get-name(:$meta);
        my $version = self.get-version(:$meta);
        my $license = $meta<license> // '';
        my $summary = $meta<description>;
        $summary.=chop if $summary and $summary.ends-with('.');
        my $source-url = $meta<source-url> || $meta<support><source>;
        my $tar-name = "{$package-name}-$version.tar.xz";
        my $source = $meta<tar-name>;
        my $requires = self.requires(:$meta);
        my $build-requires = self.build-requires(:$meta);
        my $provides = self.provides(:$meta);
        my $LICENSE = $meta<license-file> ?? "\n%license {$meta<license-file>}" !! '';
        my $RPM_BUILD_ROOT = '$RPM_BUILD_ROOT'; # Workaround for https://rt.perl.org/Ticket/Display.html?id=127226

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
        Source:         $tar-name
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
        %doc README.md$LICENSE
        %{_datadir}/perl6/vendor
        %changelog
        TEMPLATE
    }
}
