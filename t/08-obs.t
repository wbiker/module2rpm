use Test;
use XML;
use File::Temp;

use Module2Rpm::Role::Upload;
use Module2Rpm::Upload::OBS;
use Module2Rpm::Spec;
use Module2Rpm::Package;

class ClientReplacement does Module2Rpm::Role::Upload {
    has Str $.get-url;
    has Str $.get-return is rw;
    has Str $.delete-url;
    has Hash $.put-stuff;

    method get(Str $url) {
        $!get-url = $url;

        return $!get-return;
    }

    method delete(Str $url) {
        $!delete-url = $url;

    }
    method put(Str $url, :$content-type?, :$body?) {
        $!put-stuff<url> = $url;
        $!put-stuff<content-type> = $content-type // "";
        $!put-stuff<body> = $body // "";
    }
}

my $test-client = ClientReplacement.new;
my $obs = Module2Rpm::Upload::OBS.new(client => $test-client, project => 'project');

dies-ok {$obs.delete-source-file()}, "delete-source-file expect package parameter";

$test-client.get-return = q:to/END/;
<directory count="3">
    <entry name="perl6-IO-Prompt"/>
</directory>
END

is $obs.package-exists("doesnotexists"), False, "Not existing package returns False";
is $test-client.get-url(), "https://api.opensuse.org/source/project", "package-exists build correct url";
is $obs.package-exists("perl6-IO-Prompt"), True, "Existing package returns True";

my $meta = {
    name => 'Module::Name',
    version => '0.0.2',
    source-url => 'https://doesnotexists.tar.gz',
    description => "summary",
};
my $package = create-test-package(:$meta, path => tempdir().IO);
$obs.create-package(:$package);

is $test-client.put-stuff<url>, "https://api.opensuse.org/source/project/perl6-Module-Name/_meta", "Url for create package is the expected one";

my $expected-create-package-xml = q:to/END/;
<package name="perl6-Module-Name" project="project">
    <title>perl6-Module-Name</title>
    <description>summary</description>
</package>
END
is $test-client.put-stuff<content-type>, "application/xml", "Create-package uses proper content-type";
is $test-client.put-stuff<body>, $expected-create-package-xml, "Create-package uses proper xml";

$obs.delete-package(:$package);
is $test-client.delete-url(), "https://api.opensuse.org/source/project/perl6-Module-Name", "Delete-package build proper url";




done-testing;

sub create-test-package(:$meta, :$path) {
    my $s = Module2Rpm::Spec.new(metadata => $meta);
    return Module2Rpm::Package.new(spec =>  $s, :$path);
}