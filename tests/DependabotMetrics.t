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

$mock_lwp_user_agent -> mock('get', sub {
    my ($self, $url_or_request) = @_;
    my $url = ref $url_or_request ? $url_or_request -> uri -> as_string : $url_or_request;

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

    $response -> code($HTTP_NOT_FOUND);
    $response -> message('Not Found (Mock)');
    $response -> content("URL not handled by mock: $url");
    diag "Mock LWP::UserAgent received unhandled GET: $url";

    return $response;
});

subtest 'DependabotMetrics' => sub {
    plan tests => 3;

    $repository_page_count = 0;
    $repo1_alert_fetch_count = 0;

    my %flow_message = (
        org      => 'test-org',
        token    => 'test-token',
        per_page => $PER_PAGE
    );

    my $metrics_output = Sentra::Component::DependabotMetrics -> new(\%flow_message);

    like($metrics_output, qr/Severity\s+high:\s+1/xms, 'High severity alert counted');
    like($metrics_output, qr/Severity\s+low:\s+1/xms, 'Low severity alert counted');
    like($metrics_output, qr/Total\s+DependaBot\s+Alerts:\s+2/xms, 'Total alerts counted correctly');
};

done_testing();

1;
