package Mojo::Cron::Command::cron;
use Mojo::Base 'Mojolicious::Command';

has description => 'Mojolicious Cron processor';
has usage => sub { shift->extract_usage };

use Mojo::IOLoop;

sub run {
  my $self = shift;
  $self->app->cron->start;
  Mojo::IOLoop->start unless Mojo::IOLoop->is_running;  
}

1;
