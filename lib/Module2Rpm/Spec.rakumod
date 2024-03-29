use Cro::WebApp::Template;
use Logger;

use Module2Rpm::Metadata;
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
    has Module2Rpm::Metadata $.metadata is required;
    has Module2Rpm::Role::FindLibraryName $.find-rpm = Module2Rpm::FindLibraryNameForOpenSuse.new;
    has $.log = Logger.get;
    has $.requires = 'raku >= 2016.12';
    has $.build-requires = "rakudo >= 2017.04.2";

    #| Returns a list of the provided files with the pattern:
    #| Provides:       raku(<name of the provided file>)
    method provides() {
        return ($!metadata.get-name, |$!metadata.get-provides.keys).unique.sort.map({"Provides:       raku($_)\nProvides:       perl6($_)"}).join("\n");
    }

    #| Returns a list of the required modules with the pattern:
    #| Requires:       <name of the requirement>
    method requires() {
        (
            $!requires,
            |$!metadata.requires.map({ self.map-dependency($_) })
        ).map({"Requires:       $_"})
    }

    method test-requires() {
        $!metadata.test-requires.map({ self.map-dependency($_) }).map({"TestRequires:   $_"})
    }

    #| Returns a list of the build requirements with the pattern:
    #| BuildRequires:  <name of the build requirement>
    method build-requires()  {
        (
            $!build-requires,
            |$!metadata.build-requires.map({ self.map-dependency($_) })
        ).map({"BuildRequires:  $_"})
    }

    #| Obsoletes the old package before the Perl6 -> Raku rename
    method obsoletes( --> Str) {
        return "Obsoletes:      perl6-{ $!metadata.get-name.subst: /'::'/, '-', :g }"
    }

    method map-dependency(Module2Rpm::Requires $requires)  {
        given $requires.adverbs<from> {
            when 'native' {
                $!log.debug("Spec.map-dependency: Look for native library name: $requires.name()");
                return $!find-rpm.find-rpm(:adverbs($requires.adverbs), requires => $requires.name.IO);
            }
            when 'bin'    {
                if $requires.name eq 'perl' {
                    $!log.debug("Bin requires: perl");
                    return "perl";
                }

                my $req ~= '%{_bindir}/' ~ $requires.name;
                $!log.debug("Bin requires: $req");

                return $req;
            }
            default       {
                my $req = "raku($requires.name())";
                $!log.debug("Default requires: $req");
                return $req;
            }
        }
    }

    #| Returns the spec file as String.
    method get-spec-file(:$readme-file, :$license-file, :$build-file --> Str) {
        $!log.debug("Metadata: " ~ $!metadata.raku);

        my $build-command = $build-file ?? "rakudo -e 'require Build:file(\"" ~ $build-file.basename ~ '".IO.absolute); ::("Build").build($*CWD.Str)\'' !! '';

        my %data;
        my $package-name = self.metadata.get-package-name();
        my $version = $!metadata.get-version();
        my $tar-name = "{$package-name}-$version.tar.xz";
        %data<package-name> = $package-name;
        %data<version> = $version;
        %data<license> = $!metadata.get-license;
        %data<summary> = $!metadata.get-summary();
        %data<source-url> = $!metadata.get-source-url;
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
