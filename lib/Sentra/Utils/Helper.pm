package Sentra::Utils::Helper {
    use strict;
    use warnings;

    our $VERSION = '0.0.1';

    sub new {
        return join("\n",
            "Sentra v0.0.1",
            "Core Commands",
            "    ==============",
            "        Command                         Description",
            "        -------                         -----------",
            "        -o, --org                       Specify the name of the organization",
            "        -t, --token                     Set the GitHub Token to use during actions",
            "        -mt, --maintained               Get alerts about repositories with a last commit date greater than 90 days old",
            "        -d, --dependency                Check if repositories has dependabot.yaml file",
            "        -M, --metrics                   See some metrics based on GHAS",
            "        -ss, --secret-scanning          Check repositories for secret scanning tools",
            "        --sast                          Check repositories for SAST tools",
            "        -w, --webhook                   Set the webhook address for Slack",
            "        -m, --message                   Message to send via Slack webhook"
        );
    }
}

1;
