package Getopt::SubCommand;

use strict;
use warnings;
use Carp qw/carp croak/;

our $VERSION = eval '0.001';

use Getopt::Long ();
use Data::Util qw/:check anon_scalar/;
use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(qw/args_ref parser_config/);



sub new {
    my ($class, %opt) = @_;
    # Override default values with user values.
    %opt = (do_parse_args => 1, %opt);

    for (qw/commands global_opts/) {
        unless (exists $opt{$_}) {
            croak "'$_' is required option.";
        }
        unless (is_hash_ref $opt{$_}) {
            croak "'$_' is hash reference but invalid value was given.";
        }
    }

    my $self = bless {
        usage_name => $opt{usage_name},
        usage_version => $opt{usage_version},
        usage_args => $opt{usage_args},
        commands => $opt{commands},
        global_opts => $opt{global_opts},
    }, $class;
    $self->args_ref(do {
        if (is_array_ref $opt{args_ref}) {
            $opt{args_ref};
        }
        else {
            carp "'args_ref' is array reference but invalid value was given.";
            carp 'fallback: use @ARGV as args_ref instead.';
            \@ARGV;
        }
    });
    $self->parser_config([]);

    # Store parsing results.
    $self->parse_args() if $opt{do_parse_args};

    $self;
}


sub parse_args {
    my ($self, $args) = @_;
    $args = $self->args_ref unless defined $args;

    # split_args() destroys $args.
    my ($global_opts, $cmd, $cmd_opts, $cmd_args) = $self->split_args($args);

    defined $global_opts and $self->__set_global_opts($global_opts);
    defined $cmd         and $self->__set_command($cmd);
    defined $cmd_opts    and $self->__set_command_opts($cmd_opts);
    defined $cmd_args    and $self->__set_command_args($cmd_args);
}

sub split_args {
    my ($self, $args) = @_;
    my ($global_opts, $command, $command_opts, $command_args);
    goto end unless is_array_ref($args) && @$args;

    # Global options.
    my @g;
    push @g, shift @$args while $args->[0] =~ /^-/;
    $global_opts = $self->__get_options(
        \@g,    # __get_options() destroys @g.
        $self->{global_opts},
    ) or goto end;
    unless (@g == 0) {
        carp "warning: something wrong.";
    }

    # Command name.
    @$args or goto end;
    $command = shift @$args;
    exists $self->{commands}{$command}{options} or goto end;

    # Command options.
    $command_opts = $self->__get_options(
        $args,    # __get_options() destroys $args.
        $self->{commands}{$command}{options},
    ) or goto end;

    # Command args.
    $command_args = [@$args];
    @$args = ();

end:
    ($global_opts, $command, $command_opts, $command_args);
}

sub __get_options {
    my ($self, $args, $opt) = @_;

    local @ARGV = @$args;

    # Add some required options for suitable form
    # to parse sub-command arguments.
    # - gnu_compat: --opt="..." is allowed.
    # - no_bundling: single character option is not bundled.
    # - no_ignore_case: no ignore case on long option.
    my $c = $self->parser_config;
    my $p = Getopt::Long::Parser->new(config => [
        @$c, qw(gnu_compat no_bundling no_ignore_case)
    ]);
    my ($parser_args, $ref_args) = $self->__get_parser_args($opt);
    # TODO: $p->getoptions()'s return value.
    $p->getoptions(%$parser_args) or return undef;

    @$args = @ARGV;    # Destroy $args.
    $ref_args;
}

sub __get_parser_args {
    my ($self, $options) = @_;
    my %ref_args;
    my %getopt_args;    # Getopt::Long::GetOptions()'s args.
    for my $store_name (keys %$options) {
        my $info = $options->{$store_name};

        my $arg_key;
        if (is_array_ref $info->{name}) {
            $arg_key = join '|', @{$info->{name}};
        }
        else {
            $arg_key = $info->{name};
        }
        $arg_key .= $info->{attribute} || '';

        $getopt_args{$arg_key} = $ref_args{$store_name} = anon_scalar;
    }
    (\%getopt_args, \%ref_args);
}


sub get_usage {
    my ($self) = @_;

    # TODO
    my $cmdname;
    my $version;
    my $available_commands;

    return <<EOM;
$cmdname $version
usage: $cmdname [options] COMMAND ARGS

Avaiable commands are:
$available_commands

See '$cmdname help COMMAND' for more information on a specific command.
EOM
}

sub show_usage {
    my ($self, %opts) = @_;
    print $self->get_usage;
    exit if $opts{exit};
}


sub __set_command {
    my $self = shift;
    $self->{__command} = $_[0] if @_;
}

sub get_command {
    shift->{__command};
}

sub __set_command_args {
    my $self = shift;
    $self->{__command_args} = $_[0] if @_;
}

sub get_command_args {
    my $array_ref = shift->{__command_args};
    wantarray ? @$array_ref : $array_ref;
}

sub __set_command_opts {
    my $self = shift;
    $self->{__command_opts} = $_[0] if @_;
}

sub get_command_opts {
    my $self = shift;
    __deref_accessor($self, '__command_opts', @_);
}

sub __set_global_opts {
    my $self = shift;
    $self->{__global_opts} = $_[0] if @_;
}

sub get_global_opts {
    my $self = shift;
    __deref_accessor($self, '__global_opts', @_);
}

sub __deref_accessor {
    my $self = shift;
    my $ac_name = shift;
    if (@_) {
        $self->{$ac_name} = $_[0];
    }
    my $h = $self->{$ac_name};
    # Dereference anon-scalar values.
    +{map {
        $a = $h->{$_};
        ($_ => (is_scalar_ref($a) ? $$a : $a));
    } keys %$h}
}

sub invoke {
    my ($self, $opt) = @_;
    $opt ||= {};

    my $sub = __get_deep_key($self, ['commands', $self->get_command, 'sub']);
    unless (defined $sub) {
        if (exists $opt->{fallback} && is_code_ref $opt->{fallback}) {
            $sub = $opt->{fallback};
        }
        else {
            return;
        }
    }

    my @optional_args;
    if (is_array_ref $opt->{optional_args}) {
        @optional_args = @{$opt->{optional_args}};
    }

    $sub->(
        $self->get_global_opts(),
        $self->get_command_opts(),
        scalar $self->get_command_args(),    # will return array-ref
        @optional_args,
    );
}


sub __get_deep_key {
    my ($hashref, $keys) = @_;
    my $key = shift @$keys;

    return undef unless exists $hashref->{$key};
    return $hashref->{$key} unless @$keys;

    @_ = ($hashref->{$key}, $keys);
    goto &__get_deep_key;
}


1;
__END__

=head1 NAME

Getopt::SubCommand - Simple sub-command parser


=head1 VERSION

This document describes Getopt::SubCommand version 0.0.1


=head1 SYNOPSIS

    use Getopt::SubCommand;
  
  
=head1 DESCRIPTION


=head1 METHODS

=over

=item new()

create instance.

=back


=head1 DEPENDENCIES

None.


=head1 BUGS

    No known bugs.


=head1 AUTHOR

tyru  C<< <tyru.exe@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, tyru C<< <tyru.exe@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
