use Test;
use File::Temp;
use Test::Mock;

use Module2Rpm::Package;
use Module2Rpm::Spec;

my $module-name-prefix = "perl6-";

my $metadata = {
    name => 'Module::Name',
    version => '1.1.1',
    source-url => 'http://www.cpan.org/authors/id/A/AR/ARNE/Perl6/p6-time-repeat-0.0101.tar.gz',
}

my $spec = Module2Rpm::Spec.new(metadata => $metadata);

my $tempdir = tempdir().IO;
my $package;
lives-ok {$package = Module2Rpm::Package.new(spec => $spec, path => $tempdir)}, "Creating Package object works without exception";

is-deeply $package.spec, $spec, "Metadata are the expected one";
is $package.module-name, "{$module-name-prefix}Module-Name", "Module name is the expected one";
is $package.path.absolute, $tempdir.add($package.module-name), "Package directory path is the expected one";
ok $package.path.e, "Package directory was created";
is $package.tar-name, "{$module-name-prefix}Module-Name-1.1.1.tar.xz", "Tar name is the expected one";
is $package.tar-archive-path, "{$tempdir.add($package.module-name).add($package.tar-name)}", "Tar path is the expected one";
is $package.source-url, 'http://www.cpan.org/authors/id/A/AR/ARNE/Perl6/p6-time-repeat-0.0101.tar.gz', "Source url is the expected one";
is $package.spec-file-name, "{$module-name-prefix}Module-Name.spec", "Spec file name is the expected one";
is $package.spec-file-path, "{$tempdir.add($package.module-name).add($package.spec-file-name)}", "Spec file path is the expected one";
is $package.client.WHAT, Module2Rpm::Cro::Client.WHAT, "Proper Client default class is used";
is $package.git.WHAT, Module2Rpm::Download::Git.WHAT, "Proper Git default class is used";
is $package.tar.WHAT, Module2Rpm::Archive::Tar.WHAT, "Proper Tar default class is used";

{
    my $client = mocked Module2Rpm::Cro::Client, returning => {
        get => "Should not trigger an exception",
    };
    my $git_mock = mocked Module2Rpm::Download::Git;
    my $tar_mock = mocked Module2Rpm::Archive::Tar, overriding => {
        Compress => -> $path, $name { my $r = $path.parent.add("test_file.tar.xz"); $r.spurt(""); $r },
        Extract => -> $url { $url.parent.add('test-directory').IO.mkdir },
    };
    my $package = Module2Rpm::Package.new(spec => $spec, path => $tempdir, client => $client, git => $git_mock, tar => $tar_mock);

    lives-ok { $package.Download() }, "Download does not die";
}
{
    my $client = mocked Module2Rpm::Cro::Client, computing => {
        get => { die "Test exception" }
    };

    my $git_mock = mocked Module2Rpm::Download::Git;
    my $tar_mock = mocked Module2Rpm::Archive::Tar;
    my $package = Module2Rpm::Package.new(spec => $spec, path => $tempdir, client => $client, git => $git_mock, tar => $tar_mock);
    throws-like {$package.Download()}, X::AdHoc, payload => /'Test exception'/, "Package dies when something goes wrong";
}

done-testing;
