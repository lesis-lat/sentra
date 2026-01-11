package Sentra::Utils::UserAgent {
    use strict;
    use warnings;
    use LWP::UserAgent;

    our $VERSION = '0.0.1';

    sub new {
        my (undef, $token) = @_;

        my $user_agent = LWP::UserAgent -> new(
            timeout  => 5,
            ssl_opts => {
                verify_hostname => 0,
                SSL_verify_mode => 0
            },
            agent => "Sentra 0.0.3"
        );

        $user_agent -> default_headers -> header (
            'X-GitHub-Api-Version' => '2022-11-28',
            'Accept'               => 'application/vnd.github+json',
            'Authorization'        => "Bearer $token"
        );

        return $user_agent;
    }
}

1;
