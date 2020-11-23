use Test;
use File::Temp;

use Module2Rpm::Package;
use Module2Rpm::Spec;

use Module2Rpm::Role::Download;

class CurlReplacement does Module2Rpm::Role::Download {
    has Bool $.fail = False;
    has Str $.error = "";

    method Download(Str $url, IO::Path $path?) {
        die $!error if $!fail;

        $path.spurt("") if $path;
    }
}

class GitReplacement does Module2Rpm::Role::Download {
    method Download(Str $url, IO::Path $path) {
    }
}

class TarReplacement does Module2Rpm::Role::Archive {
    method Compress(IO::Path $path, Str $name --> IO::Path) {
        my IO::Path $return-object = $path.parent.add($name);
        $return-object.spurt("");

        return $return-object;
    }
    method Extract(IO::Path $path) {
        $path.parent.add('test').mkdir;
        $path.unlink;
    }
    method List(IO::Path $path --> Array) {
        return <test/file
                test/file1
                test/subtest/file
                test/subtest/file2>
    }
}

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
is $package.curl.WHAT, Module2Rpm::Download::Curl.WHAT, "Proper Curl default class is used";
is $package.git.WHAT, Module2Rpm::Download::Git.WHAT, "Proper Git default class is used";
is $package.tar.WHAT, Module2Rpm::Archive::Tar.WHAT, "Proper Tar default class is used";

{
    my $curl = CurlReplacement.new;
    my $package = Module2Rpm::Package.new(spec => $spec, path => $tempdir, curl => $curl, git => GitReplacement.new, tar => TarReplacement.new);

    lives-ok { $package.Download() }, "Download does not die";
}
{
    my $curl = CurlReplacement.new(fail => True, error => "Test exception");
    my $package = Module2Rpm::Package.new(spec => $spec, path => $tempdir, curl => $curl, git => GitReplacement.new, tar => TarReplacement.new);
    throws-like {$package.Download()}, X::AdHoc, payload => /'Test exception'/, "Package dies when something goes wrong";
}

done-testing;
