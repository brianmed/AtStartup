package Mojolicious::Plugin::AtStartup;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.01';

sub register {
  my ($once, $app, $code) = @_;

  my $daemon = $ARGV[0] && $ARGV[0] =~ m/^(daemon|prefork)$/;
  my $hypnotoad = $ENV{HYPNOTOAD_REV} && 2 <= $ENV{HYPNOTOAD_REV} && !$ENV{HYPNOTOAD_STOP};

  # Morbo?
  if ($daemon || $hypnotoad) {
      if ("ARRAY" eq $code) {
          $_->($once, $app) for @{$code};
      }
      else {
          $code->($once, $app);
      }
  }
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
