requires "Getopt::Long",                "2.58";
requires "Mojolicious", "9.42";
requires "LWP::UserAgent", "6.82";
requires "JSON", "4.11";
requires "DateTime::Format::ISO8601", "0.19";
requires "DateTime",                    "1.66";
requires "Readonly", "2.05";
requires "LWP::Protocol::https", "6.15";

on 'test' => sub {
    requires "Test::More", "1.302219";
    requires "Test::MockModule", "v0.183.0";
};