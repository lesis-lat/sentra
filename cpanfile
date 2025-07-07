requires "Getopt::Long", "2.54";
requires "Mojo::UserAgent", "9.41";
requires "LWP::UserAgent", "6.44";
requires "JSON", "4.10";
requires "DateTime::Format::ISO8601", "0.16";
requires "DateTime", "1.65";

on 'test' => sub {
requires "Test::More", "1.302206";
requires "Test::MockModule", "0.179.0";
    requires "Mojo::Transaction::HTTP", "9.41";
};
