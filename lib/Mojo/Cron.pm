package Mojo::Cron;
use Mojo::Base -base;

use Mojo::IOLoop;
use Mojo::Server;
use Mojo::Loader qw(find_modules load_class);
use Mojo::Util 'camelize';

use Time::Piece;

has app => sub { Mojo::Server->new->build_app('Mojo::HelloWorld') };
has server => sub { Mojo::Server->new };
has name => 'cron';
has namespaces => sub { [camelize(shift->app->moniker).'::Cron'] };

sub start {
  my ($self) = @_;
  my $cron = Mojo::IOLoop->subprocess->run(
    sub {
      my $cron = shift;
      $self->_set_process_name($self->name);
      sleep 59 - localtime->sec;
      $cron->ioloop->timer(1 => sub { $self->_start($cron) });
      sleep 1;
      $cron->ioloop->recurring(60 => sub { $self->_start($cron) });
      $self->server->on(finish => sub {
        my ($server, $graceful) = @_;
        $self->app->log->info(sprintf "Ended cron subprocess %s %s %s", $$, ref $server, $graceful||0);
        $cron->ioloop->stop if $cron->ioloop->is_running;
      });
      $cron->ioloop->start unless $cron->ioloop->is_running;
    },
    sub {
      $self->app->log->error("I've never seen this");
    }
  );
  $self->app->log->info(sprintf 'Started cron subprocess %s', $cron->pid);
}

sub _set_process_name { $0 = pop }

sub _start {
  my ($self, $cron) = @_;
  my $time = time;
  my @namespaces = map { find_modules $_ } grep { $_ } @{$self->namespaces};
  $self->app->log->warn("No cron jobs found") unless @namespaces;
  for my $module ( @namespaces ) {
    my $e = load_class $module;
    $self->app->log->warn(sprintf 'Loading "%s" failed: %s', $module, $e) and next if ref $e;

    my $job = $module->new(app => $self->app, cron => $cron, server => $self->server, time => $time);
    $job->start;
  }
}

1;
