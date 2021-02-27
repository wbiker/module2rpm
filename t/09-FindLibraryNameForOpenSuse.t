use Test;
use Test::Mock;

use Module2Rpm::Role::Internet;
use Module2Rpm::FindLibraryNameForOpenSuse;
use Module2Rpm::Cro::Client;
use Module2Rpm::Archive::Gzip;

my $client = mocked Module2Rpm::Cro::Client, computing => {
    get => {
        q:to/END/;
        <?xml version="1.0" encoding="UTF-8"?>
        <repomd xmlns="http://linux.duke.edu/metadata/repo" xmlns:rpm="http://linux.duke.edu/metadata/rpm">
            <data type="primary">
                <location href="repodata/ee17b27ef91d0fb16ac7311f04afe362fe2efeb1a90ff4d97811237ff14e7bec-primary.xml.gz"/>
            </data>
        </repomd>
        END
    }
};

my $gzip = mocked Module2Rpm::Archive::Gzip, computing => {
    Extract => {
            q:to/END/;
            <?xml version="1.0" encoding="UTF-8"?>
            <metadata xmlns="http://linux.duke.edu/metadata/common" xmlns:rpm="http://linux.duke.edu/metadata/rpm" packages="38560">
                <package type="rpm">
                    <name>libgpgme11</name>
                    <format>
                        <rpm:provides>
                            <rpm:entry name="libgpgme.so.11()(64bit)"/>
                        </rpm:provides>
                    </format>
                </package>
            </metadata>
            END
        }
};

my $f = Module2Rpm::FindLibraryNameForOpenSuse.new(:$client, :$gzip);

my $libname = $f.find-rpm(adverbs => { ver => "11" }, requires => "gpgme".IO);
is $libname, 'libgpgme.so.11()(64bit)', 'Libname with version is the expected one';

$libname = $f.find-rpm(adverbs => {}, requires => "perl".IO);
is $libname, 'libperl.so()(64bit)', 'Certain libname without version is the expected one';

$libname = $f.find-rpm(adverbs => {}, requires => "unknown".IO);
is $libname, '%{_libdir}/libunknown.so', 'libname without version retuns expected name';

done-testing;
