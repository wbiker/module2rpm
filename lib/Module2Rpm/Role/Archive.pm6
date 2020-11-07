role Module2Rpm::Role::Archive {
    method Extract(IO::Path $path) {...}
    method Compress(IO::Path $path, Str $name) {...}
    method List(IO::Path $path --> Array) {...}
}
