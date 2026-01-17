package Sentra::Component::SearchFiles {
    use strict;
    use warnings;
    use Sentra::Utils::UserAgent;
    use Sentra::Utils::Repositories_List;
    use Readonly;

    our $VERSION = '0.0.1';

    Readonly my $HTTP_NOT_FOUND => 404;

    sub new {
        my (undef, $message) = @_;

        my $output       = q{};
        my $user_agent   = Sentra::Utils::UserAgent -> new($message -> {token});
        my @repositories = Sentra::Utils::Repositories_List -> new($message -> {org}, $message -> {token});
        my @files        = qw(.github/dependabot.yml);

        foreach my $repository (@repositories) {
            foreach my $file (@files) {
                my $dependabot_url = "https://api.github.com/repos/$repository/contents/$file";
                my $response       = $user_agent -> get($dependabot_url);

                if ($response -> code == $HTTP_NOT_FOUND) {
                    $output .= "The $file file was not found in this repository: https://github.com/$repository\n";
                }
            }
        }

        return $output;
    }
}

1;
