package Helper;

our $VERSION = '0.0.1';

use strict;
use warnings;
use lib '../lib/';
use Sentra::Utils::Helper;
use Test::More;

subtest 'Helper' => sub {
    plan tests => 25;

    my $helper_output = Sentra::Utils::Helper->new;

    ok( defined $helper_output, 'Helper output is defined' );
    is( ref $helper_output, q{}, 'Helper output is a string' );

    ok(
        index( $helper_output, 'Sentra v' ) >= 0,
        'Helper output contains version information'
    );
    ok(
        index( $helper_output, 'Core Commands' ) >= 0,
        'Helper output contains core commands'
    );

    ok(
        index( $helper_output, '-o, --org' ) >= 0,
        'Helper output contains org option'
    );
    ok(
        index( $helper_output, '-r, --repo' ) >= 0,
        'Helper output contains repo option'
    );
    ok(
        index( $helper_output, '-t, --token' ) >= 0,
        'Helper output contains token option'
    );
    ok(
        index( $helper_output, '-mt, --maintained' ) >= 0,
        'Helper output contains maintained option'
    );
    ok(
        index( $helper_output, '-d, --dependency' ) >= 0,
        'Helper output contains dependency option'
    );
    ok(
        index( $helper_output, '-M, --metrics' ) >= 0,
        'Helper output contains metrics option'
    );
    ok(
        $helper_output =~ /--metrics-dependabot/xms,
        'Helper output contains metrics dependabot option'
    );
    ok(
        $helper_output =~ /--metrics-secret/xms,
        'Helper output contains metrics secret option'
    );
    ok(
        $helper_output =~ /--metrics-code/xms,
        'Helper output contains metrics code option'
    );
    ok(
        $helper_output =~ /--static-analysis/xms,
        'Helper output contains static analysis option'
    );
    ok(
        index( $helper_output, '-w, --webhook' ) >= 0,
        'Helper output contains webhook option'
    );
    ok(
        index( $helper_output, '-m, --message' ) >= 0,
        'Helper output contains message option'
    );

    ok(
        index( $helper_output, 'Description' ) >= 0,
        'Helper output contains Description'
    );
    ok(
        index( $helper_output, 'Command' ) >= 0,
        'Helper output contains Command'
    );
    ok(
        index( $helper_output, '-------' ) >= 0,
        'Helper output contains dashes'
    );
    ok(
        $helper_output =~ m/[[:space:]]/xms,
        'Helper output contains whitespace'
    );
    ok( index( $helper_output, "\n" ) >= 0, 'Helper output contains newline' );
    ok(
        index( $helper_output, 'Sentra v' ) == 0,
        'Helper output starts at beginning'
    );
    ok( length($helper_output) > 0, 'Helper output ends at end' );

    my @expected_options = (
        '-o, --org',
        '-r, --repo',
        '-t, --token',
        '-mt, --maintained',
        '-d, --dependency',
        '-M, --metrics',
        '--metrics-dependabot',
        '--metrics-secret',
        '--metrics-code',
        '--static-analysis',
        '-w, --webhook',
        '-m, --message',
    );

    my @missing_options;

    for my $option (@expected_options) {
        if ( $helper_output !~ m/\Q$option\E/xms ) {
            push @missing_options, $option;
        }
    }

    is( scalar @missing_options, 0, 'All expected command options are present' )
      or diag 'Missing options: ' . join ', ', @missing_options;

    my $options_debug =
      "Options found in helper output for expected options:\n";
    for my $option (@expected_options) {
        my $option_status = 'No';

        if ( $helper_output =~ m/\Q$option\E/xms ) {
            $option_status = 'Yes';
        }

        $options_debug .= sprintf '%s: %s' . "\n", $option, $option_status;
    }
    diag $options_debug;
    pass('Printed debug information about options');
};

done_testing();

1;
