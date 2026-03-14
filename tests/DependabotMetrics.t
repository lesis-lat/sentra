package DependabotMetrics;

our $VERSION = '0.0.1';

use strict;
use warnings;
use lib "../lib/";
use Test::More;
use Test::MockModule;
use Sentra::Component::DependabotMetrics;
use HTTP::Response;
use JSON;
use Readonly;

Readonly my $HTTP_OK => 200;
Readonly my $HTTP_NOT_FOUND => 404;
Readonly my $PER_PAGE => 100;

my $mock_lwp_user_agent = Test::MockModule -> new('LWP::UserAgent');

my $repository_page_count = 0;
my $repo1_alert_fetch_count = 0;
my $repo1_secret_alert_fetch_count = 0;
my $repo1_code_alert_fetch_count = 0;
my $repository_page_count_second_org = 0;
my $repo1_second_org_alert_fetch_count = 0;
my $repo2_second_org_alert_fetch_count = 0;
my $repo1_second_org_secret_alert_fetch_count = 0;
my $repo2_second_org_secret_alert_fetch_count = 0;
my $repo1_second_org_code_alert_fetch_count = 0;
my $repo2_second_org_code_alert_fetch_count = 0;

$mock_lwp_user_agent -> mock('get', sub {
    my ($self, $url_or_request) = @_;
    my $url = $url_or_request;

    if (ref $url_or_request) {
        $url = $url_or_request -> uri -> as_string;
    }

    my $response = HTTP::Response -> new;

    if ($url =~ m{/orgs/test-org/repos\?}xms) {
        $repository_page_count++;
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');

        if ($repository_page_count == 1) {
            $response -> content(encode_json([
                {name => "repo1", archived => JSON::false},
                {name => "repo2", archived => JSON::true}
            ]));
        }

        if ($repository_page_count != 1) {
            $response -> content(encode_json([]));
        }

        return $response;
    }

    if ($url =~ m{/orgs/test-org-second/repos\?}xms) {
        $repository_page_count_second_org++;
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');

        if ($repository_page_count_second_org == 1) {
            $response -> content(encode_json([
                {name => "repo1", archived => JSON::false},
                {name => "repo2", archived => JSON::false}
            ]));
        }

        if ($repository_page_count_second_org != 1) {
            $response -> content(encode_json([]));
        }

        return $response;
    }

    if ($url =~ m{/repos/test-org/repo1/dependabot/alerts\?}xms) {
        $repo1_alert_fetch_count++;
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');

        if ($repo1_alert_fetch_count == 1) {
            $response -> content(encode_json([
                {security_vulnerability => {severity => "high"}},
                {security_vulnerability => {severity => "low"}}
            ]));
        }

        if ($repo1_alert_fetch_count != 1) {
            $response -> content(encode_json([]));
        }

        return $response;
    }

    if ($url =~ m{/repos/test-org/repo1/secret-scanning/alerts\?}xms) {
        $repo1_secret_alert_fetch_count++;
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');

        if ($repo1_secret_alert_fetch_count == 1) {
            $response -> content(encode_json([
                {number => 1}
            ]));
        }

        if ($repo1_secret_alert_fetch_count != 1) {
            $response -> content(encode_json([]));
        }

        return $response;
    }

    if ($url =~ m{/repos/test-org/repo1/code-scanning/alerts\?}xms) {
        $repo1_code_alert_fetch_count++;
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');

        if ($repo1_code_alert_fetch_count == 1) {
            $response -> content(encode_json([
                {rule => {security_severity_level => "high"}}
            ]));
        }

        if ($repo1_code_alert_fetch_count != 1) {
            $response -> content(encode_json([]));
        }

        return $response;
    }

    if ($url =~ m{/repos/test-org-second/repo1/dependabot/alerts\?}xms) {
        $repo1_second_org_alert_fetch_count++;
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');
        $response -> content(encode_json([]));

        return $response;
    }

    if ($url =~ m{/repos/test-org-second/repo2/dependabot/alerts\?}xms) {
        $repo2_second_org_alert_fetch_count++;
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');

        if ($repo2_second_org_alert_fetch_count == 1) {
            $response -> content(encode_json([
                {security_vulnerability => {severity => "critical"}}
            ]));
        }

        if ($repo2_second_org_alert_fetch_count != 1) {
            $response -> content(encode_json([]));
        }

        return $response;
    }

    if ($url =~ m{/repos/test-org-second/repo1/secret-scanning/alerts\?}xms) {
        $repo1_second_org_secret_alert_fetch_count++;
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');
        $response -> content(encode_json([]));

        return $response;
    }

    if ($url =~ m{/repos/test-org-second/repo2/secret-scanning/alerts\?}xms) {
        $repo2_second_org_secret_alert_fetch_count++;
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');

        if ($repo2_second_org_secret_alert_fetch_count == 1) {
            $response -> content(encode_json([
                {number => 99},
                {number => 100}
            ]));
        }

        if ($repo2_second_org_secret_alert_fetch_count != 1) {
            $response -> content(encode_json([]));
        }

        return $response;
    }

    if ($url =~ m{/repos/test-org-second/repo1/code-scanning/alerts\?}xms) {
        $repo1_second_org_code_alert_fetch_count++;
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');
        $response -> content(encode_json([]));

        return $response;
    }

    if ($url =~ m{/repos/test-org-second/repo2/code-scanning/alerts\?}xms) {
        $repo2_second_org_code_alert_fetch_count++;
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');

        if ($repo2_second_org_code_alert_fetch_count == 1) {
            $response -> content(encode_json([
                {rule => {security_severity_level => "low"}}
            ]));
        }

        if ($repo2_second_org_code_alert_fetch_count != 1) {
            $response -> content(encode_json([]));
        }

        return $response;
    }

    $response -> code($HTTP_NOT_FOUND);
    $response -> message('Not Found (Mock)');
    $response -> content("URL not handled by mock: $url");
    diag "Mock LWP::UserAgent received unhandled GET: $url";

    return $response;
});

subtest 'DependabotMetrics' => sub {
    plan tests => 5;

    $repository_page_count = 0;
    $repo1_alert_fetch_count = 0;
    $repo1_secret_alert_fetch_count = 0;
    $repo1_code_alert_fetch_count = 0;

    my %flow_message = (
        org      => 'test-org',
        token    => 'test-token',
        per_page => $PER_PAGE
    );

    my $metrics_output = Sentra::Component::DependabotMetrics -> new(\%flow_message);

    like($metrics_output, qr/Severity\s+high:\s+1/xms, 'High severity alert counted');
    like($metrics_output, qr/Severity\s+low:\s+1/xms, 'Low severity alert counted');
    like($metrics_output, qr/Total\s+Dependabot\s+Alerts:\s+2/xms, 'Dependabot total alerts counted correctly');
    like($metrics_output, qr/Total\s+Secret\s+Scanning\s+Alerts:\s+1/xms, 'Secret scanning total alerts counted correctly');
    like($metrics_output, qr/Total\s+Code\s+Scanning\s+Alerts:\s+1/xms, 'Code scanning total alerts counted correctly');
};

subtest 'DependabotMetrics continues after repository with zero alerts' => sub {
    plan tests => 4;

    $repository_page_count_second_org = 0;
    $repo1_second_org_alert_fetch_count = 0;
    $repo2_second_org_alert_fetch_count = 0;
    $repo1_second_org_secret_alert_fetch_count = 0;
    $repo2_second_org_secret_alert_fetch_count = 0;
    $repo1_second_org_code_alert_fetch_count = 0;
    $repo2_second_org_code_alert_fetch_count = 0;

    my %flow_message = (
        org      => 'test-org-second',
        token    => 'test-token',
        per_page => $PER_PAGE
    );

    my $metrics_output = Sentra::Component::DependabotMetrics -> new(\%flow_message);

    like($metrics_output, qr/Severity\s+critical:\s+1/xms, 'Critical severity alert counted in later repository');
    like($metrics_output, qr/Total\s+Dependabot\s+Alerts:\s+1/xms, 'Dependabot total alerts counted across repositories');
    like($metrics_output, qr/Total\s+Secret\s+Scanning\s+Alerts:\s+2/xms, 'Secret scanning total alerts counted across repositories');
    like($metrics_output, qr/Total\s+Code\s+Scanning\s+Alerts:\s+1/xms, 'Code scanning total alerts counted across repositories');
};

subtest 'DependabotMetrics supports split metric scopes' => sub {
    plan tests => 6;

    $repository_page_count = 0;
    $repo1_alert_fetch_count = 0;
    $repo1_secret_alert_fetch_count = 0;
    $repo1_code_alert_fetch_count = 0;

    my %dependabot_only_message = (
        org          => 'test-org',
        token        => 'test-token',
        per_page     => $PER_PAGE,
        metric_scope => 'dependabot'
    );
    my $dependabot_only_output = Sentra::Component::DependabotMetrics -> new(\%dependabot_only_message);
    like($dependabot_only_output, qr/Dependabot\ Alerts/xms, 'Dependabot-only includes Dependabot section');
    unlike($dependabot_only_output, qr/Secret\ Scanning\ Alerts/xms, 'Dependabot-only excludes Secret section');
    unlike($dependabot_only_output, qr/Code\ Scanning\ Alerts/xms, 'Dependabot-only excludes Code section');

    $repository_page_count = 0;
    $repo1_alert_fetch_count = 0;
    $repo1_secret_alert_fetch_count = 0;
    $repo1_code_alert_fetch_count = 0;

    my %secret_only_message = (
        org          => 'test-org',
        token        => 'test-token',
        per_page     => $PER_PAGE,
        metric_scope => 'secret'
    );
    my $secret_only_output = Sentra::Component::DependabotMetrics -> new(\%secret_only_message);
    like($secret_only_output, qr/Secret\ Scanning\ Alerts/xms, 'Secret-only includes Secret section');
    unlike($secret_only_output, qr/Dependabot\ Alerts/xms, 'Secret-only excludes Dependabot section');
    unlike($secret_only_output, qr/Code\ Scanning\ Alerts/xms, 'Secret-only excludes Code section');
};

done_testing();

1;
