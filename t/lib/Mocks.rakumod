use Module2Rpm::Role::Download;
use Module2Rpm::Role::Internet;
use Module2Rpm::Role::Archive;

class Mocks::ClientReplacement does Module2Rpm::Role::Internet {
    has @.get_return_strings is rw = <" ">;
    has Int $!index = 0;
    has Bool $.fail = False;
    has Str $.error = "";
    has Hash $.put-stuff;
    has Str $.get-url;
    has Str $.delete-url;

    method get(Str $url) {
        die $!error if $!fail;

        $!get-url = $url if $url;

        die "ClientReplacement: No more strings to return" if $!index >= @!get_return_strings.elems;
        return @!get_return_strings[$!index++];
    }
    method delete(Str $url) {
        $!delete-url = $url;
    }

    method put(Str $url, :$content-type, :$body) {
        $!put-stuff<url> = $url;
        $!put-stuff<content-type> = $content-type // "";
        $!put-stuff<body> = $body // "";
    }
}

class Mocks::GitReplacement does Module2Rpm::Role::Download {
    method Download(Str $url, IO::Path $path) {
    }
}

class Mocks::TarReplacement does Module2Rpm::Role::Archive {
    method Compress(IO::Path $path, Str $name --> IO::Path) {
        my IO::Path $return-object = $path.parent.add($name);
        $return-object.spurt("");

        return $return-object;
    }
    method Extract(IO::Path $path) {
        $path.parent.add('test').mkdir;
        $path.unlink;
    }
    method List(IO::Path $path --> Array) {
        return <test/file
                test/file1
                test/subtest/file
                test/subtest/file2>
    }
}
