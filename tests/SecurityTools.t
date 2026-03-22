package SecurityTools;

our $VERSION = '0.0.1';

use strict;
use warnings;
use lib '../lib/';
use Test::More;
use Test::MockModule;
use HTTP::Response;
use JSON;
use Sentra::Component::SecurityTools;

use Readonly;
Readonly my $HTTP_OK        => 200;
Readonly my $HTTP_NOT_FOUND => 404;
Readonly my $PER_PAGE       => 100;

my $mock_lwp_user_agent = Test::MockModule->new('LWP::UserAgent');

my $repo_list_page_count_security_tools              = 0;
my $repo_list_page_count_security_tools_perl         = 0;
my $repo_list_page_count_security_tools_perl_missing = 0;

my %security_static_response_by_path = (
    '/repos/test-org/repo1/languages' => {
        code => $HTTP_NOT_FOUND,
        body => { message => 'Not Found' }
    },
    '/repos/test-org-perl/repo-perl/languages' => {
        code => $HTTP_OK,
        body => { Perl => 12_345 }
    },
    '/repos/test-org-perl/repo-perl/contents/.gitleaks.toml' => {
        code => $HTTP_OK,
        body => { name => '.gitleaks.toml' }
    },
    '/repos/test-org-perl-missing/repo-perl-missing/languages' => {
        code => $HTTP_OK,
        body => { Perl => 999 }
    },
    '/repos/test-org/repo1/contents/.gitleaks.toml' => {
        code => $HTTP_OK,
        body => { name => '.gitleaks.toml' }
    },
    '/repos/test-org-perl/repo-perl/contents/.bunkai.yml' => {
        code => $HTTP_NOT_FOUND,
        body => { message => 'Not Found' }
    },
    '/repos/test-org-perl/repo-perl/contents/.bunkai.yaml' => {
        code => $HTTP_NOT_FOUND,
        body => { message => 'Not Found' }
    },
    '/repos/test-org-perl/repo-perl/contents/.github/workflows/bunkai.yml' => {
        code => $HTTP_OK,
        body => { name => 'bunkai.yml' }
    },
    '/repos/test-org-perl/repo-perl/contents/.zarn.yml' => {
        code => $HTTP_NOT_FOUND,
        body => { message => 'Not Found' }
    },
    '/repos/test-org-perl/repo-perl/contents/.zarn.yaml' => {
        code => $HTTP_NOT_FOUND,
        body => { message => 'Not Found' }
    },
    '/repos/test-org-perl/repo-perl/contents/.github/workflows/zarn.yml' => {
        code => $HTTP_OK,
        body => { name => 'zarn.yml' }
    },
    '/repos/test-org-perl-missing/repo-perl-missing/contents/.bunkai.yml' => {
        code => $HTTP_NOT_FOUND,
        body => { message => 'Not Found' }
    },
    '/repos/test-org-perl-missing/repo-perl-missing/contents/.bunkai.yaml' => {
        code => $HTTP_NOT_FOUND,
        body => { message => 'Not Found' }
    },
'/repos/test-org-perl-missing/repo-perl-missing/contents/.github/workflows/bunkai.yml'
      => {
        code => $HTTP_NOT_FOUND,
        body => { message => 'Not Found' }
      },
'/repos/test-org-perl-missing/repo-perl-missing/contents/.github/workflows/bunkai.yaml'
      => {
        code => $HTTP_NOT_FOUND,
        body => { message => 'Not Found' }
      },
    '/repos/test-org-perl-missing/repo-perl-missing/contents/.zarn.yml' => {
        code => $HTTP_NOT_FOUND,
        body => { message => 'Not Found' }
    },
    '/repos/test-org-perl-missing/repo-perl-missing/contents/.zarn.yaml' => {
        code => $HTTP_NOT_FOUND,
        body => { message => 'Not Found' }
    },
'/repos/test-org-perl-missing/repo-perl-missing/contents/.github/workflows/zarn.yml'
      => {
        code => $HTTP_NOT_FOUND,
        body => { message => 'Not Found' }
      },
'/repos/test-org-perl-missing/repo-perl-missing/contents/.github/workflows/zarn.yaml'
      => {
        code => $HTTP_NOT_FOUND,
        body => { message => 'Not Found' }
      },
    '/repos/test-org/repo1/contents/.github/workflows/codeql.yml' => {
        code => $HTTP_OK,
        body => { name => 'codeql.yml' },
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

sub _paged_repo_response {
    my ( $counter_ref, $first_page ) = @_;
    ${$counter_ref}++;

    if ( ${$counter_ref} == 1 ) {
        return _json_response( $HTTP_OK, $first_page );
    }

    return _json_response( $HTTP_OK, [] );
}

sub _security_repo_list_response {
    my ($path_with_query) = @_;

    if ( index( $path_with_query, '/orgs/test-org/repos?' ) == 0 ) {
        return _paged_repo_response(
            \$repo_list_page_count_security_tools,
            [
                { name => 'repo1', archived => JSON::false },
                { name => 'repo2', archived => JSON::true }
            ]
        );
    }

    if ( index( $path_with_query, '/orgs/test-org-perl/repos?' ) == 0 ) {
        return _paged_repo_response(
            \$repo_list_page_count_security_tools_perl,
            [ { name => 'repo-perl', archived => JSON::false } ]
        );
    }

    if ( index( $path_with_query, '/orgs/test-org-perl-missing/repos?' ) == 0 )
    {
        return _paged_repo_response(
            \$repo_list_page_count_security_tools_perl_missing,
            [ { name => 'repo-perl-missing', archived => JSON::false } ]
        );
    }

    return;
}

sub _security_static_response {
    my ($path_with_query) = @_;
    my $path = $path_with_query;
    $path =~ s{[?].*$}{}xms;

    if ( !exists $security_static_response_by_path{$path} ) {
        return;
    }

    my $spec = $security_static_response_by_path{$path};
    return _json_response( $spec->{code}, $spec->{body} );
}

sub _not_found_response {
    my ($url) = @_;
    my $response = HTTP::Response->new;
    $response->code($HTTP_NOT_FOUND);
    $response->message('Not Found (Mock)');
    $response->content("URL not handled by mock: $url");
    diag "Mock LWP::UserAgent received unhandled GET in SecurityTools.t: $url";
    return $response;
}

sub _mock_security_tools_get {
    my ( $self, $url_or_request ) = @_;
    my $url             = _extract_url($url_or_request);
    my $path_with_query = _api_path($url);

    my $repo_list_response = _security_repo_list_response($path_with_query);
    if ($repo_list_response) {
        return $repo_list_response;
    }

    my $static_response = _security_static_response($path_with_query);
    if ($static_response) {
        return $static_response;
    }

    return _not_found_response($url);
}

$mock_lwp_user_agent->mock( 'get', \&_mock_security_tools_get );

subtest 'SecurityTools' => sub {
    plan tests => 1;

    $repo_list_page_count_security_tools = 0;

    my %flow_message = (
        org      => 'test-org',
        token    => 'test-token',
        per_page => $PER_PAGE,
    );

    my $security_tools_output =
      Sentra::Component::SecurityTools->new( \%flow_message );

    is( $security_tools_output, q{},
        'No output when generic checks are compliant' );
};

subtest 'SecurityTools with Perl-specific checks' => sub {
    plan tests => 1;

    $repo_list_page_count_security_tools_perl = 0;

    my %flow_message = (
        org      => 'test-org-perl',
        token    => 'test-token',
        per_page => $PER_PAGE,
    );

    my $security_tools_output =
      Sentra::Component::SecurityTools->new( \%flow_message );

    is( $security_tools_output, q{},
        'No output when Perl-specific checks are compliant' );
};

subtest 'SecurityTools with missing Perl controls' => sub {
    plan tests => 3;

    $repo_list_page_count_security_tools_perl_missing = 0;

    my %flow_message = (
        org      => 'test-org-perl-missing',
        token    => 'test-token',
        per_page => $PER_PAGE,
    );

    my $security_tools_output =
      Sentra::Component::SecurityTools->new( \%flow_message );

    ok(
        index( $security_tools_output,
'No secret scanning tools detected in https://github.com/test-org-perl-missing/repo-perl-missing'
        ) >= 0,
        'Secret scanning missing is reported for Perl repository'
    );

    ok(
        index( $security_tools_output,
'Perl SCA tool check (Bunkai) in https://github.com/test-org-perl-missing/repo-perl-missing: missing'
        ) >= 0,
        'Perl SCA missing is reported'
    );

    ok(
        index( $security_tools_output,
'Perl SAST tool check (ZARN) in https://github.com/test-org-perl-missing/repo-perl-missing: missing'
        ) >= 0,
        'Perl SAST missing is reported'
    );
};

done_testing();

1;
