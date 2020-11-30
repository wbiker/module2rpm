use Test;
use JSON::Fast;
use File::Temp;

use Module2Rpm::Cro::Client;

# Unfortunately, I have to use an file on the internet to test the download method. This url will probably change or
# the file will be replaced with something else. Find a better method to test that.
my $url = 'https://raw.githubusercontent.com/wbiker/module2rpm/main/LICENSE';

my $client = Module2Rpm::Cro::Client.new;

plan 2;

# First test the download method without a given path. That should return the file content.
my $file-content = $client.get($url);
like $file-content, /'Apache License'/, "String found in test download without path";

my $json = from-json($client.get('https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/cpan1.json'));

ok $json[0].name, "Returned json array with at least one module";
