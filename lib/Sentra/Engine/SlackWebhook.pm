package Sentra::Engine::SlackWebhook {
    use strict;
    use warnings;
    use Mojo::UserAgent;
    use JSON;

    our $VERSION = '0.0.1';

    sub new {
        my ($class, $message, $webhook) = @_;

        my $userAgent = Mojo::UserAgent -> new();
        my $payload   = encode_json({ text => $message });

        my $text = $userAgent -> post($webhook => {
            'Content-Type' => 'application/json'
        } => $payload);

        my $res = $text -> result;
        
        if (!$res) {
            my $err = $text -> error;
            return "Failed to send message: [" . ($err->{message} || "Unknown error") . "]\n";
        }
       
        if (!$res -> is_success) {
            return "Failed to send message: [" . $res->message . "]\n";
        }
       
        return "Message sent successfully! [" . $res->body . "]\n";
    }
}

1;