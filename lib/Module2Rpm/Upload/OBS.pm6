use Module2Rpm::Package;

=begin pod

=head1 Module2Rpm::Upload::OBS

=head2 More Infos
    L<https://build.opensuse.org/apidocs/index>

=end pod
class Module2Rpm::Upload::OBS {
    has $user;
    has $password;
    has $url;

    method Upload(Module2Rpm::Package) {

    }
}
