use Module2Rpm::Role::Internet;

class Module2Rpm::Internet::LWP does Module2Rpm::Role::Internet {
    has $.lwp is required;

    method get(Str $url) {
        return $!lwp.get($url);
    }

    method delete(Str $url) { X::NYI.new( feature => &?ROUTINE.name).throw; }
    method put(Str $url, :$content-type, :$body) { X::NYI.new( feature => &?ROUTINE.name).throw; }
}
