#!/usr/bin/env perl

use 5.030;
use strict;
use warnings;
use lib './lib/';
use Getopt::Long qw(:config no_ignore_case);
use Sentra::Utils::Helper;
use Sentra::Engine::Maintained;
use Sentra::Engine::SearchFiles;
use Sentra::Engine::SlackWebhook;
use Sentra::Engine::DependabotMetrics;
use Sentra::Engine::SecurityTools;
use Readonly;

our $VERSION = '0.0.1';

Readonly my $PER_PAGE => 100;

sub main {
    my ($org, $token, $webhook, $message, $help, %options);

    my $per_page = $PER_PAGE;

    GetOptions (
        'o|org=s'       => \$org,
        't|token=s'     => \$token,
        'w|webhook=s'   => \$webhook,
        'm|message=s'   => \$message,
        'h|help'        => \$help,
        'mt|maintained' => \$options{'maintained'},
        'd|dependency'  => \$options{'dependency'},
        'M|metrics'     => \$options{'metrics'},
        'ss|secret-scanning' => \$options{'secret_scanning'},
        'sast'               => \$options{'sast'},
    );

    my %dispatch_table = (
        'metrics'    => sub { Sentra::Engine::DependabotMetrics -> new($org, $token, $per_page) },
        'dependency' => sub { Sentra::Engine::SearchFiles -> new($org, $token, $per_page) },
        'maintained' => sub { Sentra::Engine::Maintained -> new($org, $token, $per_page) },
        'secret_scanning' => sub { Sentra::Engine::SecurityTools -> new($org, $token, $per_page) },
        'sast'            => sub { Sentra::Engine::SecurityTools -> new($org, $token, $per_page) },
    );

    for my $option (keys %options) {
        if ($options{$option} && exists $dispatch_table{$option}) {
            print $dispatch_table{$option}->();
        }
    }

    if ($webhook && $message) {
        my $send = Sentra::Engine::SlackWebhook -> new($message, $webhook);

        if ($send) {
            return 0;
        }
    }

    if ($help) {
        print Sentra::Utils::Helper -> new();

        return 0;
    }

    return 1;
}

exit main();
