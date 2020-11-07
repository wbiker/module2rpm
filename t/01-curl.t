use Test;
use File::Temp;

use Module2Rpm::Download::Curl;

# Unfortunately, I have to use an file on the internet to test the download method. This url will probably change or
# the file will be replaced with something else. Find a better method to test that.
my $url = 'https://raw.githubusercontent.com/wbiker/module2rpm/main/LICENSE';

my $curl = Module2Rpm::Download::Curl.new;

plan 4;

# First test the download method without a given path. That should return the file content.
my $file-content = $curl.Download($url);
like $file-content, /'Apache License'/, "String found in test download without path";

# Then with path. That should download the file to the given path.
my $target-dir = tempdir;
my $test-file = $target-dir.IO.add("test.txt");
lives-ok {$curl.Download($url, $test-file)}, "Download file to path worked without exception";
like $test-file.slurp(:close), /'Apache License'/, "Downloaded file is the expected one";

dies-ok { $curl.download("not a valid url")}, "Download method throws for invalid url";
