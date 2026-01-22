package SecurityTools;

our $VERSION = '0.0.1';

use strict;
use warnings;
use lib "../lib/";
use Test::More;
use Test::MockModule;
use HTTP::Response;
use JSON;
use Sentra::Component::SecurityTools;

use Readonly;
Readonly my $HTTP_OK => 200;
Readonly my $HTTP_NOT_FOUND => 404;
Readonly my $PER_PAGE => 100;

my $mock_lwp_user_agent = Test::MockModule -> new('LWP::UserAgent');

my $repo_list_page_count_security_tools = 0;

$mock_lwp_user_agent -> mock('get', sub {
    my ($self, $url_or_request) = @_;
    my $url = $url_or_request;

    if (ref $url_or_request) {
        $url = $url_or_request -> uri -> as_string;
    }

    my $response = HTTP::Response -> new;

    if ($url =~ m{/orgs/test-org/repos\?}xms) {
        $repo_list_page_count_security_tools++;
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');

        if ($repo_list_page_count_security_tools == 1) {
            $response -> content(encode_json([
                {name => "repo1", archived => JSON::false},
                {name => "repo2", archived => JSON::true}
            ]));
        }

        if ($repo_list_page_count_security_tools != 1) {
            $response -> content(encode_json([]));
        }

        return $response;
    }

    if ($url =~ m{/repos/test-org/repo1/contents/\.gitleaks\.toml}xms) {
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');
        $response -> content(encode_json({name => '.gitleaks.toml'}));

        return $response;
    }

    if ($url =~ m{/repos/test-org/repo1/contents/\.github/workflows/codeql\.yml}xms) {
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');
        $response -> content(encode_json({name => 'codeql.yml'}));

        return $response;
    }

    $response -> code($HTTP_NOT_FOUND);
    $response -> message('Not Found (Mock)');
    $response -> content("URL not handled by mock: $url");
    diag "Mock LWP::UserAgent received unhandled GET in SecurityTools.t: $url";

    return $response;
});

subtest 'SecurityTools' => sub {
    plan tests => 4;

    $repo_list_page_count_security_tools = 0;

    my %flow_message = (
        org      => 'test-org',
        token    => 'test-token',
        per_page => $PER_PAGE
    );

    my $security_tools_output = Sentra::Component::SecurityTools -> new(\%flow_message);

    like(
        $security_tools_output,
        qr{Secret\ scanning\ tools\ detected\ in\ https://github\.com/test-org/repo1:\ Gitleaks}xms,
        'Secret scanning tools detection message includes Gitleaks'
    );

    like(
        $security_tools_output,
        qr{SAST\ tools\ detected\ in\ https://github\.com/test-org/repo1:\ CodeQL}xms,
        'SAST tools detection message includes CodeQL'
    );

    unlike(
        $security_tools_output,
        qr{No\ secret\ scanning\ tools\ detected}xms,
        'Secret scanning tools detection did not report missing tools'
    );

    unlike(
        $security_tools_output,
        qr{No\ SAST\ tools\ detected}xms,
        'SAST tools detection did not report missing tools'
    );
};

done_testing();

1;
