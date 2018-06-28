package Mojolicious::Plugin::Cron;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.01';

use Mojo::Cron;
use Scalar::Util 'weaken';

sub register {
  my ($self, $app, $conf) = @_;

  push @{$app->commands->namespaces}, 'Mojo::Cron::Command';

  my $cron = Mojo::Cron->new(each %$conf);
  weaken $cron->app($app)->{app};
  $app->helper(cron => sub {$cron});

  $app->log->warn("Not development mode; remember to install your cron commands in your system's cron") and return
    unless $app->mode eq 'development';

  $app->hook(before_server_start => sub { $cron->server(shift)->start });
}

1;
__END__

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Cron - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Cron');

  # Mojolicious::Lite
  plugin 'Cron';

=head1 DESCRIPTION

L<Mojolicious::Plugin::Cron> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::Cron> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.

=cut
