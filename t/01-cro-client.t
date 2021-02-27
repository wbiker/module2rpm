use Test;
use JSON::Fast;
use File::Temp;

use Module2Rpm::Cro::Client;
plan 1;

skip-rest("Cro::HTTP::Client bug");
exit;


# Unfortunately, I have to use an file on the internet to test the download method. This url will probably change or
# the file will be replaced with something else. Find a better method to test that.
my $url = 'https://raw.githubusercontent.com/wbiker/module2rpm/main/LICENSE';

my $client = Module2Rpm::Cro::Client.new;


# First test the download method without a given path. That should return the file content.
my $file-content = $client.get($url);
like $file-content, /'Apache License'/, "String found in test download without path";

# Died with the exception:
#    Header table index 82 out of range
#      in method resolve-decoded-index at /home/wolf/.rakubrew/versions/moar-2020.09/install/share/perl6/site/sources/4CC285A8AB160824E5A42DC6EF776B610FCEB2F9 (HTTP::HPACK) line 258
#      in block  at /home/wolf/.rakubrew/versions/moar-2020.09/install/share/perl6/site/sources/4CC285A8AB160824E5A42DC6EF776B610FCEB2F9 (HTTP::HPACK) line 286
#      in method decode-headers at /home/wolf/.rakubrew/versions/moar-2020.09/install/share/perl6/site/sources/4CC285A8AB160824E5A42DC6EF776B610FCEB2F9 (HTTP::HPACK) line 282
#      in method set-headers at /home/wolf/.rakubrew/versions/moar-2020.09/install/share/perl6/site/sources/3523BF185071CC5AB875D8D00C04E400CF5777AB (Cro::HTTP2::GeneralParser) line 187
#      in block  at /home/wolf/.rakubrew/versions/moar-2020.09/install/share/perl6/site/sources/3523BF185071CC5AB875D8D00C04E400CF5777AB (Cro::HTTP2::GeneralParser) line 101
#      in block  at /home/wolf/.rakubrew/versions/moar-2020.09/install/share/perl6/site/sources/2FD61B909A901DA559CEDBC72E222C0CE26736D7 (Cro::HTTP2::FrameParser) line 93
#      in block  at /home/wolf/.rakubrew/versions/moar-2020.09/install/share/perl6/site/sources/2FD61B909A901DA559CEDBC72E222C0CE26736D7 (Cro::HTTP2::FrameParser) line 61
#      in block  at /home/wolf/.rakubrew/versions/moar-2020.09/install/share/perl6/site/sources/DDDD3607B617AC6B7DCA0D086AD3F4247AC394E9 (Cro::TLS) line 89
# TODO find out why this fails.
my $json = from-json($client.get('https://raw.githubusercontent.com/ugexe/Perl6-ecosystems/master/cpan1.json'));

ok $json[3].name, "Returned json array with at least one module";
