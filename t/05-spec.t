use Test;
use Test::Mock;
use File::Temp;
use lib './lib';

use Module2Rpm::Spec;

dies-ok { Module2Rpm::Spec.new }, "Dies without metadata";

{
    my $spec = Module2Rpm::Spec.new(metadata => {});
    dies-ok { $spec.get-name() }, "Get-name dies without module name";
}

{
    my $spec = Module2Rpm::Spec.new(metadata => { name => "Module::Name" });
    is $spec.get-name(), "raku-Module-Name", "Get-Name returns expected name";
}

{
    my $spec = Module2Rpm::Spec.new(metadata => {
        name => 'ModuleName',
        provides => { 'ModuleName' => 'lib/ModuleName' }
    });
    is $spec.provides(), "Provides:       raku(ModuleName)\nProvides:       perl6(ModuleName)", "Provides returns proper string";
}

{
    my $spec = Module2Rpm::Spec.new(metadata => {
        name => 'ModuleName',
        provides => {   'ModuleName' => 'lib/ModuleName',
                        'ModuleName::Name' => 'lib/ModuleName/Name' }
    });
    is $spec.provides(), chomp(q:to/SPEC/), "Provides returns proper string";
        Provides:       raku(ModuleName)
        Provides:       perl6(ModuleName)
        Provides:       raku(ModuleName::Name)
        Provides:       perl6(ModuleName::Name)
        SPEC
}

{
    my $spec = Module2Rpm::Spec.new(metadata => {
        name => 'ModuleName',
    });
    is $spec.obsoletes(), chomp(q:to/SPEC/), "Obsoletes the Perl6 package";
        Obsoletes:      perl6-ModuleName
        SPEC
}

{
    my $spec = Module2Rpm::Spec.new(metadata => {});
    is $spec.requires(), "Requires:       raku >= 2016.12", "Requires returns one dependency";
}

{
    my $spec = Module2Rpm::Spec.new(metadata => { depends => ['Dependency', 'Test::Assertion']});

    my @expected =
        "Requires:       raku >= 2016.12",
        "Requires:       raku(Dependency)",
        "Requires:       raku(Test::Assertion)";
    is $spec.requires(), @expected, "Requires returns several dependencies";
}

{
    my $spec = Module2Rpm::Spec.new(metadata => { depends => ["Method::Also", "Test"] });

    my @expected =
        "Requires:       raku >= 2016.12",
        "Requires:       raku(Method::Also)";
    is $spec.requires(), @expected, "Requires returns one dependency";
}

{
    my $spec = Module2Rpm::Spec.new(metadata => { depends => { runtime => { "requires" => ["Cairo","Color"] } } });

    my @expected =
        'Requires:       raku >= 2016.12',
        'Requires:       raku(Cairo)',
        'Requires:       raku(Color)';
    is $spec.requires(), @expected, "Requires returns several runtime dependencies";
}

{
    my $spec = Module2Rpm::Spec.new(metadata => {
        depends => {
            runtime => { "requires" => ["Cairo"] },
            test => { requires => ["testModule"] }
        }
    });

    my @expected =
        'Requires:       raku >= 2016.12',
        'Requires:       raku(Cairo)';
    is $spec.requires(), @expected, "Requires returns test requirements";
}

{
    my $find-rpm-mock = mocked Module2Rpm::FindLibraryNameForOpenSuse, returning => {
        find-rpm => 'libgpgme.so.11()(64bit)';
    };

    my $spec = Module2Rpm::Spec.new(metadata => {
            depends => {
                runtime => {
                    "requires" => [ "NativeLibs:ver<0.0.7+>:auth<github:salortiz>",
                                    "gpgme:from<native>:ver<11>"]
                }
            },
        },
        find-rpm => $find-rpm-mock,
    );

    my @expected =
        'Requires:       raku >= 2016.12',
        'Requires:       raku(NativeLibs)',
        'Requires:       libgpgme.so.11()(64bit)';
    is $spec.requires(), @expected, "Requires returns several runtime dependencies";

    check-mock($find-rpm-mock, 
        *.called('find-rpm', times => 1),
    );
}

{
    my $spec = Module2Rpm::Spec.new(metadata => {
        depends => {
            runtime => {
                "requires" => [
                    "Distribution::Builder::MakeFromJSON:ver<0.6+>",
                    {
                        "from" => "bin",
                        "name"=> "perl"
                    }
                ]
            }
        }
    });

    my @expected =
        'Requires:       raku >= 2016.12',
        'Requires:       raku(Distribution::Builder::MakeFromJSON)',
        'Requires:       perl';
    is $spec.requires(), @expected, "Requires does not return dependency as Hash";
}

{
    my $spec = Module2Rpm::Spec.new(metadata => {});

    my @expected =
        'BuildRequires:  rakudo >= 2017.04.2';
    is $spec.build-requires(), @expected, "Build-requires returns one dependency";
}

{
    my $spec = Module2Rpm::Spec.new(metadata => {build-depends =>  ["LibraryMake","Pod::To::Markdown"]});

    my @expected =
        'BuildRequires:  rakudo >= 2017.04.2',
        'BuildRequires:  raku(LibraryMake)',
        'BuildRequires:  raku(Pod::To::Markdown)';
    is $spec.build-requires(), @expected, "Build-requires returns several dependency";
}

{
    my $spec = Module2Rpm::Spec.new(metadata => {
        build-depends =>  ["LibraryMake"],
        depends => {build => {"requires" => ["Pod::To::Markdown"]}}
    });

    my @expected =
        'BuildRequires:  rakudo >= 2017.04.2',
        'BuildRequires:  raku(Pod::To::Markdown)',
        'BuildRequires:  raku(LibraryMake)';
    is $spec.build-requires(), @expected, 'Build-requires returns also %{requires} dependency';
}

my $meta = {
    "authors" => [
      "pnu",
      "wbiker"
   ],
   "build-depends" => [],
   "depends" => [],
   "description" => "This is a generic module for interactive prompting from the console.",
   "license" => "Artistic-2.0",
   "name" => "IO::Prompt",
   "perl" => "6.*",
   "provides" => {
      "IO::Prompt" => "lib/IO/Prompt.pm"
   },
        "resources" => [],
   "source-url" => "http://www.cpan.org/authors/id/W/WB/WBIKER/Perl6/IO-Prompt-0.0.2.tar.gz",
   "tags" => [],
   "test-depends" => [
      "Test"
   ],
   "version" => "0.0.2"
}

my $spec = Module2Rpm::Spec.new(metadata => $meta);
my $spec-file-content = $spec.get-spec-file();

like $spec-file-content, /'Source0:' \s+ 'raku-IO-Prompt-0.0.2.tar.xz'/, "Source0 found in spec file";
like $spec-file-content, /'Name:' \s+ 'raku-IO-Prompt'/, "Name found in spec file";
like $spec-file-content, /'Version:' \s+ '0.0.2'/, "Version found in spec file";
like $spec-file-content, /'Release:' \s+ '0.0.2'/, "Release found in spec file";
like $spec-file-content, /'License:' \s+ 'Artistic-2.0'/, "License found in spec file";
like $spec-file-content, /'BuildRequires:' \s+ 'fdupes'/, "BuildRequires found in spec file";
like $spec-file-content, /'BuildRequires:' \s+ 'fdupes' \n 'BuildRequires:  rakudo >= 2017.04.2'/, "BuildRequires found in spec file";
like $spec-file-content, /'Requires:' \s+ 'raku >= 2016.12'/, "Requires found in spec file";
like $spec-file-content, /'Provides:' \s+ 'raku(IO::Prompt)'/, "Provides found in spec file";
like $spec-file-content, /'BuildRoot:' \s+ '%{_tmppath}/%{name}-%{version}-build'/, "BuildRoot found in spec file";
unlike $spec-file-content, /'rakudo -e \'require Build:file('/, 'build command not found if build-file not found';

$spec-file-content = $spec.get-spec-file(build-file => IO::Path.new('Build.pm'));
like $spec-file-content, /'rakudo -e \'require Build:file('/, 'build command found with build file';

done-testing;
