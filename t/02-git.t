use Test;
use File::Temp;
use lib './lib';

use Module2Rpm::Download::Git;

my $git-repo = 'https://github.com/wbiker/module2rpm.git';

my $git = Module2Rpm::Download::Git.new;

my $temp-dir = tempdir().IO;

lives-ok {$git.Download($git-repo, $temp-dir)}, "Git clone does not die for existing repo and targed directory";
my $this-test-file = $temp-dir.add('t/02-git.t');
ok $this-test-file.e, "Successfully cloned git repository";

dies-ok {$git.Download($git-repo, $temp-dir)}, "Dies when destination directory exists and is not empty";

done-testing;
