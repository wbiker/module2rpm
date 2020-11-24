use Cro::HTTP::Client;

use Module2Rpm::Role::Upload;

class Module2Rpm::Upload::Cro::Client does Module2Rpm::Role::Upload {
    has Cro::HTTP::Client $!client;

    submethod BUILD(:$auth) {
        $!client = Cro::HTTP::Client.new(:$auth);
    }

    method get(Str $url) {
        my $response = await $!client.get($url);

        return await $response.body;
    }

    method put(Str $url, :$content-type?, :$body?) {
        try {
            return await $!client.put($url, :$content-type, :$body);

            CATCH {
                default { "PUT request failed with {$_} for '$url' with content-type '$content-type'"; }
            }
        }
    }

    method delete(Str $url) {
        return await $!client.delete($url);
    }
}
