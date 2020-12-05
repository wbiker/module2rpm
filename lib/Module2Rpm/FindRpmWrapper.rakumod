use Module2Rpm::Role::FindRpmWrapper;

=begin pod

=head1 Module2Rpm::FindRpmWrapper

This class is used for looking for the find-provides RPM command line tool and wrapping it.

=head1 DESCRIPTION

This class is used to find the path for a given library. When the find-provides tool was not found the default
"%{_libdir}/library_name" is returned.

=head1 SYNOPSIS

=end pod

class Module2Rpm::FindRpmWrapper does Module2Rpm::Role::FindRpmWrapper {
    has $.find-rpm-path = '/usr/lib/rpm/find-provides';
    has $.find-rpm-exists = False;
    has @.lib-paths = </usr/lib64 /lib64 /usr/lib /lib>;

    submethod TWEAK() {
        if $!find-rpm-path.IO.e {
            $!find-rpm-exists = True;
            return;
        }

        #warn "$!find-rpm-path not found. Cannot look for libs";
    }

    method find-rpm(:%adverbs, IO::Path :$requires) {
        my $default-libdir = '%{_libdir}/' ~ $*VM.platform-library-name($requires);

        if not %adverbs<ver> {
            #note "Package doesn't specify a library version, so I have to fall back to depending on library path.";
            return $default-libdir;
        }

        my $lib = $*VM.platform-library-name($requires, :version(Version.new(%adverbs<ver>)));
        my $path = </usr/lib64 /lib64 /usr/lib /usr/lib32 /lib>.first({$_.IO.add($lib).e});
        if not $path {
            #note "Falling back to depending on the library path as I couldn't find $lib";
            return $default-libdir;
        }

        if not $!find-rpm-exists.IO.e {
           # note "{$!find-rpm-path} does not exists. Falling back to depending on the library path.";
            return $default-libdir;
        }

        my $proc = run '/usr/lib/rpm/find-provides', :in, :out;
        $proc.in.say($path.IO.add($lib).resolve.Str);
        $proc.in.close;
        return $proc.out.lines;
    }
}
