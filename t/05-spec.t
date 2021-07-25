use Test;
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
    is $spec.get-name(), "perl6-Module-Name", "Get-Name returns expected name";
}

{
    my $spec = Module2Rpm::Spec.new(metadata => {
        name => 'ModuleName',
        provides => { 'ModuleName' => 'lib/ModuleName' }
    });
    is $spec.provides(), "Provides:       perl6(ModuleName)", "Provides returns proper string";
}

{
    my $spec = Module2Rpm::Spec.new(metadata => {
        name => 'ModuleName',
        provides => {   'ModuleName' => 'lib/ModuleName',
                        'ModuleName::Name' => 'lib/ModuleName/Name' }
    });
    is $spec.provides(), chomp(q:to/SPEC/), "Provides returns proper string";
        Provides:       perl6(ModuleName)
        Provides:       perl6(ModuleName::Name)
        SPEC
}

{
    my $spec = Module2Rpm::Spec.new(metadata => {});
    is $spec.requires(), "Requires:       perl6 >= 2016.12", "Requires returns one dependency";
}

{
    my $spec = Module2Rpm::Spec.new(metadata => { depends => ['Dependency', 'Dependency1']});

    my @expected =
        "Requires:       perl6 >= 2016.12",
        "Requires:       perl6(Dependency)",
        "Requires:       perl6(Dependency1)";
    is $spec.requires(), @expected, "Requires returns one dependency";
}

{
    my $spec = Module2Rpm::Spec.new(metadata => { depends => ["Method::Also"] });

    my @expected =
        "Requires:       perl6 >= 2016.12",
        "Requires:       perl6(Method::Also)";
    is $spec.requires(), @expected, "Requires returns several dependencies";
}

{
    my $spec = Module2Rpm::Spec.new(metadata => { depends => { runtime => { "requires" => ["Cairo","Color"] } } });

    my @expected =
        'Requires:       perl6 >= 2016.12',
        'Requires:       perl6(Cairo)',
        'Requires:       perl6(Color)';
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
        'Requires:       perl6 >= 2016.12',
        'Requires:       perl6(Cairo)';
    is $spec.requires(), @expected, "Requires returns test requirements";
}

{
    my $spec = Module2Rpm::Spec.new(metadata => {
        depends => {
            runtime => {
                "requires" => [ "NativeLibs:ver<0.0.7+>:auth<github:salortiz>",
                                "gpgme:from<native>:ver<11>"]
            }
        }
    });

    my @expected =
        'Requires:       perl6 >= 2016.12',
        'Requires:       perl6(NativeLibs)',
        'Requires:       libgpgme.so.11()(64bit)';
    is $spec.requires(), @expected, "Requires returns several runtime dependencies";
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
        'Requires:       perl6 >= 2016.12',
        'Requires:       perl6(Distribution::Builder::MakeFromJSON)',
        'Requires:       /usr/bin/perl';
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
        'BuildRequires:  perl6(LibraryMake)',
        'BuildRequires:  perl6(Pod::To::Markdown)';
    is $spec.build-requires(), @expected, "Build-requires returns several dependency";
}

{
    my $spec = Module2Rpm::Spec.new(metadata => {
        build-depends =>  ["LibraryMake"],
        depends => {build => {"requires" => ["Pod::To::Markdown"]}}
    });

    my @expected =
        'BuildRequires:  rakudo >= 2017.04.2',
        'BuildRequires:  perl6(Pod::To::Markdown)',
        'BuildRequires:  perl6(LibraryMake)';
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

like $spec-file-content, /'Source0:' \s+ 'perl6-IO-Prompt-0.0.2.tar.xz'/, "Source0 found in spec file";
like $spec-file-content, /'Name:' \s+ 'perl6-IO-Prompt'/, "Name found in spec file";
like $spec-file-content, /'Version:' \s+ '0.0.2'/, "Version found in spec file";
like $spec-file-content, /'Release:' \s+ '1.1'/, "Release found in spec file";
like $spec-file-content, /'License:' \s+ 'Artistic-2.0'/, "License found in spec file";
like $spec-file-content, /'BuildRequires:' \s+ 'fdupes'/, "BuildRequires found in spec file";
like $spec-file-content, /'BuildRequires:' \s+ 'fdupes' \n 'BuildRequires:  rakudo >= 2017.04.2'/, "BuildRequires found in spec file";
like $spec-file-content, /'Requires:' \s+ 'perl6 >= 2016.12'/, "Requires found in spec file";
like $spec-file-content, /'Provides:' \s+ 'perl6(IO::Prompt)'/, "Provides found in spec file";
like $spec-file-content, /'BuildRoot:' \s+ '%{_tmppath}/%{name}-%{version}-build'/, "BuildRoot found in spec file";

done-testing;
