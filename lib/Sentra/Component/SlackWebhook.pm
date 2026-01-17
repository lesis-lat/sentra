package Sentra::Component::SlackWebhook {
    use strict;
    use warnings;
    use Mojo::UserAgent;
    use JSON;

    our $VERSION = '0.0.1';

    sub new {
        my (undef, $message) = @_;

        my $user_agent = Mojo::UserAgent -> new();
        my $payload    = encode_json({ text => $message -> {message} });

        my $transaction = $user_agent -> post($message -> {webhook} => {
            'Content-Type' => 'application/json'
        } => $payload);

        my $response = $transaction -> result;

        if (!$response) {
            my $error = $transaction -> error;
            my $error_message = 'Unknown error';

            if ($error -> {message}) {
                $error_message = $error -> {message};
            }

            return "Failed to send message: [" . $error_message . "]\n";
        }

        if (!$response -> is_success) {
            return "Failed to send message: [" . $response -> message . "]\n";
        }

        return "Message sent successfully! [" . $response -> body . "]\n";
    }
}

1;
