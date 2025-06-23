package SlackWebhook;

use strict;
use warnings;
use lib "../lib/";
use Test::More;
use Test::MockModule;
use Mojo::Transaction::HTTP;
use Mojo::Message::Response;
use Sentra::Engine::SlackWebhook;
use Readonly;

our $VERSION = '0.0.1';

Readonly my $HTTP_OK => 200;

my $mock_ua = Test::MockModule->new('Mojo::UserAgent');

$mock_ua->mock('post', sub {
    my ($self, $url, $headers, $payload_json) = @_;
    
    my $tx = Mojo::Transaction::HTTP->new;
    $tx->res(Mojo::Message::Response->new); 
    $tx->res->code($HTTP_OK);
    $tx->res->message('OK');
    $tx->res->body('ok'); 
    
    return $tx; 
});

subtest 'SlackWebhook' => sub {
    plan tests => 1;
    
    my $result_message = Sentra::Engine::SlackWebhook->new('Test message', 'https://hooks.slack.com/services/xxx/yyy/zzz');
    
    like($result_message, qr/Message\ sent\ successfully! \s \[ok\]/xms, 'Webhook message sent successfully');
};

done_testing();

1;