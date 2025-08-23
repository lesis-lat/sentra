package Sentra::Engine::DependabotMetrics {
    use strict;
    use warnings;
    use JSON;
    use Sentra::Utils::UserAgent;
    use Sentra::Utils::Repositories_List;
    use Readonly;
    
    our $VERSION = '0.0.2';

    Readonly my $HTTP_OK => 200;

    sub new {
        my ($class, $org, $token, $per_page) = @_;
        
        my $userAgent = Sentra::Utils::UserAgent -> new($token);
        my @repositories_list = Sentra::Utils::Repositories_List -> new($org, $token);
        
        my $output         = q{};
        my $total_alerts   = 0;
        my %severity_count = (
            low      => 0, 
            medium   => 0, 
            high     => 0, 
            critical => 0
        );

        foreach my $repository (@repositories_list) {
            my $alert_page = 1;
            my $alert_url  = "https://api.github.com/repos/$repository/dependabot/alerts?state=open&per_page=$per_page&page=$alert_page";
            my $request    = $userAgent -> get($alert_url);
                
            if ($request -> code() == $HTTP_OK) {
                my $alert_data = decode_json($request -> content());
                
                if (scalar(@{$alert_data}) == 0) {
                    last;
                }

                $total_alerts += scalar(@{$alert_data});
                
                foreach my $alert (@{$alert_data}) {
                    my $severity = $alert->{security_vulnerability}{severity} || 'unknown';
                    
                    if (exists $severity_count{$severity}) {
                        $severity_count{$severity}++;
                    }
                }
            }
        }
        
        foreach my $sev (keys %severity_count) {
            $output .= "Severity $sev: $severity_count{$sev}\n";
        }
        
        $output .= "Total DependaBot Alerts: $total_alerts\n";

        return $output;
    }
}

1;