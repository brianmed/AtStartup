#!/opt/perl

use Mojolicious::Lite;

app->log->level("debug");

plugin(AtStartup => sub {
    pop->log->info("AtStartup: $$: " . scalar(localtime));
});

get '/' => sub {
    my $c = shift;

    $c->render(text => "Hello: $$: " . scalar(localtime));
};

app->start;

