use Test;
use File::Temp;

use Module2Rpm::Archive::Tar;

my constant ARCHIVE-ROOT = "archive";
my constant ARCHIVE-SUBDIR = "archive/dir";
my constant ARCHIVE-SUBDIR2 = "archive/dir1";
my constant ARCHIVE-SUBDIR-FILE = "archive/dir/file";
my constant ARCHIVE-SUBDIR2-FILE = "archive/dir1/file1";
my constant ARCHIVE-ROOT-FILE = "archive/file2";

my @test-dirs = ARCHIVE-ROOT, ARCHIVE-SUBDIR, ARCHIVE-SUBDIR2;
my @test-files = ARCHIVE-SUBDIR-FILE, ARCHIVE-SUBDIR2-FILE, ARCHIVE-ROOT-FILE;

my $tar-file-name = "testfile.tar.xz";
my $tar = Module2Rpm::Archive::Tar.new;

{
    my $temp-dir = tempdir().IO;
    my $expected-tar-file-path = $temp-dir.add($tar-file-name);

    my $tar-file-path = create-tar-archive-from-directory($temp-dir, $tar-file-name);
    is $tar-file-path.Str, $expected-tar-file-path, "Tar file created";

    my $expected-list = <archive/ archive/file2 archive/dir1/ archive/dir1/file1 archive/dir/ archive/dir/file>.sort.Seq;
    my $file-list = $tar.List($tar-file-path).sort;
    is-deeply($file-list, $expected-list, "Archive file list is the expected one");
}

{
    my $tar-file = create-tar-archive-from-directory(tempdir().IO, $tar-file-name);
    my $extract-dir = tempdir().IO;
    my $extract-tar-path = $extract-dir.add($tar-file-name);
    $tar-file.copy($extract-tar-path);
    $tar.Extract($extract-tar-path);

    ok $extract-dir.add(ARCHIVE-ROOT).e, "Extracted root folder found";
    ok $extract-dir.add(ARCHIVE-SUBDIR).e, "Extracted subfolder found";
    ok $extract-dir.add(ARCHIVE-SUBDIR2).e, "Extracted second subfolder found";
    ok $extract-dir.add(ARCHIVE-SUBDIR-FILE).e, "Extracted file in subfolder found";
    ok $extract-dir.add(ARCHIVE-SUBDIR2-FILE).e, "Extracted second file in subfolder found";
    ok $extract-dir.add(ARCHIVE-ROOT-FILE).e, "Extracted file found";
}

done-testing;

sub create-test-structure(IO::Path $dir --> IO::Path) {
    for @test-dirs -> $dir-to-create {
        $dir.add($dir-to-create).mkdir;
    }
    for @test-files -> $file {
        $dir.add($file).spurt("dummy");
    }

    return $dir.add(ARCHIVE-ROOT);
}

sub create-tar-archive-from-directory(IO::Path $dir, Str $tar-file-name --> IO::Path) {
    my $test-dir = create-test-structure($dir);
    return $tar.Compress($test-dir, $tar-file-name);
}
