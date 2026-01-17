package Sentra::Component::DependabotMetrics {
    use strict;
    use warnings;
    use JSON;
    use Sentra::Utils::UserAgent;
    use Sentra::Utils::Repositories_List;
    use Readonly;

    our $VERSION = '0.0.1';

    Readonly my $HTTP_OK => 200;

    sub new {
        my (undef, $message) = @_;

        my $user_agent   = Sentra::Utils::UserAgent -> new($message -> {token});
        my @repositories = Sentra::Utils::Repositories_List -> new($message -> {org}, $message -> {token});

        my $output       = q{};
        my $per_page     = $message -> {per_page};
        my $total_alerts = 0;
        my %severity_count = (
            low      => 0,
            medium   => 0,
            high     => 0,
            critical => 0
        );

        foreach my $repository (@repositories) {
            my $alert_page     = 1;
            my $alert_url      = "https://api.github.com/repos/$repository/dependabot/alerts?state=open&per_page=$per_page&page=$alert_page";
            my $alert_response = $user_agent -> get($alert_url);

            if ($alert_response -> code() == $HTTP_OK) {
                my $alert_data = decode_json($alert_response -> content());

                if (scalar(@{$alert_data}) == 0) {
                    last;
                }

                $total_alerts += scalar(@{$alert_data});

                foreach my $alert (@{$alert_data}) {
                    my $severity = $alert -> {security_vulnerability}{severity} || 'unknown';

                    if (exists $severity_count{$severity}) {
                        $severity_count{$severity}++;
                    }
                }
            }
        }

        foreach my $severity_label (keys %severity_count) {
            $output .= "Severity $severity_label: $severity_count{$severity_label}\n";
        }

        $output .= "Total DependaBot Alerts: $total_alerts\n";

        return $output;
    }
}

1;
