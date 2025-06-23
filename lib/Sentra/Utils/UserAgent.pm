package Sentra::Utils::UserAgent {
    use strict;
    use warnings;
    use LWP::UserAgent;

    our $VERSION = '0.0.1';

    sub new {
        my ($self, $token) = @_;

        my $userAgent = LWP::UserAgent -> new(
            timeout  => 5,
            ssl_opts => { 
                verify_hostname => 0,
                SSL_verify_mode => 0
            },
            agent => "Sentra 0.0.3"
        );
        
        $userAgent -> default_headers -> header (
            'X-GitHub-Api-Version' => '2022-11-28',
            'Accept'               => 'application/vnd.github+json',
            'Authorization'        => "Bearer $token"
        );

        return $userAgent;
    }
}

1;