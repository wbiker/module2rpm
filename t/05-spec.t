use Test;
use File::Temp;

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

    is $spec.requires(), chomp(q:to/SPEC/), "Requires returns one dependency";
        Requires:       perl6 >= 2016.12
        Requires:       perl6(Dependency)
        Requires:       perl6(Dependency1)
        SPEC
}

{
    my $spec = Module2Rpm::Spec.new(metadata => { depends => ["Method::Also"] });

    is $spec.requires(), chomp(q:to/SPEC/), "Requires returns several dependencies";
        Requires:       perl6 >= 2016.12
        Requires:       perl6(Method::Also)
        SPEC
}

{
    my $spec = Module2Rpm::Spec.new(metadata => { depends => { runtime => { "requires" => ["Cairo","Color"] } } });

    is $spec.requires(), chomp(q:to/SPEC/), "Requires returns several runtime dependencies";
        Requires:       perl6 >= 2016.12
        Requires:       perl6(Cairo)
        Requires:       perl6(Color)
        SPEC
}

{
    my $spec = Module2Rpm::Spec.new(metadata => {});

    is $spec.build-requires(), "BuildRequires:  rakudo >= 2017.04.2", "Build-requires returns one dependency";
}

{
    my $spec = Module2Rpm::Spec.new(metadata => {build-depends =>  ["LibraryMake","Pod::To::Markdown"]});

    is $spec.build-requires(), chomp(q:to/SPEC/), "Build-requires returns several dependency";
        BuildRequires:  rakudo >= 2017.04.2
        BuildRequires:  perl6(LibraryMake)
        BuildRequires:  perl6(Pod::To::Markdown)
        SPEC
}

{
    my $spec = Module2Rpm::Spec.new(metadata => {
        build-depends =>  ["LibraryMake"],
        depends => {build => {"requires" => ["Pod::To::Markdown"]}}
    });

    is $spec.build-requires(), chomp(q:to/SPEC/), "Build-requires returns also depends dependency";
        BuildRequires:  rakudo >= 2017.04.2
        BuildRequires:  perl6(Pod::To::Markdown)
        BuildRequires:  perl6(LibraryMake)
        SPEC
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

like $spec-file-content, /'Source:         perl6-IO-Prompt-0.0.2.tar.xz'/, "Source found in spec file";
like $spec-file-content, /'Name:           perl6-IO-Prompt'/, "Name found in spec file";
like $spec-file-content, /'Version:        0.0.2'/, "Version found in spec file";
like $spec-file-content, /'Release:        1.1'/, "Release found in spec file";
like $spec-file-content, /'License:        Artistic-2.0'/, "License found in spec file";
like $spec-file-content, /'BuildRequires:  fdupes'/, "BuildRequires found in spec file";
like $spec-file-content, /'BuildRequires:  fdupes' \n 'BuildRequires:  rakudo >= 2017.04.2'/, "BuildRequires found in spec file";
like $spec-file-content, /'Requires:       perl6 >= 2016.12'/, "Requires found in spec file";
like $spec-file-content, /'Provides:       perl6(IO::Prompt)'/, "Provides found in spec file";
like $spec-file-content, /'BuildRoot:      %{_tmppath}/%{name}-%{version}-build'/, "BuildRoot found in spec file";

done-testing;
