package Sentra::Network::Flow {
    use strict;
    use warnings;
    use Getopt::Long qw(:config no_ignore_case);
    use Readonly;
    use Sentra::Utils::Helper;
    use Sentra::Component::DependabotMetrics;
    use Sentra::Component::SearchFiles;
    use Sentra::Component::Maintained;
    use Sentra::Component::SecurityTools;
    use Sentra::Component::SlackWebhook;

    our $VERSION = '0.0.1';

    Readonly my $PER_PAGE => 100;

    sub new {
        my ($class) = @_;
        my ($org, $token, $webhook, $message, $help, %options);

        my $per_page = $PER_PAGE;

        GetOptions (
            'o|org=s'          => \$org,
            't|token=s'        => \$token,
            'w|webhook=s'      => \$webhook,
            'm|message=s'      => \$message,
            'h|help'           => \$help,
            'mt|maintained'    => \$options{'maintained'},
            'd|dependency'     => \$options{'dependency'},
            'M|metrics'        => \$options{'metrics'},
            'static-analysis'  => \$options{'security_tools'},
        );

        my %flow_message = (
            org      => $org,
            token    => $token,
            per_page => $per_page
        );

        my %dispatch_table = (
            'metrics'        => sub { Sentra::Component::DependabotMetrics -> new(\%flow_message) },
            'dependency'     => sub { Sentra::Component::SearchFiles -> new(\%flow_message) },
            'maintained'     => sub { Sentra::Component::Maintained -> new(\%flow_message) },
            'security_tools' => sub { Sentra::Component::SecurityTools -> new(\%flow_message) },
        );

        for my $option (keys %options) {
            if ($options{$option} && exists $dispatch_table{$option}) {
                print $dispatch_table{$option} -> ();
            }
        }

        if ($webhook && $message) {
            my %slack_message = (
                message => $message,
                webhook => $webhook
            );
            my $send_result = Sentra::Component::SlackWebhook -> new(\%slack_message);

            if ($send_result) {
                return 0;
            }
        }

        if ($help) {
            print Sentra::Utils::Helper -> new();

            return 0;
        }

        return 1;
    }
}

1;
