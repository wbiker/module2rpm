use Cro::HTTP::Client;
use LogP6;

=begin pod

=head1 Cro::HTTP::Client

Wrapper for the Cro::HTTP::Client class.

=head1 DESCRIPTION

Encapsulates the get, put and delete method of the Cro::HTTP::Client class. For request with base authentication HTTP 1.1 is used.

=head1 SYNOPSIS

=begin code
my $client = Module2Rpm::Cro::Client.new(auth => {
    username => "user",
    password => "password"
});

my $message-body = $client.get('https://docs.raku.org');
$client.put($url, body => "something", content-type => "text/HTML);
$client.delete($url);
=end code

=head1 Methods

=head2 get(Str $url)

Returns the body of an requested URL

=head2 put(Str $url, :$body, :$content-type = "text/html")

Puts some data to a URL.

=head2 delete(Str $url)

Deletes a resource at a URL

=end pod

use Module2Rpm::Role::Internet;

class Module2Rpm::Cro::Client does Module2Rpm::Role::Internet {
    has $!log = get-logger($?CLASS.^name);

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
        $!log.debug("GET '$url'");
        my $response = await $!client.get($url);
        $!log.debug("Response status: " ~ $response.status);

        return await $response.body;
    }

    method put(Str $url, :$body, :$content-type = "text/html") {
        try {
            $!log.debug("PUT '$url', content-type: $content-type, body: $body");

            await $!client.put($url, :$content-type, :$body);

            CATCH {
                default { $!log.error("PUT request failed with { $_ } for '$url'"); }
            }
        }
    }

    method delete(Str $url) {
        $!log.debug("DELETE '$url'");
        return await $!client.delete($url);
    }
}
