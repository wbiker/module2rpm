use Test;
use File::Temp;

use Module2Rpm::Archive::Tar;

my $tar-file-name = "testfile.tar.xz";
my $tar = Module2Rpm::Archive::Tar.new;

{
    my $temp-dir = tempdir().IO;
    my $expected-tar-file-path = $temp-dir.add($tar-file-name);

    my $tar-file-path = create-tar-archive-from-directory($temp-dir, $tar-file-name);
    is $tar-file-path.Str, $expected-tar-file-path, "Tar file created";

    my $expected-list = <archive/ archive/file2 archive/dir1/ archive/dir1/file1 archive/dir/ archive/dir/file>.Seq;
    is-deeply($tar.List($tar-file-path), $expected-list, "Archive file list is the expected one");
}

{
    my $tar-file = create-tar-archive-from-directory(tempdir().IO, $tar-file-name);
    my $extract-dir = tempdir().IO;
    my $extract-tar-path = $extract-dir.add($tar-file-name);
    $tar-file.copy($extract-tar-path);
    $tar.Extract($extract-tar-path);

    ok $extract-dir.add("archive").e, "Extracted root folder found";
    ok $extract-dir.add("archive/dir").e, "Extracted subfolder found";
    ok $extract-dir.add("archive/dir1").e, "Extracted second subfolder found";
    ok $extract-dir.add("archive/dir/file").e, "Extracted file in subfolder found";
    ok $extract-dir.add("archive/dir1/file1").e, "Extracted second file in subfolder found";
    ok $extract-dir.add("archive/file2").e, "Extracted file found";
}

done-testing;

sub create-test-structure(IO::Path $dir --> IO::Path) {
    my $archive-dir = $dir.add('archive');
    $archive-dir.mkdir;
    $archive-dir.add('dir').mkdir;
    $archive-dir.add('dir1').mkdir;
    $archive-dir.add('dir/file').spurt("dummy");
    $archive-dir.add('dir1/file1').spurt("dummy");
    $archive-dir.add('file2').spurt("dummy");

    return $archive-dir;
}

sub create-tar-archive-from-directory(IO::Path $dir, Str $tar-file-name --> IO::Path) {
    my $test-dir = create-test-structure($dir);
    return $tar.Compress($test-dir, $tar-file-name);
}
