use Cro::WebApp::Template;
use Logger;

use Module2Rpm::Metadata;
use Module2Rpm::Role::FindLibraryName;
use Module2Rpm::FindLibraryNameWithFindProvides;
use Module2Rpm::FindLibraryNameForOpenSuse;

=begin pod

=head1 Module2Rpm::Deb

Creates Debian build files.

=head1 DESCRIPTION

Writes build files needed to create Debian packages for a given module.

=head2 Methods

=head3 write-debian-files(:$readme-file --> Str) {

Writes debian build files.

=end pod

class Module2Rpm::Deb {
    has Module2Rpm::Metadata $.metadata is required;
    has $.log = Logger.get;

    #| Returns a list of the provided files with the pattern:
    #| Provides:       raku(<name of the provided file>)
    method provides() {
        return ($!metadata.get-name, |$!metadata.get-provides.keys).unique.sort.map({"Provides:       raku($_)\nProvides:       perl6($_)"}).join("\n");
    }

    #| Returns a list of the required modules with the pattern:
    #| Requires:       <name of the requirement>
    method requires() {
        (
            '${misc:Depends}',
            '${raku:Depends}',
            'rakudo (>= 2022.07-2)',
            |$!metadata.requires.map({ self.map-dependency($_) })
        )
    }

    method test-requires() {
        $!metadata.test-requires.map({ self.map-dependency($_) })
    }

    #| Returns a list of the build requirements with the pattern:
    #| BuildRequires:  <name of the build requirement>
    method build-requires()  {
        (
            'debhelper-compat (= 13)',
            'dh-sequence-raku',
            'rakudo (>= 2022.07-2)',
            |$!metadata.build-requires.map({ self.map-dependency($_) }),
            |$!metadata.test-requires.map({ self.map-dependency($_) }),
        )
    }

    method map-dependency(Module2Rpm::Requires $requires)  {
        given $requires.adverbs<from> {
            when 'native' {
                $!log.debug("Deb.map-dependency: Look for native library name: $requires.name()");
                return "lib$requires.name()"; #TODO actually look for matching package
            }
            when 'bin'    {
                if $requires.name eq 'perl' {
                    $!log.debug("Bin requires: perl");
                    return "perl";
                }

                my $req = $requires.name; #TODO actually look for matching package
                $!log.debug("Bin requires: $req");

                return $req;
            }
            default       {
                my $req = "raku-{$requires.name.lc.subst('::', '-', :g)}";
                $!log.debug("Default requires: $req");
                return $req;
            }
        }
    }
    method write-build-files(IO::Path $path, :$build-file) {
        if $build-file {
            my $rules = %?RESOURCES<debian.rules.with-build>.IO;
            $path.add('debian.rules').spurt: render-template($rules, {file => $build-file.basename});
        }
        else {
            %?RESOURCES<debian.rules>.copy($path.add('debian.rules'), :createonly);
        }

        my $package-name = self.metadata.get-package-name.lc;
        my $version = S/^v// given $!metadata.get-version();
        my $timestamp = DateTime.now(formatter => {
            sprintf "%s, %d %s %d %02d:%02d:%02d +%02d00",
                <Mon Tue Wed Thu Fri Sat Sun>[.day-of-week - 1],
                .day,
                <Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec>[.month - 1],
                .year,
                .hour,
                .minute,
                .second,
                .offset-in-hours
        });

        $path.add('debian.control').spurt: qq:to/END/;
            Source: $package-name
            Maintainer: Stefan Seifert <stefan.seifert@rootprompt.at>
            Section: interpreters
            Priority: optional
            Build-Depends: $.build-requires.join(', ')
            Rules-Requires-Root: no
            Standards-Version: 4.6.1

            Package: $package-name
            Architecture: any
            Depends: $.requires.join(', ')
            Description: $!metadata.get-summary()
            END

        $path.add('debian.changelog').spurt: qq:to/END/;
            $package-name ($version) stable; urgency=medium

              * Upgrade to $version

             -- Stefan Seifert <stefan.seifert@rootprompt.at>  $timestamp
            END

        $path.add(self.metadata.get-package-name ~ '.dsc').spurt: qq:to/END/;
            Format: 1.0
            Source: $package-name
            Version: $version
            Binary: $package-name
            Maintainer: Stefan Seifert <stefan.seifert@rootprompt.at>
            Architecture: any
            Homepage: https://rootprompt.at
            Standards-Version: 4.6.1
            Build-Depends: $.build-requires.join(', ')
            END
    }
}
