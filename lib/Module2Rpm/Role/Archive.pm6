role Module2Rpm::Role::Archive {
    method Extract(IO::Path $path) {...}
    method Compress(IO::Path $path, Str $name --> IO::Path) {...}
    method List(IO::Path $path --> Seq) {...}
}
