use Module2Rpm::Metadata;

class Module2Rpm::Spec {
    has %keys-values;
    has %keys-values<requires> = 'perl6 >= 2016.12';
    has %keys-values<build-requires> = 'rakudo >= 2017.04.2';

    method write-spec-file(IO::Path $path, Module2Rpm::Metadata $meta) {}
}
