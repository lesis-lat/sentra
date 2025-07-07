package SearchFiles;

our $VERSION = '0.0.1';

use strict;
use warnings;
use lib "../lib/";
use Test::More;
use Test::MockModule;
use HTTP::Response; 
use JSON;     
use Sentra::Engine::SearchFiles;      

use Readonly;
Readonly my $HTTP_OK => 200;
Readonly my $HTTP_NOT_FOUND => 404;
Readonly my $PER_PAGE => 100;

my $mock_lwp_ua = Test::MockModule->new('LWP::UserAgent');

my $repo_list_page_count_sf = 0;

$mock_lwp_ua->mock('get', sub {
    my ($self, $url_or_request) = @_;
    my $url = ref $url_or_request ? $url_or_request->uri->as_string : $url_or_request;
    
    my $res = HTTP::Response->new;

    if ($url =~ m{/orgs/test-org/repos\?}xms) { 
        $repo_list_page_count_sf++;
        $res->code($HTTP_OK);
        $res->message('OK');
        $res->header('Content-Type' => 'application/json');

        if ($repo_list_page_count_sf == 1) {
            $res->content(encode_json([
                {name => "repo1", archived => JSON::false}, 
                {name => "repo2", archived => JSON::true}
            ]));
        } 
        
        else {
            $res->content(encode_json([])); 
        }
    }
    
    elsif ($url =~ m{/repos/test-org/repo1/contents/\.github/dependabot\.yml}xms) { 
        $res->code($HTTP_NOT_FOUND);
        $res->message('Not Found');
        $res->header('Content-Type' => 'application/json'); 
        $res->content(encode_json({message => "Not Found", documentation_url => "..."}));
    }
    
    else {
        $res->code($HTTP_NOT_FOUND);
        $res->message('Not Found (Mock)');
        $res->content("URL not handled by mock: $url");
        diag "Mock LWP::UserAgent received unhandled GET in SearchFiles.t: $url";
    }
    
    return $res;
});

subtest 'SearchFiles' => sub {
    plan tests => 4; 

    $repo_list_page_count_sf = 0;

    my $search_output = Sentra::Engine::SearchFiles->new('test-org', 'test-token', $PER_PAGE);

    my $expected_text_1 = qr{The\ }xms;
    my $expected_text_2a = qr{\.github/dependabot\.yml}xms;
    my $expected_text_2b = qr{file\ was\ not\ found\ in\ this\ repository:}xms;
    my $expected_url_msg  = qr{https://github\.com/test-org/repo1}xms;

    like($search_output, $expected_text_1, 'Dependabot file not found message (part 1)');
    like($search_output, $expected_text_2a, 'Dependabot file not found message (file path)');
    like($search_output, $expected_text_2b, 'Dependabot file not found message (not found text)');
    like($search_output, $expected_url_msg,  'Dependabot file not found message (URL)');
};

done_testing();

1;