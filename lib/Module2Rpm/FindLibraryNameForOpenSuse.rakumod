use File::Temp;
use XML;

use Module2Rpm::Role::FindLibraryName;
use Module2Rpm::Role::Internet;
use Module2Rpm::Role::Archive;
use Module2Rpm::Cro::Client;
use Module2Rpm::Archive::Gzip;

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

has $!repodata = 'http://download.opensuse.org/distribution/openSUSE-current/repo/oss/';
has $!repodata-repomd-xml = 'repodata/repomd.xml';   # This file contains the name of the primary.xml file which we need.
has Module2Rpm::Role::Internet $.client = Module2Rpm::Cro::Client.new;
has Module2Rpm::Role::Archive $.gzip = Module2Rpm::Archive::Gzip.new;
has $!primary-xml;
has Bool $!download-successful = True;

method find-rpm(:%adverbs, IO::Path :$requires) {
    my $default-libdir = '%{_libdir}/' ~ $*VM.platform-library-name($requires);

    if not %adverbs<ver> {
        #note "Package doesn't specify a library version, so I have to fall back to depending on library path.";
        if $requires eq 'perl' {
            return 'libperl.so()(64bit)';
        }
        return $default-libdir;
    }

    self.download-file();

    my $libname = $*VM.platform-library-name($requires);
    $libname ~= "." ~ %adverbs<ver> ~ '()(64bit)';

    if $!primary-xml.contains($libname) {
        return $libname;
    }

    return $default-libdir;
}

method download-file() {
    return if not $!download-successful;

    my $repomd;
    try {
        $repomd = $!client.get($!repodata ~ $!repodata-repomd-xml);

        CATCH { default { warn "Could not download repo xml file to look for the OpenSuse RPM library packages."; $!download-successful = False; } }
    }

    my $xml = from-xml($repomd);
    my $repomd-xml = $xml.root.nodes.grep(* ~~ XML::Element).grep({$_.attribs<type>.defined and $_.attribs<type> eq "primary"}).first;
    do { $!download-successful = False; warn "Could not find OpenSuse's RPM library package file."; return; } unless $repomd-xml;
    my $primary-file-name = $repomd-xml.nodes.grep({ $_ ~~ XML::Element }).grep(*.name eq "location").first.attribs<href>;
    do { $!download-successful = False; warn "Could not find OpenSuse's RPM library package file."; return; } unless $primary-file-name;

    my $primary-file-content = $!client.get($!repodata ~ $primary-file-name);
    unless $primary-file-content {
        warn "Could not download OpenSuse'S RPM library package file: {$!repodata}{$primary-file-name}";
        $!download-successful = False;
        return;
    }

    my $tempdir = tempdir().IO;
    my $compressed-file = $tempdir.add("compressedfile.gz");
    $compressed-file.spurt($primary-file-content, :bin);
    my $file-content = $!gzip.Extract($compressed-file);
    if not $file-content {
        $!download-successful = False;
        return;
    }

    $!primary-xml = $file-content;
}
