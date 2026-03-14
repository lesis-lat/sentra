package Sentra::Utils::Repositories_List {
    use strict;
    use warnings;
    use JSON;
    use Sentra::Utils::UserAgent;
    use Readonly;

    our $VERSION = '0.0.1';

    Readonly my $HTTP_OK => 200;

    sub new {
        my (undef, $org, $token, $repo) = @_;

        if (defined $repo && $repo ne q{}) {
            if ($repo =~ m{/}xms) {
                return ($repo);
            }

            return ($org . '/' . $repo);
        }

        my @repositories;
        my $page = 1;
        my $user_agent = Sentra::Utils::UserAgent -> new($token);

        while (1) {
            my $url = "https://api.github.com/orgs/$org/repos?per_page=100" . "&page=$page";
            my $response = $user_agent -> get($url);

            if ($response -> code() != $HTTP_OK) {
                my $status = $response -> status_line() || 'Unknown error';

                die "Failed to fetch repositories for org '$org' (page $page): $status\n";
            }

            my $data = decode_json($response -> content());

            if (scalar(@{$data}) == 0) {
                last;
            }

            foreach my $repository (@{$data}) {
                if (!$repository -> {archived}) {
                    push @repositories, $org . '/' . $repository -> {name};
                }
            }

            $page++;
        }

        return @repositories;
    }
}

1;
