package DependabotMetrics;

use strict;
use warnings;
use lib "../lib/";
use Test::More;
use Test::MockModule;
use Sentra::Engine::DependabotMetrics;
use HTTP::Response; 
use JSON;
use Readonly;

our $VERSION = '0.0.1';

Readonly my $HTTP_OK => 200;
Readonly my $HTTP_NOT_FOUND => 404;
Readonly my $PER_PAGE => 100;

my $mock_lwp_ua = Test::MockModule->new('LWP::UserAgent');

my $repo_list_page_count = 0;
my $alert_fetch_count_repo1 = 0;

$mock_lwp_ua->mock('get', sub {
    my ($self, $url_or_request) = @_;
    my $url = ref $url_or_request ? $url_or_request->uri->as_string : $url_or_request;

    my $res = HTTP::Response->new;

    if ($url =~ m{/orgs/test-org/repos\?}xms) { 
        $repo_list_page_count++;
        $res->code($HTTP_OK);
        $res->message('OK');
        $res->header('Content-Type' => 'application/json');

        if ($repo_list_page_count == 1) {
            $res->content(encode_json([
                {name => "repo1", archived => JSON::false}, 
                {name => "repo2", archived => JSON::true}
            ]));
        } 
        
        else {
            $res->content(encode_json([])); 
        }
    }
    
    elsif ($url =~ m{/repos/test-org/repo1/dependabot/alerts\?}xms) { 
        $alert_fetch_count_repo1++;
        $res->code($HTTP_OK);
        $res->message('OK');
        $res->header('Content-Type' => 'application/json');

        if ($alert_fetch_count_repo1 == 1) {
            $res->content(encode_json([
                {security_vulnerability => {severity => "high"}},
                {security_vulnerability => {severity => "low"}}
            ]));
        } 
        
        else {
            $res->content(encode_json([])); 
        }
    }
    
    else {
        $res->code($HTTP_NOT_FOUND);
        $res->message('Not Found (Mock)');
        $res->content("URL not handled by mock: $url");
        diag "Mock LWP::UserAgent received unhandled GET: $url";
    }
    
    return $res;
});

subtest 'DependabotMetrics' => sub {
    plan tests => 3;

    $repo_list_page_count = 0;
    $alert_fetch_count_repo1 = 0;

    my $metrics = Sentra::Engine::DependabotMetrics->new('test-org', 'test-token', $PER_PAGE);

    like($metrics, qr/Severity\s+high:\s+1/xms, 'High severity alert counted');
    like($metrics, qr/Severity\s+low:\s+1/xms, 'Low severity alert counted');
    like($metrics, qr/Total\s+DependaBot\s+Alerts:\s+2/xms, 'Total alerts counted correctly');
};

done_testing();

1;