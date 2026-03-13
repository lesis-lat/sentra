requires "Getopt::Long",                "2.58";
requires "Mojolicious", "9.42";
requires "LWP::UserAgent", "6.81";
requires "JSON",                        "4.10";
requires "DateTime::Format::ISO8601", "0.19";
requires "DateTime",                    "1.66";
requires "Readonly";
requires "LWP::Protocol::https";

on 'test' => sub {
    requires "Test::More", "1.302219";
    requires "Test::MockModule",            "0.180.0";
};