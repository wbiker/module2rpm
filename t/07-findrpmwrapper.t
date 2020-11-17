use Test;
use File::Temp;

use Module2Rpm::FindRpmWrapper;

my $frw = Module2Rpm::FindRpmWrapper.new;

if $frw.find-rpm-path.IO.e {
    ok $frw.find-rpm-exists, "Bool is true when find-rpm executable was found.";
}
else {
    skip "{$frw.find-rpm-path} does not exists. find-rpm tests are skipped", 1;

    nok $frw.find-rpm-exists, "find-rpm-exists is false when find-rpm executable was not found";

    my %adverbs;
    my $requires = "name".IO;
    is $frw.find-rpm(:%adverbs, :$requires), '%{_libdir}/libname.so', "Default is returned without version";

    %adverbs<ver> = "1";
    is $frw.find-rpm(:%adverbs, :$requires), '%{_libdir}/libname.so', "Default is returned when lib path does not exists";
}

done-testing;
