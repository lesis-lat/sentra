package Sentra::Component::DependabotMetrics {
    use strict;
    use warnings;
    use JSON;
    use Sentra::Utils::UserAgent;
    use Sentra::Utils::Repositories_List;
    use Readonly;

    our $VERSION = '0.0.1';

    Readonly my $HTTP_OK => 200;
    Readonly my $ALERTS_PER_PAGE => 100;

    sub new {
        my (undef, $message) = @_;

        my $user_agent   = Sentra::Utils::UserAgent -> new($message -> {token});
        my @repositories = Sentra::Utils::Repositories_List -> new(
            $message -> {org},
            $message -> {token},
            $message -> {repo}
        );

        my $output   = q{};
        my $per_page = $message -> {per_page} || $ALERTS_PER_PAGE;
        my $metric_scope = $message -> {metric_scope} || 'all';
        my $dependabot_total_alerts = 0;
        my %dependabot_severity_count = (
            low      => 0,
            medium   => 0,
            high     => 0,
            critical => 0
        );
        my $secret_scanning_total_alerts = 0;
        my $code_scanning_total_alerts   = 0;
        my %code_scanning_severity_count = (
            low      => 0,
            medium   => 0,
            high     => 0,
            critical => 0
        );

        foreach my $repository (@repositories) {
            my @dependabot_alerts = _fetch_open_alerts(
                $user_agent,
                $repository,
                'dependabot/alerts',
                $per_page
            );

            $dependabot_total_alerts += scalar(@dependabot_alerts);
            foreach my $alert (@dependabot_alerts) {
                my $severity = $alert -> {security_vulnerability}{severity} || 'unknown';
                if (exists $dependabot_severity_count{$severity}) {
                    $dependabot_severity_count{$severity}++;
                }
            }

            my @secret_scanning_alerts = _fetch_open_alerts(
                $user_agent,
                $repository,
                'secret-scanning/alerts',
                $per_page
            );
            $secret_scanning_total_alerts += scalar(@secret_scanning_alerts);

            my @code_scanning_alerts = _fetch_open_alerts(
                $user_agent,
                $repository,
                'code-scanning/alerts',
                $per_page
            );
            $code_scanning_total_alerts += scalar(@code_scanning_alerts);

            foreach my $alert (@code_scanning_alerts) {
                my $severity = $alert -> {rule}{security_severity_level}
                    || $alert -> {rule}{severity}
                    || 'unknown';
                if (exists $code_scanning_severity_count{$severity}) {
                    $code_scanning_severity_count{$severity}++;
                }
            }
        }

        if ($metric_scope eq 'all' || $metric_scope eq 'dependabot') {
            $output .= "Dependabot Alerts\n";
            foreach my $severity_label (qw(critical high medium low)) {
                $output .= "Severity $severity_label: "
                    . $dependabot_severity_count{$severity_label}
                    . "\n";
            }
            $output .= "Total Dependabot Alerts: $dependabot_total_alerts\n";
        }

        if ($metric_scope eq 'all' || $metric_scope eq 'secret') {
            $output .= "\n" if $output ne q{};
            $output .= "Secret Scanning Alerts\n";
            $output .= "Total Secret Scanning Alerts: $secret_scanning_total_alerts\n";
        }

        if ($metric_scope eq 'all' || $metric_scope eq 'code') {
            $output .= "\n" if $output ne q{};
            $output .= "Code Scanning Alerts\n";
            foreach my $severity_label (qw(critical high medium low)) {
                $output .= "Severity $severity_label: "
                    . $code_scanning_severity_count{$severity_label}
                    . "\n";
            }
            $output .= "Total Code Scanning Alerts: $code_scanning_total_alerts\n";
        }

        return $output;
    }

    sub _fetch_open_alerts {
        my ($user_agent, $repository, $endpoint, $per_page) = @_;
        my @alerts;
        my $alert_page = 1;

        while (1) {
            my $alert_url = 'https://api.github.com/repos/'
                . $repository
                . '/'
                . $endpoint
                . '?state=open&per_page='
                . $per_page
                . "&page=$alert_page";
            my $alert_response = $user_agent -> get($alert_url);

            if ($alert_response -> code() != $HTTP_OK) {
                last;
            }

            my $alert_data = decode_json($alert_response -> content());
            if (scalar(@{$alert_data}) == 0) {
                last;
            }

            push @alerts, @{$alert_data};
            $alert_page++;
        }

        return @alerts;
    }
}

1;
