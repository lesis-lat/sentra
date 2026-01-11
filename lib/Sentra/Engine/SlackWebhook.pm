package Sentra::Engine::SlackWebhook {
    use strict;
    use warnings;
    use Mojo::UserAgent;
    use JSON;

    our $VERSION = '0.0.1';

    sub new {
        my (undef, $message, $webhook) = @_;

        my $user_agent = Mojo::UserAgent -> new();
        my $payload    = encode_json({ text => $message });

        my $transaction = $user_agent -> post($webhook => {
            'Content-Type' => 'application/json'
        } => $payload);

        my $response = $transaction -> result;

        if (!$response) {
            my $error = $transaction -> error;
            return "Failed to send message: [" . ($error -> {message} || "Unknown error") . "]\n";
        }

        if (!$response -> is_success) {
            return "Failed to send message: [" . $response -> message . "]\n";
        }

        return "Message sent successfully! [" . $response -> body . "]\n";
    }
}

1;
