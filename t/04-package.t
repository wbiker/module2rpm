use Test;
use File::Temp;

use Module2Rpm::Package;
use Module2Rpm::Spec;

my $module-name-prefix = "perl6-";

my $metadata = {
    name => 'Module::Name',
    version => '1.1.1',
    source-url => 'https://gist.github.com/64267c60b798047145c80561334c3cd5.git',
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
is $package.source-url, 'https://gist.github.com/64267c60b798047145c80561334c3cd5.git', "Source url is the expected one";

done-testing;
