use Module2Rpm::Package;

role Module2Rpm::Role::Upload {
    method get(Str $url) {...}
    method put(Str $url, :$content-type?, :$body?) {...}
    method delete(Str $url) {...}
}
