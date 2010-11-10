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
    %opt = (
        do_parse_args => 1,
        auto_help => 1,
        %opt,
    );
    $class->__validate_required_new_opts(\%opt);

    my $self = bless {
        usage_name => $opt{usage_name},
        usage_version => $opt{usage_version},
        usage_args => $opt{usage_args},
        commands => $opt{commands},
        global_opts => $opt{global_opts},
    }, $class;
    $self->args_ref(do {
        if (not defined $opt{args_ref}) {
            [];
        }
        elsif (is_array_ref $opt{args_ref}) {
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

    if ($opt{auto_help}) {
        $self->{commands}{help} = {
            sub => sub { shift->show_usage },
            usage => 'Show help text.',
        };
    }

    $self;
}

sub __validate_required_new_opts {
    my ($self, $opt) = @_;
    unless (exists $opt->{commands}) {
        croak "'commands' is required option.";
    }
    unless (is_hash_ref $opt->{commands}) {
        croak "'commands' is hash reference but invalid value was given.";
    }
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
    $args = $self->args_ref unless defined $args;
    goto end unless is_array_ref($args) && @$args;

    # Global options.
    my @g;
    push @g, shift @$args while $args->[0] =~ /^-/;
    $global_opts = $self->__get_options(
        \@g,    # __get_options() destroys @g.
        $self->{global_opts},
    ) or goto end;
    unless (@g == 0) {
        carp "warning: something technically wrong.";    # FIXME :p
    }
    $self->__validate_required_global_opts($global_opts);

    # Command name.
    @$args or goto end;
    $command = shift @$args;
    defined __get_deep_key($self, ['commands', $command, 'options']) or goto end;

    # Command options.
    $command_opts = $self->__get_options(
        $args,    # __get_options() destroys $args.
        $self->{commands}{$command}{options},
    ) or goto end;
    $self->__validate_required_command_opts($command, $command_opts);

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
    $p->getoptions(%$parser_args) or return undef;

    @$args = @ARGV;    # Destroy $args.

    # Eliminates options which were not given.
    +{
        map { $_ => $ref_args->{$_} }
        grep { defined ${$ref_args->{$_}} }
        keys %$ref_args
    };
}

sub __validate_required_global_opts {
    my ($self, $got_opts) = @_;
    my $h = __get_deep_key($self, ['global_opts']) || return;
    $self->__validate_required_opts($h, $got_opts);
}

sub __validate_required_command_opts {
    my ($self, $command, $got_opts) = @_;
    my $h = __get_deep_key($self, ['commands', $command, 'options']) || return;
    $self->__validate_required_opts($h, $got_opts);
}

sub __validate_required_opts {
    my (undef, $h, $got_opts) = @_;

    for my $optname (keys %$h) {
        my $required = __get_deep_key($h, [$optname, 'required']);
        if ($required && ! exists $got_opts->{$optname}) {
            $optname = length $optname == 1 ? "-$optname" : "--$optname";
            croak "required option '$optname' is missing.";
        }
    }
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

    my $cmdname = defined $self->{usage_name} ? $self->{usage_name} : '[No name]';
    my $version = defined $self->{usage_version} ? $self->{usage_version} : '';
    my $available_commands = join "\n", map { "  $_" } keys %{$self->{commands}};

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


# Accessing to value without creating empty hashrefs.
sub __get_deep_key {
    my ($hashref, $keys) = @_;
    my $key = shift @$keys;

    return undef unless defined $key;
    return undef unless exists $hashref->{$key};
    return $hashref->{$key} unless @$keys;

    @_ = ($hashref->{$key}, $keys);
    goto &__get_deep_key;
}


1;
__END__

=head1 NAME

Getopt::SubCommand - Simple sub-command parser


=head1 SYNOPSIS

    use Getopt::SubCommand;
    my $parser = Getopt::SubCommand->new(
        # args_ref => \@ARGV,    # default to \@ARGV
        args_ref => [qw(
            --global --hello=world
            foo
            -a --command),
            q(-b=this is b), q(-c), q(this is c),
        ],
        global_opts => {
            global => {
                name => [qw/g global/],
            },
            opt_hello => {
                name => 'hello',
                attribute => '=s',
            },
        },
        commands => {
            foo => {
                # sub => sub { print "foo" },    # optional
                options => {
                    opt_a => {
                        name => 'a',
                    },
                    opt_command => {
                        name => 'command',
                    },
                    opt_b => {
                        name => 'b',
                        attribute => '=s',
                    },
                    opt_c => {
                        name => 'c',
                        attribute => '=s',
                    },
                },
            },
            # bar => {
            #     ...
            # },
        },
    );

    my $command = $parser->get_command;
    if ($command eq 'foo') {
        print "foo:", $parser->get_command_args();
    }

    # Or if "sub" exists in command's structure, simply invoke it.
    $parser->invoke;


    warn Dumper $self->get_global_opts();     # {global => 1, opt_hello => 'world'}
    warn Dumper $self->get_command();         # "foo"
    warn Dumper $self->get_command_opts();    # {opt_a => 1, opt_command => 1, opt_b => 'this is b', opt_c => 'this is c'}
    warn Dumper $self->get_command_args();    # ("bar", "baz")
    warn Dumper scalar $self->get_command_args();    # ["bar", "baz"]



=head1 DESCRIPTION

The module parses arguments which has sub-command like git.
It splits into 4 elements.
    - Global options
    - Command name
    - Command options
    - Command arguments

=head2 GLOBAL OPTIONS

Options before command.
Note that value string cannot be passed without "=".
    cmd -g global cmdname -a foo
In this case, it will be splitted like:
    - Global options: -g
    - Command name: global
    - Command options: -a
    - Command arguments: cmdname foo
Because Getopt::SubCommand just skips $arg =~ /^-/
to search command name.

User must pass option value like this:
    cmd -g=global cmdname -a foo

=head2 COMMAND NAME

No description is necessary :)

=head2 COMMAND OPTIONS

Command name.

=head2 COMMAND ARGUMENTS

Rest arguments after command name, command options.


=head1 METHODS

=over

=item new(%opts)

Create instance.

=item get_command()

Get command name.

=item get_command_args()

Get command arguments.
If list context, return array.
If scalar context, return array reference.

=item get_command_opts()

Get command options.

=item get_global_opts()

Get global options.

=item invoke()

=item invoke($opts)

Invoke command if "sub" exists in command's structure.

=item get_usage()

Get usage string.

=item show_usage()

Prints usage string and exit().

=item args_ref()

=item args_ref($args_ref)

Setter/Getter for arguments array reference.

=item parser_config()

=item parser_config($config)

Setter/Getter for config array reference for Getopt::Long::Parser->new().

=item parse_args()

=item parse_args($args_ref)

Parses $args_ref.
If $args_ref was not given,
$self->args_ref()'s value is used instead.

Array reference will be destroyed
(it must be empty array reference after call).

=item split_args()

=item split_args($args_ref)

Splits $args_ref into 4 elements of array.
If $args_ref was not given,
$self->args_ref()'s value is used instead.

Array reference will be destroyed
(it must be empty array reference after call).

TODO

=back


=head1 DEPENDENCIES

    Test::More
    Test::Pod
    Test::Pod::Coverage
    Test::Perl::Critic
    Test::Exception
    Test::Output
    Data::Util
    Class::Accessor::Fast


=head1 BUGS

No known bugs.


=head1 AUTHOR

tyru  C<< <tyru.exe@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, tyru C<< <tyru.exe@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
