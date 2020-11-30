role Module2Rpm::Role::Internet {
    method get(Str $url) {...}
    method put(Str $url, :$content-type, :$body) {...}
    method delete(Str $url) {...}
}
