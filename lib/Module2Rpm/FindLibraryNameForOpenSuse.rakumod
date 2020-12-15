use File::Temp;

use Module2Rpm::Role::FindLibraryName;
use Module2Rpm::Role::Internet;
use Module2Rpm::Cro::Client;

=begin pod

=head1 Module2Rpm::FindLibraryNameForOpenSuse

This class is used for looking for library names on OpenSuse files systems.

=head1 DESCRIPTION

This class is used to find the name for libraries like primesieve = 'libprimesieve.so.0()(64bit)'. It expexts the
library name and version and looked it up in the OpenSuse bec-primary.xml file. This file can be find here:
L<http://download.opensuse.org/distribution/openSUSE-current/repo/oss/repodata/>. It parses the repomd.xml file to find
the bec-primary.xml file and downloaded it. Once the library name is found in the file all is fine. In case of missing
version or when the library name was not found in the file guessing work starts.

=head1 SYNOPSIS

=end pod

unit class Module2Rpm::FindLibraryNameForOpenSuse does Module2Rpm::Role::FindLibraryName;

has $!repodata = 'http://download.opensuse.org/distribution/openSUSE-current/repo/oss/repodata/';
has $!repodata-repomd-xml = 'repomd.xml';   # This file contains the name of the primary.xml file which we need.
has Module2Rpm::Role::Internet $.client = Module2Rpm::Cro::Client.new;

method find-rpm(:%adverbs, IO::Path :$requires) {
    my $default-libdir = '%{_libdir}/' ~ $*VM.platform-library-name($requires);

    if not %adverbs<ver> {
        #note "Package doesn't specify a library version, so I have to fall back to depending on library path.";
        return $default-libdir;
    }
}

method download-and-expand-primary-xml() {

}