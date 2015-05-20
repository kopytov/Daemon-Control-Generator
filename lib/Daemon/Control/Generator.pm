# ABSTRACT: generates init files for Daemon::Control
package Daemon::Control::Generator;
use Moose;
use autodie;

use Carp;
use File::Basename;

require Data::Dumper;

with 'MooseX::Getopt';

has program => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has progname => (
    is      => 'ro',
    isa     => 'Str',
    builder => 'build_progname',
    lazy    => 1,
);

has init_code => (
    is      => 'ro',
    isa     => 'Str',
    default => q{},
);

has lsb_start => (
    is      => 'ro',
    isa     => 'Str',
    default => '$syslog $remote_fs',
);

has lsb_stop => (
    is      => 'ro',
    isa     => 'Str',
    default => '$syslog',
);

has lsb_sdesc => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Generated by dc-gen',
);

has lsb_desc => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Generated by dc-gen',
);

has path => (
    is      => 'ro',
    isa     => 'Str',
    builder => 'build_path',
    lazy    => 1,
);

has user => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { scalar getpwuid $> },
);

has group => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { scalar getgrgid( ( getpwnam shift->user )[3] ) },
);

has directory => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { ( getpwnam shift->user )[7] },
);

has pid_file => (
    is      => 'ro',
    isa     => 'Str',
    builder => 'build_pid_file',
    lazy    => 1,
);

has stderr_file => (
    is      => 'ro',
    isa     => 'Str',
    builder => 'build_stderr_file',
    lazy    => 1,
);

has stdout_file => (
    is      => 'ro',
    isa     => 'Str',
    builder => 'build_stdout_file',
    lazy    => 1,
);

has kill_timeout => (
    is      => 'ro',
    isa     => 'Int',
    default => 15,
);

has save => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

sub build_progname { basename( shift->program ) }

sub build_path {
    my $self      = shift;
    my $sysprefix = '/etc/opt';
    my $sysdir    = "$sysprefix/dc-gen";
    my $path      = "$sysdir/" . $self->progname;
    mkdir $sysprefix if !-d $sysprefix;
    mkdir $sysdir    if !-d $sysdir;
    return $path;
}

sub build_pid_file {
    return "/var/run/@{[ shift->progname ]}.pid";
}

sub build_stderr_file {
    return "/var/log/@{[ shift->progname ]}.log";
}

sub build_stdout_file {
    return "/var/log/@{[ shift->progname ]}.log";
}

sub dd ($) {
    my $dumper = Data::Dumper->new( [shift] );
    $dumper->Indent(0);
    $dumper->Terse(1);
    return $dumper->Dump;
}

sub mq ($) {
    my $string = shift;
    $string =~ s{'}{\\'}gxms;
    return $string;
}

sub script {
    my $self       = shift;
    my $script_fmt = <<'END_SCRIPT';
#!/usr/bin/env perl
use strict;
require Daemon::Control;
my $dc = Daemon::Control->new(
    name         => '%s',
    lsb_start    => '%s',
    lsb_stop     => '%s',
    lsb_sdesc    => '%s',
    lsb_desc     => '%s',
    path         => '%s',
    program      => '%s',
    user         => '%s',
    group        => '%s',
    directory    => '%s',
    pid_file     => '%s',
    stderr_file  => '%s',
    stdout_file  => '%s',
    init_code    => '%s',
    program_args => %s,
    kill_timeout => %d,
);
exit $dc->run;
END_SCRIPT
    return sprintf $script_fmt, mq $self->progname, mq $self->lsb_start,
      mq $self->lsb_stop, mq $self->lsb_sdesc, mq $self->lsb_desc,
      mq $self->path, mq $self->program, mq $self->user, mq $self->group,
      mq $self->directory,   mq $self->pid_file,  mq $self->stderr_file,
      mq $self->stdout_file, mq $self->init_code, dd $self->extra_argv,
      $self->kill_timeout;
}

sub save_script {
    my $self = shift;
    open my $fh, '>', $self->path;
    print {$fh} $self->script;
    close $fh;
    chmod 0755, $self->path;
    print 'Saved to ' . $self->path . qq{\n};
}

1;