package Sentra::Component::DependabotMetrics;

use strict;
use warnings;
use JSON;
use Sentra::Utils::UserAgent;
use Sentra::Utils::Repositories_List;
use Readonly;

our $VERSION = '0.0.1';

Readonly my $HTTP_OK         => 200;
Readonly my $ALERTS_PER_PAGE => 100;

sub new {
    my ( undef, $message ) = @_;

    my $user_agent = Sentra::Utils::UserAgent->new( $message->{token} );
    my @repositories =
      Sentra::Utils::Repositories_List->new( $message->{org}, $message->{token},
        $message->{repo} );

    my $per_page     = $message->{per_page}     || $ALERTS_PER_PAGE;
    my $metric_scope = $message->{metric_scope} || 'all';

    my %metrics = (
        dependabot_total_alerts      => 0,
        secret_scanning_total_alerts => 0,
        code_scanning_total_alerts   => 0,
        dependabot_severity_count    => { _initialize_severity_count() },
        code_scanning_severity_count => { _initialize_severity_count() },
    );

    foreach my $repository (@repositories) {
        my @dependabot_alerts =
          _fetch_open_alerts( $user_agent, $repository, 'dependabot/alerts',
            $per_page );
        _accumulate_dependabot_metrics( \@dependabot_alerts, \%metrics );

        my @secret_scanning_alerts =
          _fetch_open_alerts( $user_agent, $repository,
            'secret-scanning/alerts', $per_page );
        _accumulate_secret_metrics( \@secret_scanning_alerts, \%metrics );

        my @code_scanning_alerts =
          _fetch_open_alerts( $user_agent, $repository, 'code-scanning/alerts',
            $per_page );
        _accumulate_code_metrics( \@code_scanning_alerts, \%metrics );
    }

    return _render_metrics_output( $metric_scope, \%metrics );
}

sub _initialize_severity_count {
    return (
        low      => 0,
        medium   => 0,
        high     => 0,
        critical => 0
    );
}

sub _accumulate_dependabot_metrics {
    my ( $alerts, $metrics ) = @_;

    $metrics->{dependabot_total_alerts} += scalar @{$alerts};

    foreach my $alert ( @{$alerts} ) {
        my $severity = $alert->{security_vulnerability}{severity} || 'unknown';
        if ( exists $metrics->{dependabot_severity_count}{$severity} ) {
            $metrics->{dependabot_severity_count}{$severity}++;
        }
    }
    return;
}

sub _accumulate_secret_metrics {
    my ( $alerts, $metrics ) = @_;

    $metrics->{secret_scanning_total_alerts} += scalar @{$alerts};
    return;
}

sub _accumulate_code_metrics {
    my ( $alerts, $metrics ) = @_;

    $metrics->{code_scanning_total_alerts} += scalar @{$alerts};

    foreach my $alert ( @{$alerts} ) {
        my $severity =
             $alert->{rule}{security_severity_level}
          || $alert->{rule}{severity}
          || 'unknown';
        if ( exists $metrics->{code_scanning_severity_count}{$severity} ) {
            $metrics->{code_scanning_severity_count}{$severity}++;
        }
    }
    return;
}

sub _render_metrics_output {
    my ( $metric_scope, $metrics ) = @_;

    my $output = q{};

    if ( $metric_scope eq 'all' || $metric_scope eq 'dependabot' ) {
        $output .= _render_dependabot_section(
            $metrics->{dependabot_total_alerts},
            $metrics->{dependabot_severity_count}
        );
    }

    if ( $metric_scope eq 'all' || $metric_scope eq 'secret' ) {
        if ( $output ne q{} ) {
            $output .= "\n";
        }
        $output .=
          _render_secret_section( $metrics->{secret_scanning_total_alerts} );
    }

    if ( $metric_scope eq 'all' || $metric_scope eq 'code' ) {
        if ( $output ne q{} ) {
            $output .= "\n";
        }
        $output .= _render_code_section(
            $metrics->{code_scanning_total_alerts},
            $metrics->{code_scanning_severity_count}
        );
    }

    return $output;
}

sub _render_dependabot_section {
    my ( $total_alerts, $severity_count ) = @_;

    my $output = "Dependabot Alerts\n";
    foreach my $severity_label (qw(critical high medium low)) {
        $output .= "Severity $severity_label: "
          . $severity_count->{$severity_label} . "\n";
    }
    $output .= "Total Dependabot Alerts: $total_alerts\n";
    return $output;
}

sub _render_secret_section {
    my ($total_alerts) = @_;

    my $output = "Secret Scanning Alerts\n";
    $output .= "Total Secret Scanning Alerts: $total_alerts\n";
    return $output;
}

sub _render_code_section {
    my ( $total_alerts, $severity_count ) = @_;

    my $output = "Code Scanning Alerts\n";
    foreach my $severity_label (qw(critical high medium low)) {
        $output .= "Severity $severity_label: "
          . $severity_count->{$severity_label} . "\n";
    }
    $output .= "Total Code Scanning Alerts: $total_alerts\n";
    return $output;
}

sub _fetch_open_alerts {
    my ( $user_agent, $repository, $endpoint, $per_page ) = @_;
    my @alerts;
    my $alert_page = 1;

    while (1) {
        my $alert_url =
            q{https://api.github.com/repos/}
          . $repository . q{/}
          . $endpoint
          . '?state=open&per_page='
          . $per_page
          . "&page=$alert_page";
        my $alert_response = $user_agent->get($alert_url);

        if ( $alert_response->code() != $HTTP_OK ) {
            last;
        }

        my $alert_data = decode_json( $alert_response->content() );
        if ( scalar( @{$alert_data} ) == 0 ) {
            last;
        }

        push @alerts, @{$alert_data};
        $alert_page++;
    }

    return @alerts;
}

1;
