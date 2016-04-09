#!/opt/perl

use Mojolicious::Lite;

app->log->level("debug");

plugin qw(AtStartup);

app->run_code(sub {
    shift->log->info("AtStartup: $$: " . scalar(localtime));
});

app->run_code(sub {
    Mojo::IOLoop->timer(5 => sub{app->log->warn("starting: $$")});
});

get '/' => sub {
    my $c = shift;

    $c->render(text => "Hello: $$: " . scalar(localtime));
};

app->start;

