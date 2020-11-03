use Module2Rpm::Spec;
use Module2Rpm::Metadata;

class Module2Rpm::Package {
    has Module2Rpm::Spec $spec;

    method Fill-Template(Module2Rpm::Metadata $metadata --> Str) {
        return "";
    }
}
