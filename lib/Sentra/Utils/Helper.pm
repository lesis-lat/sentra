package Sentra::Utils::Helper {
    use strict;
    use warnings;

    our $VERSION = '0.0.3';

    sub new {
        my ($class) = @_;

        return join("\n",
            "Sentra v$VERSION",
            "Core Commands",
            "==============",
            "        Command                         Description",
            "        -------                         -----------",
            "        -o, --org                       Specify the name of the organization",
            "        -r, --repo                      Scan only one repository (use with --org)",
            "        -t, --token                     Set the GitHub Token to use during actions",
            "        -mt, --maintained               Get alerts about repositories with a last commit date greater than 90 days old",
            "        -d, --dependency                Check if repositories has dependabot.yaml file",
            "        -M, --metrics                   Show all security alert metrics (dependabot, secret, code)",
            "        --metrics-dependabot            Show only Dependabot alert metrics",
            "        --metrics-secret                Show only Secret Scanning alert metrics",
            "        --metrics-code                  Show only Code Scanning alert metrics",
            "        --static-analysis               Check repositories for security tools (SAST, secret scanning, SCA)",
            "        -w, --webhook                   Set the webhook address for Slack",
            "        -m, --message                   Message to send via Slack webhook"
        );
    }
}

1;
