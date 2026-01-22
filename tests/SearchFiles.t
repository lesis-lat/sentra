package SearchFiles;

our $VERSION = '0.0.1';

use strict;
use warnings;
use lib "../lib/";
use Test::More;
use Test::MockModule;
use HTTP::Response;
use JSON;
use Sentra::Component::SearchFiles;

use Readonly;
Readonly my $HTTP_OK => 200;
Readonly my $HTTP_NOT_FOUND => 404;
Readonly my $PER_PAGE => 100;

my $mock_lwp_user_agent = Test::MockModule -> new('LWP::UserAgent');

my $repo_list_page_count_search_files = 0;

$mock_lwp_user_agent -> mock('get', sub {
    my ($self, $url_or_request) = @_;
    my $url = $url_or_request;

    if (ref $url_or_request) {
        $url = $url_or_request -> uri -> as_string;
    }

    my $response = HTTP::Response -> new;

    if ($url =~ m{/orgs/test-org/repos\?}xms) {
        $repo_list_page_count_search_files++;
        $response -> code($HTTP_OK);
        $response -> message('OK');
        $response -> header('Content-Type' => 'application/json');

        if ($repo_list_page_count_search_files == 1) {
            $response -> content(encode_json([
                {name => "repo1", archived => JSON::false},
                {name => "repo2", archived => JSON::true}
            ]));
        }

        if ($repo_list_page_count_search_files != 1) {
            $response -> content(encode_json([]));
        }

        return $response;
    }

    if ($url =~ m{/repos/test-org/repo1/contents/\.github/dependabot\.yml}xms) {
        $response -> code($HTTP_NOT_FOUND);
        $response -> message('Not Found');
        $response -> header('Content-Type' => 'application/json');
        $response -> content(encode_json({message => "Not Found", documentation_url => "..."}));

        return $response;
    }

    $response -> code($HTTP_NOT_FOUND);
    $response -> message('Not Found (Mock)');
    $response -> content("URL not handled by mock: $url");
    diag "Mock LWP::UserAgent received unhandled GET in SearchFiles.t: $url";

    return $response;
});

subtest 'SearchFiles' => sub {
    plan tests => 4;

    $repo_list_page_count_search_files = 0;

    my %flow_message = (
        org      => 'test-org',
        token    => 'test-token',
        per_page => $PER_PAGE
    );

    my $search_output = Sentra::Component::SearchFiles -> new(\%flow_message);

    my $expected_prefix_text = qr{The\ }xms;
    my $expected_path_text = qr{\.github/dependabot\.yml}xms;
    my $expected_missing_text = qr{file\ was\ not\ found\ in\ this\ repository:}xms;
    my $expected_url_text  = qr{https://github\.com/test-org/repo1}xms;

    like($search_output, $expected_prefix_text, 'Dependabot file not found message (part 1)');
    like($search_output, $expected_path_text, 'Dependabot file not found message (file path)');
    like($search_output, $expected_missing_text, 'Dependabot file not found message (not found text)');
    like($search_output, $expected_url_text,  'Dependabot file not found message (URL)');
};

done_testing();

1;
