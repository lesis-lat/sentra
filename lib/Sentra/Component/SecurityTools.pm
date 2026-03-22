package Sentra::Component::SecurityTools {
    use strict;
    use warnings;
    use JSON;
    use Sentra::Utils::Repositories_List;
    use Sentra::Utils::UserAgent;
    use Readonly;

    our $VERSION = '0.0.1';

    Readonly my $HTTP_OK => 200;

    sub new {
        my (undef, $message) = @_;

        my $output       = q{};
        my $user_agent   = Sentra::Utils::UserAgent -> new($message -> {token});
        my @repositories = Sentra::Utils::Repositories_List -> new(
            $message -> {org},
            $message -> {token},
            $message -> {repo}
        );

        my %secret_scanning_tools = (
            'Detect Secrets' => [
                '.secrets.baseline',
                '.github/workflows/detect-secrets.yml',
                '.github/workflows/detect-secrets.yaml'
            ],
            'Gitleaks' => [
                '.gitleaks.toml',
                '.gitleaks.yml',
                '.gitleaks.yaml',
                '.gitleaks.json'
            ],
            'TruffleHog' => [
                '.trufflehog.yml',
                '.trufflehog.yaml',
                '.github/workflows/trufflehog.yml',
                '.github/workflows/trufflehog.yaml'
            ]
        );

        my %sast_tools = (
            'CodeQL' => [
                '.github/workflows/codeql.yml',
                '.github/workflows/codeql.yaml',
                '.github/codeql/codeql-config.yml',
                '.github/codeql/codeql-config.yaml'
            ],
            'Semgrep' => [
                '.semgrep.yml',
                '.semgrep.yaml',
                '.semgrep/semgrep.yml',
                '.semgrep/semgrep.yaml',
                '.github/workflows/semgrep.yml',
                '.github/workflows/semgrep.yaml'
            ],
            'SonarQube' => [
                'sonar-project.properties',
                '.github/workflows/sonarqube.yml',
                '.github/workflows/sonarqube.yaml'
            ]
        );

        foreach my $repository (@repositories) {
            my $languages = _fetch_languages($user_agent, $repository);
            my $repository_url = 'https://github.com/' . $repository;
            my @secret_tools_found;
            my @sast_tools_found;

            for my $tool (sort keys %secret_scanning_tools) {
                for my $file (@{$secret_scanning_tools{$tool}}) {
                    my $tool_url = "https://api.github.com/repos/$repository/contents/$file";
                    my $response = $user_agent -> get($tool_url);

                    if ($response -> code() == $HTTP_OK) {
                        push @secret_tools_found, $tool;
                        last;
                    }
                }
            }

            for my $tool (sort keys %sast_tools) {
                for my $file (@{$sast_tools{$tool}}) {
                    my $tool_url = "https://api.github.com/repos/$repository/contents/$file";
                    my $response = $user_agent -> get($tool_url);

                    if ($response -> code() == $HTTP_OK) {
                        push @sast_tools_found, $tool;
                        last;
                    }
                }
            }

            if (!@secret_tools_found) {
                $output .= 'No secret scanning tools detected in '
                    . $repository_url . "\n";
            }

            if ($languages && exists $languages -> {Perl}) {
                my ($bunkai_found) = _find_first_matching_file(
                    $user_agent,
                    $repository,
                    [
                        qw(
                            .github/workflows/bunkai.yml
                            .github/workflows/bunkai.yaml
                        )
                    ]
                );
                my ($zarn_found) = _find_first_matching_file(
                    $user_agent,
                    $repository,
                    [
                        qw(
                            .zarn.yml
                            .zarn.yaml
                            .github/workflows/zarn.yml
                            .github/workflows/zarn.yaml
                        )
                    ]
                );

                if (!$bunkai_found) {
                    $output .= "Perl SCA tool check (Bunkai) in $repository_url: missing\n";
                }

                if (!$zarn_found) {
                    $output .= "Perl SAST tool check (ZARN) in $repository_url: missing\n";
                }
                next;
            }

            if (!@sast_tools_found) {
                $output .= 'No SAST tools detected in '
                    . $repository_url . "\n";
            }
        }

        return $output;
    }

    sub _fetch_languages {
        my ($user_agent, $repository) = @_;
        my $languages_url = "https://api.github.com/repos/$repository/languages";
        my $languages_response = $user_agent -> get($languages_url);

        if ($languages_response -> code() != $HTTP_OK) {
            return undef;
        }

        return decode_json($languages_response -> content());
    }

    sub _find_first_matching_file {
        my ($user_agent, $repository, $files) = @_;

        foreach my $file (@{$files}) {
            my $tool_url = "https://api.github.com/repos/$repository/contents/$file";
            my $response = $user_agent -> get($tool_url);

            if ($response -> code() == $HTTP_OK) {
                return (1, $file);
            }
        }

        return (0, q{});
    }
}

1;
