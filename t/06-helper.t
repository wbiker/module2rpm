use Test;
use File::Temp;
use Test::Mock;

use Module2Rpm::Helper;

{
    my $helper;
    my $client_mock = mocked Module2Rpm::Cro::Client;
    lives-ok { $helper = Module2Rpm::Helper.new(client => $client_mock) }, "Creation of helper works without exceptions";
    is $helper.client.WHAT, $client_mock.WHAT, "client object is the expected one";
    ok $helper.is-meta-url("http://something.meta"), "Meta url recognized";
    nok $helper.is-meta-url("Module::Name"), "Name instead of meta url recognized";
    ok $helper.is-module-name("Module.:Name"), "Module name found";
    nok $helper.is-module-name("http://something.meta"), "Url instead of Name";
}

{
    my $download_return_strings = (
    '[
        {
          "auth": "github:arjancwidlak",
          "authors": "Arjan Widlak <acw@cpan.org",
          "build-depends": [

          ],
          "depends": [
            "Config::Parser",
            "JSON::Fast"
          ],
          "description": "JSON parser for Config",
          "license": [
            "GPL",
            "Artistic-2.0"
          ],
          "name": "Config::Parser::json",
          "perl": "6.*",
          "provides": {
            "Config::Parser::json": "lib/Config/Parser/json.pm6"
          },
          "source-url": "http://www.cpan.org/authors/id/A/AC/ACW/Perl6/Config-Parser-json-1.0.0.tar.gz",
          "tags": [
            "config",
            "configuration"
          ],
          "test-depends": [
            "File::Temp",
            "Test::META"
          ],
          "version": "1.0.0"
        }
    ]',
    '[
        {
              "authors": [
                "Takumi Akiyama"
              ],
              "build-depends": [

              ],
              "depends": [

              ],
              "description": "Human JSON (Hjson) deserializer",
              "license": "Artistic-2.0",
              "name": "JSON::Hjson",
              "perl": "6.c",
              "provides": {
                "JSON::Hjson": "lib/JSON/Hjson.pm6",
                "JSON::Hjson::Actions": "lib/JSON/Hjson/Actions.pm6",
                "JSON::Hjson::Grammar": "lib/JSON/Hjson/Grammar.pm6"
              },
              "resources": [

              ],
              "source-url": "http://www.cpan.org/authors/id/A/AK/AKIYM/Perl6/JSON-Hjson-0.0.1.tar.gz",
              "tags": [

              ],
              "test-depends": [
              "JSON::Tiny",
              "Test::META"
            ],
            "version": "0.0.1"
        }
    ]').iterator;

    my $client_mock = mocked Module2Rpm::Cro::Client, computing => {
        get => { $download_return_strings.pull-one },
    };
    my $helper = Module2Rpm::Helper.new(client => $client_mock);
    my %all-metadata;
    lives-ok { %all-metadata = $helper.fetch-metadata() }, "Fetch-metadata does not die";

    my %expected-metadata = ${
        "Config::Parser::json" => ${
            :auth("github:arjancwidlak"),
            :authors("Arjan Widlak <acw\@cpan.org"),
            :build-depends($[]),
            :depends($["Config::Parser", "JSON::Fast"]),
            :description("JSON parser for Config"),
            :license($["GPL", "Artistic-2.0"]),
            :name("Config::Parser::json"),
            :perl("6.*"),
            :provides(${"Config::Parser::json" => "lib/Config/Parser/json.pm6"}),
            :source-url("http://www.cpan.org/authors/id/A/AC/ACW/Perl6/Config-Parser-json-1.0.0.tar.gz"),
            :tags($["config", "configuration"]),
            :test-depends($["File::Temp", "Test::META"]), :version("1.0.0")
        },
        "JSON::Hjson" => ${
            :authors($["Takumi Akiyama"]),
            :build-depends($[]),
            :depends($[]),
            :description("Human JSON (Hjson) deserializer"),
            :license("Artistic-2.0"),
            :name("JSON::Hjson"),
            :perl("6.c"),
            :provides(${"JSON::Hjson" => "lib/JSON/Hjson.pm6", "JSON::Hjson::Actions" => "lib/JSON/Hjson/Actions.pm6", "JSON::Hjson::Grammar" => "lib/JSON/Hjson/Grammar.pm6"}),
            :resources($[]),
            :source-url("http://www.cpan.org/authors/id/A/AK/AKIYM/Perl6/JSON-Hjson-0.0.1.tar.gz"),
            :tags($[]),
            :test-depends($["JSON::Tiny", "Test::META"]),
            :version("0.0.1")}
    }

    is-deeply %all-metadata, %expected-metadata, "Recieved metadata are the expected ones";
}

{
    # To test create-package(), the return values for client.get must be prepared. First the metadata
    # from the JSONs URL are expected.
    my $return_strings = (
        '[
            {
                "authors": [
                    "pnu",
                    "wbiker"
                ],
                "build-depends": [],
                "depends": [],
                "description": "This is a generic module for interactive prompting from the console.",
                "license": "Artistic-2.0",
                "name": "IO::Prompt",
                "perl": "6.*",
                "provides": {
                    "IO::Prompt": "lib/IO/Prompt.pm"
                },
                "resources": [],
                "source-url": "http://www.cpan.org/authors/id/W/WB/WBIKER/Perl6/IO-Prompt-0.0.2.tar.gz",
                "tags": [],
                "test-depends": [
                    "Test"
                ],
                "version": "0.0.2"
            }
    ]',
    # Then the json string from a source url:
    '[
            {
                "depends" : [
                    "LibXML",
                    "CSS::Module",
                    "CSS::Properties:ver<0.5.0+>",
                    "CSS::Selector::To::XPath"
                ],
                "description" : "CSS Stylesheet processing",
                "license" : "Artistic-2.0",
                "name" : "CSS",
                "perl" : "6.c",
                "provides" : {
                    "CSS" : "lib/CSS.rakumod",
                    "CSS::Media" : "lib/CSS/Media.rakumod",
                    "CSS::Ruleset" : "lib/CSS/Ruleset.rakumod",
                    "CSS::Selectors" : "lib/CSS/Selectors.rakumod",
                    "CSS::Stylesheet" : "lib/CSS/Stylesheet.rakumod",
                    "CSS::TagSet" : "lib/CSS/TagSet.rakumod",
                    "CSS::TagSet::XHTML" : "lib/CSS/TagSet/XHTML.rakumod"
                },
                "resources" : [
                    "xhtml.css"
                ],
                "source-url" : "http://www.cpan.org/authors/id/W/WA/WARRINGD/Perl6/CSS-0.0.5.tar.gz",
                "tags" : [
                    "xml",
                    "html",
                    "xpath",
                    "css"
                ],
                "version" : "0.0.5"
            }
            ]',
    # This is the return string from the metadata download.
    # Must not be an array.
        '{
            "depends" : [
              "LibXML",
              "CSS::Module",
              "CSS::Properties:ver<0.5.0+>",
              "CSS::Selector::To::XPath"
            ],
            "description" : "CSS Stylesheet processing",
            "license" : "Artistic-2.0",
            "name" : "CSS",
            "perl" : "6.c",
            "provides" : {
              "CSS" : "lib/CSS.rakumod",
              "CSS::Media" : "lib/CSS/Media.rakumod",
              "CSS::Ruleset" : "lib/CSS/Ruleset.rakumod",
              "CSS::Selectors" : "lib/CSS/Selectors.rakumod",
              "CSS::Stylesheet" : "lib/CSS/Stylesheet.rakumod",
              "CSS::TagSet" : "lib/CSS/TagSet.rakumod",
              "CSS::TagSet::XHTML" : "lib/CSS/TagSet/XHTML.rakumod"
            },
            "resources" : [
              "xhtml.css"
            ],
            "source-url" : "http://www.cpan.org/authors/id/W/WA/WARRINGD/Perl6/CSS-0.0.5.tar.gz",
            "tags" : [
              "xml",
              "html",
              "xpath",
              "css"
            ],
            "version" : "0.0.5"
        }'
   ).iterator;

    my $client_mock = mocked Module2Rpm::Cro::Client, computing => {
        get => { $return_strings.pull-one },
    };

    my $helper = Module2Rpm::Helper.new(client => $client_mock);
    throws-like { $helper.create-packages(path => tempdir().IO, file => "filedoesnotexists".IO) }, X::AdHoc, payload => /'does not exists'/;

    my ($tempfile) = tempfile();
    $tempfile .= IO;
    $tempfile.spurt(
        q:to/END/
        IO::Prompt
        http://www.cpan.org/authors/id/W/WA/WARRINGD/Perl6/CSS-0.0.5.meta
        END
    );
    my @packages = $helper.create-packages(path => tempdir().IO, file => $tempfile);
    is @packages[0].module-name(), "perl6-IO-Prompt", "create-packages has first module";
    is @packages[1].module-name(), "perl6-CSS", "create-packages has second module";
}
{
    my $return_strings = (
    '[
        {
          "name": "Test::Module::For::Version",
          "version": "1.0.0"
        }
    ]',
    '[
        {
              "name": "Test::Module::For::Version",
              "version": "0.0.1"
        }
    ]').iterator;
    my $client_mock = mocked Module2Rpm::Cro::Client, computing => {
        get => { $return_strings.pull-one },
    };

    my $helper = Module2Rpm::Helper.new(client => $client_mock);
    my %all-metadata;
    lives-ok { %all-metadata = $helper.fetch-metadata() }, "Fetch-metadata does not die";

    my %expected-metadata = ${
        "Test::Module::For::Version" => ${
            :name("Test::Module::For::Version"),
            :version("1.0.0")
        },
    }

    is-deeply %all-metadata, %expected-metadata, "Recieved metadata with different versions are the expected one";
}
done-testing;
