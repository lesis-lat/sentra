package Sentra::Engine::SearchFiles {
    use strict;
    use warnings;
    use JSON;
    use Sentra::Utils::UserAgent;
    use Sentra::Utils::Repositories_List;
    use Readonly;

    our $VERSION = '0.0.1';
    
    Readonly my $HTTP_NOT_FOUND => 404;

    sub new {
        my ($class, $org, $token, $per_page) = @_;
        
        my $output            = q{};
        my $userAgent         = Sentra::Utils::UserAgent -> new($token);
        my @repositories_list = Sentra::Utils::Repositories_List -> new($org, $token);
        my @files             = qw(.github/dependabot.yml);

        foreach my $repository (@repositories_list) {
            foreach my $file (@files) {
                my $dependabot_url = "https://api.github.com/repos/$repository/contents/$file";
                my $request        = $userAgent -> get($dependabot_url);
                
                if ($request -> code == $HTTP_NOT_FOUND) {
                    $output .= "The $file file was not found in this repository: https://github.com/$repository\n";
                }  
            }
        }

        return $output;
    }
}

1;