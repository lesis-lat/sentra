package SlackWebhook;

use strict;
use warnings;
use lib "../lib/";
use Test::More;
use Test::MockModule;
use Mojo::Transaction::HTTP;
use Mojo::Message::Response;
use Sentra::Component::SlackWebhook;
use Readonly;

our $VERSION = '0.0.1';

Readonly my $HTTP_OK => 200;

my $mock_user_agent = Test::MockModule -> new('Mojo::UserAgent');

$mock_user_agent -> mock('post', sub {
    my ($self, $url, $headers, $payload_json) = @_;

    my $transaction = Mojo::Transaction::HTTP -> new;
    $transaction -> res(Mojo::Message::Response -> new);
    $transaction -> res -> code($HTTP_OK);
    $transaction -> res -> message('OK');
    $transaction -> res -> body('ok');

    return $transaction;
});

subtest 'SlackWebhook' => sub {
    plan tests => 1;

    my %slack_message = (
        message => 'Test message',
        webhook => 'https://hooks.slack.com/services/xxx/yyy/zzz'
    );

    my $result_message = Sentra::Component::SlackWebhook -> new(\%slack_message);

    like($result_message, qr/Message\ sent\ successfully! \s \[ok\]/xms, 'Webhook message sent successfully');
};

done_testing();

1;
