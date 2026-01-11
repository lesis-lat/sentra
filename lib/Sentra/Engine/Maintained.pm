package Sentra::Engine::Maintained {
    use strict;
    use warnings;
    use JSON;
    use DateTime;
    use DateTime::Format::ISO8601;
    use Sentra::Utils::UserAgent;
    use Sentra::Utils::Repositories_List;
    use Readonly;

    our $VERSION = '0.0.1';

    Readonly my $HTTP_OK => 200;

    sub new {
        my (undef, $org, $token, $per_page) = @_;

        my $output       = q{};
        my $user_agent   = Sentra::Utils::UserAgent -> new($token);
        my @repositories = Sentra::Utils::Repositories_List -> new($org, $token);

        foreach my $repository (@repositories) {
            my $commits_response = $user_agent -> get("https://api.github.com/repos/$repository/commits");

            if ($commits_response -> code() == $HTTP_OK) {
                my $commits = decode_json($commits_response -> content());

                if (scalar(@{$commits}) > 0) {
                    my $last_commit_date_text = $commits -> [0]{commit}{committer}{date};
                    my $last_commit_date      = DateTime::Format::ISO8601 -> parse_datetime($last_commit_date_text);
                    my $ninety_days_ago       = DateTime -> now -> subtract(days => 90);

                    if ($ninety_days_ago > $last_commit_date) {
                        $output .= "The repository https://github.com/$repository has not been updated for more than 90 days.\n";
                    }
                }
            }
        }

        return $output;
    }
}

1;
