package Helper;

use strict;
use warnings;
use lib "../lib/";
use Sentra::Utils::Helper;
use Test::More;

our $VERSION = '0.0.1';

subtest 'Helper' => sub {
    plan tests => 20;

    my $helper_output = Sentra::Utils::Helper->new();

    ok(defined $helper_output, 'Helper output is defined');
    is(ref $helper_output, q{}, 'Helper output is a string');

    like($helper_output, qr/Sentra\ v0\.0\.1/xms, 'Helper output contains version information');
    like($helper_output, qr/Core\ Commands/xms, 'Helper output contains core commands');

    ok($helper_output =~ /-o,\ --org/xms, 'Helper output contains org option');
    ok($helper_output =~ /-t,\ --token/xms, 'Helper output contains token option');
    ok($helper_output =~ /-mt,\ --maintained/xms, 'Helper output contains maintained option');
    ok($helper_output =~ /-d,\ --dependency/xms, 'Helper output contains dependency option');
    ok($helper_output =~ /-M,\ --metrics/xms, 'Helper output contains metrics option');
    ok($helper_output =~ /-w,\ --webhook/xms, 'Helper output contains webhook option');
    ok($helper_output =~ /-m,\ --message/xms, 'Helper output contains message option');

    ok($helper_output =~ /Description/xms, 'Helper output contains Description');
    ok($helper_output =~ /Command/xms, 'Helper output contains Command');
    ok($helper_output =~ /-------/xms, 'Helper output contains dashes');
    ok($helper_output =~ /\s+/xms, 'Helper output contains whitespace');
    ok($helper_output =~ /\n/xms, 'Helper output contains newline');
    ok($helper_output =~ /\A/xms, 'Helper output starts at beginning');
    ok($helper_output =~ /\z/xms, 'Helper output ends at end');

    my @expected_options = (
        '-o, --org',
        '-t, --token',
        '-mt, --maintained',
        '-d, --dependency',  
        '-M, --metrics',
        '-w, --webhook',
        '-m, --message'
    );

    my @missing_options;
    
    for my $option (@expected_options) {
        if ($helper_output !~ m/\Q$option\E/xms) {
            push @missing_options, $option;
        }
    }

    is(scalar @missing_options, 0, 'All expected command options are present')
        or diag "Missing options: " . join(", ", @missing_options);

    my $options_debug = "Options found in helper output for expected options:\n";
    for my $option (@expected_options) {
        $options_debug .= sprintf("%s: %s\n", $option, $helper_output =~ m/\Q$option\E/xms ? "Yes" : "No");
    }
    diag $options_debug;
    pass('Printed debug information about options');
};

done_testing();

1;