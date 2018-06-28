package Mojo::Cron::Job;
use Mojo::Base -base;

use Carp 'croak';

use Mojo::Server;

use Time::Crontab;

has app => sub { Mojo::Server->new->build_app('Mojo::HelloWorld') };
has server => sub { Mojo::Server->new };
has crontab => sub { die };
has cron => sub { die };
has time => sub { time };
has name => sub { ref shift };
has [qw/server job/];

sub run { croak "method 'run' not implemented by class"; }

sub start {
  my ($self) = @_;
  my $crontab = Time::Crontab->new($self->crontab);
  return unless $crontab->match($self->time);
  my $job = $self->cron->ioloop->subprocess->run(
    sub {
      $self->app->log->debug($0 = $self->name);
      my $run = $self->run(shift);
      $self->app->log->debug($run);
      return 1;
    },
    sub {
      my ($subprocess, $err, @results) = @_;
      my $pid = $subprocess->pid;
      $self->app->log->error(sprintf 'Cron Job %s %s exited: %s', $self->name, $pid, $err) and return if $err;
      $self->app->log->info(sprintf "Cron Job %s %s exited: @results", $self->name, $pid);
    }
  );
  $self->server->on(finish => sub {
    my ($server, $graceful) = @_;
    $self->app->log->info(sprintf "Ended cron job subprocess %s %s %s", $job->pid, ref $server, $graceful||0);
    #$job->ioloop->stop if $job->ioloop->is_running;
  });
  $self->app->log->info(sprintf 'Started Cron Job %s on %s', $self->name, $job->pid);
  return $self->job($job);
}

1;
