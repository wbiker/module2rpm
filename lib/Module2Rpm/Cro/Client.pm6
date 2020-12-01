use Cro::HTTP::Client;

use Module2Rpm::Role::Internet;

class Module2Rpm::Cro::Client does Module2Rpm::Role::Internet {
    has Cro::HTTP::Client $!client;

    submethod BUILD(:$auth) {
        if $auth {
            # Setting the HTTP 1.1 version is important as otherwise a half-closed error will occur
            # during uploading certain tar archive files.
            $!client = Cro::HTTP::Client.new(:$auth, http => '1.1', :!persistent);
            return;
        }

        $!client = Cro::HTTP::Client.new();
    }

    method get(Str $url) {
        my $response = await $!client.get($url);

        return await $response.body;
    }

    method put(Str $url, :$body, :$content-type = "text/html") {
        try {
            await $!client.put($url, :$content-type, :$body);

            CATCH {
                default { "PUT request failed with { $_ } for '$url'"; }
            }
        }
    }

    method delete(Str $url) {
        return await $!client.delete($url);
    }
}
