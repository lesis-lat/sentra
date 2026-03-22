package DependabotMetrics;

our $VERSION = '0.0.1';

use strict;
use warnings;
use lib '../lib/';
use Test::More;
use Test::MockModule;
use Sentra::Component::DependabotMetrics;
use HTTP::Response;
use JSON;
use Readonly;

Readonly my $HTTP_OK        => 200;
Readonly my $HTTP_NOT_FOUND => 404;
Readonly my $PER_PAGE       => 100;

my $mock_lwp_user_agent = Test::MockModule->new('LWP::UserAgent');

my %paged_counter = (
    test_org_repos                   => 0,
    test_org_second_repos            => 0,
    test_org_repo1_dependabot        => 0,
    test_org_repo1_secret            => 0,
    test_org_repo1_code              => 0,
    test_org_second_repo1_dependabot => 0,
    test_org_second_repo2_dependabot => 0,
    test_org_second_repo1_secret     => 0,
    test_org_second_repo2_secret     => 0,
    test_org_second_repo1_code       => 0,
    test_org_second_repo2_code       => 0,
);

my %dependabot_route_specs = (
    '/orgs/test-org/repos' => {
        counter => 'test_org_repos',
        first   => [
            { name => 'repo1', archived => JSON::false },
            { name => 'repo2', archived => JSON::true }
        ]
    },
    '/orgs/test-org-second/repos' => {
        counter => 'test_org_second_repos',
        first   => [
            { name => 'repo1', archived => JSON::false },
            { name => 'repo2', archived => JSON::false }
        ]
    },
    '/repos/test-org/repo1/dependabot/alerts' => {
        counter => 'test_org_repo1_dependabot',
        first   => [
            { security_vulnerability => { severity => 'high' } },
            { security_vulnerability => { severity => 'low' } }
        ]
    },
    '/repos/test-org/repo1/secret-scanning/alerts' => {
        counter => 'test_org_repo1_secret',
        first   => [ { number => 1 } ]
    },
    '/repos/test-org/repo1/code-scanning/alerts' => {
        counter => 'test_org_repo1_code',
        first   => [ { rule => { security_severity_level => 'high' } } ]
    },
    '/repos/test-org-second/repo1/dependabot/alerts' => {
        counter => 'test_org_second_repo1_dependabot',
        first   => []
    },
    '/repos/test-org-second/repo2/dependabot/alerts' => {
        counter => 'test_org_second_repo2_dependabot',
        first   => [ { security_vulnerability => { severity => 'critical' } } ]
    },
    '/repos/test-org-second/repo1/secret-scanning/alerts' => {
        counter => 'test_org_second_repo1_secret',
        first   => []
    },
    '/repos/test-org-second/repo2/secret-scanning/alerts' => {
        counter => 'test_org_second_repo2_secret',
        first   => [ { number => 99 }, { number => 100 } ]
    },
    '/repos/test-org-second/repo1/code-scanning/alerts' => {
        counter => 'test_org_second_repo1_code',
        first   => []
    },
    '/repos/test-org-second/repo2/code-scanning/alerts' => {
        counter => 'test_org_second_repo2_code',
        first   => [ { rule => { security_severity_level => 'low' } } ],
    },
);

sub _extract_url {
    my ($url_or_request) = @_;

    if ( !ref $url_or_request ) {
        return $url_or_request;
    }

    return $url_or_request->uri->as_string;
}

sub _api_path {
    my ($url) = @_;
    my $path = $url;
    $path =~ s{^https://api[.]github[.]com}{}xms;
    return $path;
}

sub _path_without_query {
    my ($path_with_query) = @_;
    my $path = $path_with_query;
    $path =~ s{[?].*$}{}xms;
    return $path;
}

sub _json_response {
    my ( $code, $body ) = @_;
    my $message = 'OK';

    if ( $code != $HTTP_OK ) {
        $message = 'Not Found';
    }

    my $response = HTTP::Response->new;
    $response->code($code);
    $response->message($message);
    $response->header( 'Content-Type' => 'application/json' );
    $response->content( encode_json($body) );
    return $response;
}

sub _paged_json_response {
    my ( $counter_name, $first_payload ) = @_;

    $paged_counter{$counter_name}++;
    if ( $paged_counter{$counter_name} == 1 ) {
        return _json_response( $HTTP_OK, $first_payload );
    }

    return _json_response( $HTTP_OK, [] );
}

sub _dependabot_mock_response {
    my ($path_with_query) = @_;
    my $path = _path_without_query($path_with_query);

    if ( !exists $dependabot_route_specs{$path} ) {
        return;
    }

    my $spec = $dependabot_route_specs{$path};
    return _paged_json_response( $spec->{counter}, $spec->{first} );
}

sub _not_found_response {
    my ($url) = @_;
    my $response = HTTP::Response->new;
    $response->code($HTTP_NOT_FOUND);
    $response->message('Not Found (Mock)');
    $response->content("URL not handled by mock: $url");
    diag "Mock LWP::UserAgent received unhandled GET: $url";
    return $response;
}

sub _mock_dependabot_get {
    my ( $self, $url_or_request ) = @_;
    my $url             = _extract_url($url_or_request);
    my $path_with_query = _api_path($url);

    my $response = _dependabot_mock_response($path_with_query);
    if ($response) {
        return $response;
    }

    return _not_found_response($url);
}

sub _reset_test_org_counters {
    $paged_counter{test_org_repos}            = 0;
    $paged_counter{test_org_repo1_dependabot} = 0;
    $paged_counter{test_org_repo1_secret}     = 0;
    $paged_counter{test_org_repo1_code}       = 0;
    return;
}

sub _reset_test_org_second_counters {
    $paged_counter{test_org_second_repos}            = 0;
    $paged_counter{test_org_second_repo1_dependabot} = 0;
    $paged_counter{test_org_second_repo2_dependabot} = 0;
    $paged_counter{test_org_second_repo1_secret}     = 0;
    $paged_counter{test_org_second_repo2_secret}     = 0;
    $paged_counter{test_org_second_repo1_code}       = 0;
    $paged_counter{test_org_second_repo2_code}       = 0;
    return;
}

$mock_lwp_user_agent->mock( 'get', \&_mock_dependabot_get );

subtest 'DependabotMetrics' => sub {
    plan tests => 5;

    _reset_test_org_counters();

    my %flow_message = (
        org      => 'test-org',
        token    => 'test-token',
        per_page => $PER_PAGE,
    );

    my $metrics_output =
      Sentra::Component::DependabotMetrics->new( \%flow_message );

    like( $metrics_output, qr/Severity\s+high:\s+1/xms,
        'High severity alert counted' );
    like( $metrics_output, qr/Severity\s+low:\s+1/xms,
        'Low severity alert counted' );
    like(
        $metrics_output,
        qr/Total\s+Dependabot\s+Alerts:\s+2/xms,
        'Dependabot total alerts counted correctly'
    );
    like(
        $metrics_output,
        qr/Total\s+Secret\s+Scanning\s+Alerts:\s+1/xms,
        'Secret scanning total alerts counted correctly'
    );
    like(
        $metrics_output,
        qr/Total\s+Code\s+Scanning\s+Alerts:\s+1/xms,
        'Code scanning total alerts counted correctly'
    );
};

subtest 'DependabotMetrics continues after repository with zero alerts' => sub {
    plan tests => 4;

    _reset_test_org_second_counters();

    my %flow_message = (
        org      => 'test-org-second',
        token    => 'test-token',
        per_page => $PER_PAGE,
    );

    my $metrics_output =
      Sentra::Component::DependabotMetrics->new( \%flow_message );

    like(
        $metrics_output,
        qr/Severity\s+critical:\s+1/xms,
        'Critical severity alert counted in later repository'
    );
    like(
        $metrics_output,
        qr/Total\s+Dependabot\s+Alerts:\s+1/xms,
        'Dependabot total alerts counted across repositories'
    );
    like(
        $metrics_output,
        qr/Total\s+Secret\s+Scanning\s+Alerts:\s+2/xms,
        'Secret scanning total alerts counted across repositories'
    );
    like(
        $metrics_output,
        qr/Total\s+Code\s+Scanning\s+Alerts:\s+1/xms,
        'Code scanning total alerts counted across repositories'
    );
};

subtest 'DependabotMetrics supports split metric scopes' => sub {
    plan tests => 6;

    _reset_test_org_counters();

    my %dependabot_only_message = (
        org          => 'test-org',
        token        => 'test-token',
        per_page     => $PER_PAGE,
        metric_scope => 'dependabot',
    );
    my $dependabot_only_output =
      Sentra::Component::DependabotMetrics->new( \%dependabot_only_message );
    ok(
        index( $dependabot_only_output, 'Dependabot Alerts' ) >= 0,
        'Dependabot-only includes Dependabot section'
    );
    ok( index( $dependabot_only_output, 'Secret Scanning Alerts' ) < 0,
        'Dependabot-only excludes Secret section' );
    ok( index( $dependabot_only_output, 'Code Scanning Alerts' ) < 0,
        'Dependabot-only excludes Code section' );

    _reset_test_org_counters();

    my %secret_only_message = (
        org          => 'test-org',
        token        => 'test-token',
        per_page     => $PER_PAGE,
        metric_scope => 'secret',
    );
    my $secret_only_output =
      Sentra::Component::DependabotMetrics->new( \%secret_only_message );
    ok( index( $secret_only_output, 'Secret Scanning Alerts' ) >= 0,
        'Secret-only includes Secret section' );
    ok(
        index( $secret_only_output, 'Dependabot Alerts' ) < 0,
        'Secret-only excludes Dependabot section'
    );
    ok( index( $secret_only_output, 'Code Scanning Alerts' ) < 0,
        'Secret-only excludes Code section' );
};

done_testing();

1;
