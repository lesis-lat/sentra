package Sentra::Utils::Repositories_List {
    our $VERSION = '0.0.1';
    use strict;
    use warnings;
    use JSON;
    use Sentra::Utils::UserAgent;
    use Readonly;
    Readonly my $HTTP_OK => 200;

    sub new {
        my ($self, $org, $token) = @_;

        my @repos;
        my $page = 1;
        my $userAgent = Sentra::Utils::UserAgent -> new($token);

        while (1) {
            my $url      = "https://api.github.com/orgs/$org/repos?per_page=100&page=$page";
            my $response = $userAgent -> get($url);

            if ($response -> code() == $HTTP_OK) {
                my $data  = decode_json($response -> content());
                
                last if scalar(@{$data}) == 0;

                foreach my $repo (@{$data}) {
                    if (!$repo->{archived}) {
                        push @repos, "$org/$repo->{name}";
                    }
                }

                $page++;
            }
        }

        return @repos;
    }
}

1;