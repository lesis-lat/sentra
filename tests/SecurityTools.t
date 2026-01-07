package SecurityTools;

our $VERSION = '0.0.1';

use strict;
use warnings;
use lib "../lib/";
use Test::More;
use Test::MockModule;
use HTTP::Response;
use JSON;
use Sentra::Engine::SecurityTools;

use Readonly;
Readonly my $HTTP_OK => 200;
Readonly my $HTTP_NOT_FOUND => 404;
Readonly my $PER_PAGE => 100;

my $mock_lwp_ua = Test::MockModule->new('LWP::UserAgent');

my $repo_list_page_count_st = 0;

$mock_lwp_ua->mock('get', sub {
    my ($self, $url_or_request) = @_;
    my $url = ref $url_or_request ? $url_or_request->uri->as_string : $url_or_request;

    my $res = HTTP::Response->new;

    if ($url =~ m{/orgs/test-org/repos\?}xms) {
        $repo_list_page_count_st++;
        $res->code($HTTP_OK);
        $res->message('OK');
        $res->header('Content-Type' => 'application/json');

        if ($repo_list_page_count_st == 1) {
            $res->content(encode_json([
                {name => "repo1", archived => JSON::false},
                {name => "repo2", archived => JSON::true}
            ]));
        }
        else {
            $res->content(encode_json([]));
        }
    }

    elsif ($url =~ m{/repos/test-org/repo1/contents/\.gitleaks\.toml}xms) {
        $res->code($HTTP_OK);
        $res->message('OK');
        $res->header('Content-Type' => 'application/json');
        $res->content(encode_json({name => '.gitleaks.toml'}));
    }

    elsif ($url =~ m{/repos/test-org/repo1/contents/\.github/workflows/codeql\.yml}xms) {
        $res->code($HTTP_OK);
        $res->message('OK');
        $res->header('Content-Type' => 'application/json');
        $res->content(encode_json({name => 'codeql.yml'}));
    }

    else {
        $res->code($HTTP_NOT_FOUND);
        $res->message('Not Found (Mock)');
        $res->content("URL not handled by mock: $url");
        diag "Mock LWP::UserAgent received unhandled GET in SecurityTools.t: $url";
    }

    return $res;
});

subtest 'SecurityTools' => sub {
    plan tests => 4;

    $repo_list_page_count_st = 0;

    my $tools_output = Sentra::Engine::SecurityTools->new('test-org', 'test-token', $PER_PAGE);

    like(
        $tools_output,
        qr{Secret\ scanning\ tools\ detected\ in\ https://github\.com/test-org/repo1:\ Gitleaks}xms,
        'Secret scanning tools detection message includes Gitleaks'
    );

    like(
        $tools_output,
        qr{SAST\ tools\ detected\ in\ https://github\.com/test-org/repo1:\ CodeQL}xms,
        'SAST tools detection message includes CodeQL'
    );

    unlike(
        $tools_output,
        qr{No\ secret\ scanning\ tools\ detected}xms,
        'Secret scanning tools detection did not report missing tools'
    );

    unlike(
        $tools_output,
        qr{No\ SAST\ tools\ detected}xms,
        'SAST tools detection did not report missing tools'
    );
};

done_testing();

1;
