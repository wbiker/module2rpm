use Module2Rpm::Role::Archive;

class Module2Rpm::Archive::Tar does Module2Rpm::Role::Archive {
    method Extract(IO::Path $path) {

    }

    method Compress(IO::Path $path, Str name) {

    }

    method List(IO::Path $path --> Array) {
        my @files;
        return @files;
    }
}
