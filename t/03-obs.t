use Test;
use XML;
use File::Temp;
use Test::Mock;
use lib './lib';

use Cro::HTTP::Client;

use Module2Rpm::Upload::OBS;
use Module2Rpm::Spec;
use Module2Rpm::Package;

my $test_client = mocked Module2Rpm::Cro::Client, returning => {
    get => q:to/END/;
            <directory count="3">
                <entry name="raku-IO-Prompt"/>
            </directory>
            END
    };

my $obs = Module2Rpm::Upload::OBS.new(client => $test_client, project => 'project');

dies-ok {$obs.delete-source-file()}, "delete-source-file expect package parameter";

is $obs.package-exists("doesnotexists"), False, "Not existing package returns False";
is $obs.package-exists("raku-IO-Prompt"), True, "Existing package returns True";

my $meta = {
    name => 'Module::Name',
    version => '0.0.2',
    source-url => 'https://doesnotexists.tar.gz',
    description => "summary",
};
my $package = create-test-package(:$meta, path => tempdir().IO);
$obs.create-package(:$package);

my $expected-create-package-xml = q:to/END/;
<package name="raku-Module-Name" project="project">
    <title>raku-Module-Name</title>
    <description>summary</description>
</package>
END

$obs.delete-package(:$package);

check-mock($test_client,
    *.called("get", with => "https://api.opensuse.org/source/project"),
    *.called("put", with => \(
       "https://api.opensuse.org/source/project/raku-Module-Name/_meta",
       content-type => "application/xml",
       body => $expected-create-package-xml
    )),
    *.called("delete", with => "https://api.opensuse.org/source/project/raku-Module-Name")
);

done-testing;

sub create-test-package(:$meta, :$path) {
    my $s = Module2Rpm::Spec.new(metadata => $meta);
    return Module2Rpm::Package.new(spec =>  $s, :$path);
}
