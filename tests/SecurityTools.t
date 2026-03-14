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
my $repo_list_page_count_security_tools_perl = 0;

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

    if ($url =~ m{/orgs/test-org-perl/repos\?}xms) {
        $repo_list_page_count_security_tools_perl++;
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');

        if ($repo_list_page_count_security_tools_perl == 1) {
            $response -> content(encode_json([
                {name => "repo-perl", archived => JSON::false}
            ]));
        }

        if ($repo_list_page_count_security_tools_perl != 1) {
            $response -> content(encode_json([]));
        }

        return $response;
    }

    if ($url =~ m{/repos/test-org/repo1/languages}xms) {
        $response -> code($HTTP_NOT_FOUND);
        $response -> message('Not Found');
        $response -> header('Content-Type' => 'application/json');
        $response -> content(encode_json({message => "Not Found"}));

        return $response;
    }

    if ($url =~ m{/repos/test-org-perl/repo-perl/languages}xms) {
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');
        $response -> content(encode_json({Perl => 12345}));

        return $response;
    }

    if ($url =~ m{/repos/test-org/repo1/contents/\.gitleaks\.toml}xms) {
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');
        $response -> content(encode_json({name => '.gitleaks.toml'}));

        return $response;
    }

    if ($url =~ m{/repos/test-org-perl/repo-perl/contents/\.bunkai\.yml}xms) {
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');
        $response -> content(encode_json({name => '.bunkai.yml'}));

        return $response;
    }

    if ($url =~ m{/repos/test-org-perl/repo-perl/contents/\.zarn\.yml}xms) {
        $response -> code($HTTP_NOT_FOUND);
        $response -> message('Not Found');
        $response -> header('Content-Type' => 'application/json');
        $response -> content(encode_json({message => "Not Found"}));

        return $response;
    }

    if ($url =~ m{/repos/test-org-perl/repo-perl/contents/\.zarn\.yaml}xms) {
        $response -> code($HTTP_NOT_FOUND);
        $response -> message('Not Found');
        $response -> header('Content-Type' => 'application/json');
        $response -> content(encode_json({message => "Not Found"}));

        return $response;
    }

    if ($url =~ m{/repos/test-org-perl/repo-perl/contents/\.github/workflows/zarn\.yml}xms) {
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');
        $response -> content(encode_json({name => 'zarn.yml'}));

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

subtest 'SecurityTools with Perl-specific checks' => sub {
    plan tests => 4;

    $repo_list_page_count_security_tools_perl = 0;

    my %flow_message = (
        org      => 'test-org-perl',
        token    => 'test-token',
        per_page => $PER_PAGE
    );

    my $security_tools_output = Sentra::Component::SecurityTools -> new(\%flow_message);

    like(
        $security_tools_output,
        qr{Perl\ SCA\ tool\ check\ \(Bunkai\)\ in\ https://github\.com/test-org-perl/repo-perl:\ found}xms,
        'Perl SCA check reports Bunkai'
    );

    like(
        $security_tools_output,
        qr{Perl\ SAST\ tool\ check\ \(ZARN\)\ in\ https://github\.com/test-org-perl/repo-perl:\ found}xms,
        'Perl SAST check reports ZARN'
    );

    unlike(
        $security_tools_output,
        qr{Secret\ scanning\ tools\ detected\ in}xms,
        'Perl-specific path does not run generic secret scan output'
    );

    unlike(
        $security_tools_output,
        qr{SAST\ tools\ detected\ in}xms,
        'Perl-specific path does not run generic SAST scan output'
    );
};

done_testing();

1;
