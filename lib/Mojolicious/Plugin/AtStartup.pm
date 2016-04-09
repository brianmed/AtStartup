package Mojolicious::Plugin::AtStartup;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.02';

use constant DEBUG => $ENV{MOJOLICIOUS_PLUGIN_ATSTARTUP_DEBUG} || 0;

has qw(state) => sub { Mojolicious::Plugin::AtStartup::State->new };
has qw(callback) => sub { Mojolicious::Plugin::AtStartup::Callback->new };
has qw(app);
has qw(runnable) => sub { 0 };

sub register {
  my ($startup, $app) = @_;

  my $daemon = $ARGV[0] && $ARGV[0] =~ m/^(daemon|prefork)$/;
  my $hypnotoad = $ENV{HYPNOTOAD_REV} && 2 <= $ENV{HYPNOTOAD_REV} && !$ENV{HYPNOTOAD_STOP};

  # Morbo?
  if ($daemon || $hypnotoad) {
      $startup->runnable(1);

      unlink($startup->state->file);
  }

  $startup->app($app);

  $app->helper(run_code => sub {
    return unless $startup->runnable;

    Mojo::IOLoop->next_tick(
      $startup->callback->add($app, pop)
    );
  });
}

package Mojolicious::Plugin::AtStartup::State;
use Mojo::Base -base;

use Fcntl qw(O_RDWR O_CREAT O_EXCL LOCK_EX SEEK_SET LOCK_UN :flock);
use File::Spec::Functions qw(catfile tmpdir);
use Mojo::Util qw(slurp spurt steady_time);
use Mojo::JSON qw(encode_json decode_json);

has file => sub { catfile tmpdir, 'atstartup.state_file' };

use constant DEBUG => Mojolicious::Plugin::AtStartup::DEBUG;

sub _lock {
    my $fh = pop;
    flock($fh, LOCK_EX) or die "Cannot lock ? - $!\n";

    # and, in case someone appended while we were waiting...
    seek($fh, 0, SEEK_SET) or die "Cannot seek - $!\n";
}

sub _unlock {
    my $fh = pop;
    flock($fh, LOCK_UN) or die "Cannot unlock ? - $!\n";
}

sub data {
  my $state = shift;
  my $hash = shift;

  # Should be created by sysopen
  my $fh;
  if (-f $state->file) {
    open($fh, ">>", $state->file)
      or die(sprintf("Can't open %s", $state->file));

    $state->_lock($fh);
  }

  if ($hash) {
    spurt(encode_json($hash), $state->file);

    $state->_unlock($fh);

    return $hash;
  }
  elsif (-f $state->file) {
    my $ret = decode_json(slurp($state->file));

    $state->_unlock($fh);

    return $ret;
  }
}

package Mojolicious::Plugin::AtStartup::Callback;
use Mojo::Base -base;

use Fcntl qw(O_RDWR O_CREAT O_EXCL LOCK_EX SEEK_SET LOCK_UN :flock);
use Mojo::Util qw(steady_time);

has qw(state) => sub { Mojolicious::Plugin::AtStartup::State->new };
has qw(code) => sub { {} };

use constant DEBUG => Mojolicious::Plugin::AtStartup::DEBUG;

sub in_runner {
    my $state = shift->state;

    my $pid = $state->data->{worker_pid};

    return 0 if !defined $pid;
    return $pid == $$;
}

sub add {
  my $callback = shift;
  my $app = shift;
  my $code = shift;

  my $which_one = steady_time;
  $callback->code->{$which_one} = $code;

  return sub {
    my $code = $callback->code->{$which_one};

    my $file = $callback->state->file;

    eval {
      sysopen(my $fh, $file, O_RDWR|O_CREAT|O_EXCL) or die ("$file: $$: $!\n");
      $callback->state->data({ worker_pid => $$, manager_pid => $ARGV[0] && $ARGV[0] =~ m/daemon/ ? $$ : getppid });
      close($fh);

      $app->log->info("$$: Callback runner next_tick") if DEBUG;
    };
    
    # Outside
    if ($@ && !$callback->in_runner) {
      chomp(my $err = $@);
    
      $app->log->info("$$: sysopen($file): $err");
    
      return sub { };
    }
    
    return if !$callback->in_runner;
    
    # Inside
    $app->log->info("$file: sysopen($$) <-- callback runnning");

    $code->($app);
  };
}

1;

__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::AtStartup - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('AtStartup');

  # Mojolicious::Lite
  plugin 'AtStartup';

=head1 DESCRIPTION

L<Mojolicious::Plugin::AtStartup> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::AtStartup> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
