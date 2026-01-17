package Sentra::Component::SecurityTools {
    use strict;
    use warnings;
    use Sentra::Utils::Repositories_List;
    use Sentra::Utils::UserAgent;
    use Readonly;

    our $VERSION = '0.0.1';

    Readonly my $HTTP_OK => 200;

    sub new {
        my (undef, $message) = @_;

        my $output       = q{};
        my $user_agent   = Sentra::Utils::UserAgent -> new($message -> {token});
        my @repositories = Sentra::Utils::Repositories_List -> new($message -> {org}, $message -> {token});

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

            my $secret_summary = 'No secret scanning tools detected in https://github.com/' . $repository;
            my $sast_summary   = 'No SAST tools detected in https://github.com/' . $repository;

            if (@secret_tools_found) {
                $secret_summary = 'Secret scanning tools detected in https://github.com/' . $repository . ': ' . join(', ', @secret_tools_found);
            }

            if (@sast_tools_found) {
                $sast_summary = 'SAST tools detected in https://github.com/' . $repository . ': ' . join(', ', @sast_tools_found);
            }

            $output .= $secret_summary . "\n";
            $output .= $sast_summary . "\n";
        }

        return $output;
    }
}

1;
