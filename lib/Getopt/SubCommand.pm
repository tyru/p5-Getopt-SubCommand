package Getopt::SubCommand;

use 5.008_001;
use strict;
use warnings;
use Carp qw/carp croak/;

our $VERSION = eval '0.001';

use Getopt::Long ();
use Scalar::Util ();
use Data::Util qw/:check anon_scalar/;
use Regexp::Assemble;
use base qw/Class::Accessor::Fast/;
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(qw/args parser_config/);
__PACKAGE__->mk_ro_accessors(qw/command command_args/);



sub new {
    my ($class, %opts) = @_;
    # Override default values with user values.
    %opts = (
        do_parse_args => 1,
        auto_help_command => 1,
        %opts,
    );

    my $self = bless {
        usage_name => defined $opts{usage_name} ? $opts{usage_name} : '[No name]',
        usage_version => $opts{usage_version},
        usage_args => $opts{usage_args},
        commands => $opts{commands},
        global_opts => $opts{global_opts},
        aliases => $opts{aliases} || {},
    }, $class;
    $self->set_args(do {
        if (exists $opts{args}) {
            if (is_array_ref $opts{args}) {
                $opts{args};
            }
            else {
                croak "'args' is array reference but invalid value was given.";
            }
        }
        else {
            \@ARGV;
        }
    });
    $self->set_parser_config([]);

    # Store parsing results.
    $self->parse_args() if $opts{do_parse_args};

    if ($opts{auto_help_command}) {
        $self->{commands}{help} = {
            sub => $self->__generate_help_command(),
            %{$self->{commands}{help} || {}},
        };
    }

    $self;
}

sub __generate_help_command {
    my ($self) = @_;

    my $weakened_self = $self;
    Scalar::Util::weaken $weakened_self;

    return sub {
        my (undef, undef, $args) = @_;
        if (@$args) {
            my $cmd = shift @$args;
            if ($weakened_self->can_invoke_command($cmd)) {
                $weakened_self->show_command_usage($cmd);
            }
            else {
                warn "Unknown command: $cmd\n\n";
                sleep 1;
                $weakened_self->show_usage;
            }
        }
        else {
            $weakened_self->show_usage;
        }
    };
}


sub parse_args {
    my ($self, $args) = @_;
    $args = $self->get_args unless defined $args;

    # split_args() destroys $args.
    my ($global_opts, $cmd, $cmd_opts, $cmd_args) = $self->split_args($args);

    $self->__set_global_opts($global_opts);
    $self->set('command', $cmd);
    $self->__set_command_opts($cmd_opts);
    $self->set('command_args', $cmd_args);
}

sub split_args {
    my ($self, $args) = @_;
    my ($global_opts, $command, $command_opts, $command_args);
    $args = $self->get_args unless defined $args;
    goto end unless is_array_ref($args) && @$args;

    # Global options.
    my @g;
    push @g, shift @$args while @$args && $args->[0] =~ /^-/;
    if (@g) {
        $global_opts = $self->__get_options(
            \@g,    # __get_options() destroys @g.
            $self->{global_opts},
        ) or goto end;
        $self->__validate_required_global_opts($global_opts);
        # @g becomes non-zero elements of array
        # when global options were separated by "--".
        unshift @$args, @g;
    }

    # Command name.
    @$args or goto end;
    $command = shift @$args;

    # Command options.
    if (defined($_ = __get_key($self, ['commands', $command]))
        && $_->{auto_help_opt})
    {
        $_->{options}{help} = {
            name => [qw/h help/],
        };
    }
    defined __get_key($self, ['commands', $command, 'options']) or goto end;
    $command_opts = $self->__get_options(
        $args,    # __get_options() destroys $args.
        $self->{commands}{$command}{options},
    ) or goto end;
    $self->__validate_required_command_opts($command, $command_opts);

end:
    # Command args.
    $command_args = [@$args];
    @$args = ();

    ($global_opts, $command, $command_opts, $command_args);
}

# Returns undef when it fails to parse.
# Returns hashref when it succeeds.
sub __get_options {
    my ($self, $args, $opts) = @_;

    local @ARGV = @$args;

    # Add some required options for suitable form
    # to parse sub-command arguments.
    # - gnu_compat: --opt="..." is allowed.
    # - no_bundling: single character option is not bundled.
    # - no_ignore_case: no ignore case on long option.
    my $c = $self->get_parser_config;
    my $p = Getopt::Long::Parser->new(config => [
        @$c, qw(gnu_compat no_bundling no_ignore_case)
    ]);
    my ($parser_args, $ref_args) = $self->__build_parser_args($opts);
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
    my $h = __get_key($self, ['global_opts']) || return;
    $self->__validate_required_opts($h, $got_opts);
}

sub __validate_required_command_opts {
    my ($self, $command, $got_opts) = @_;
    my $h = __get_key($self, ['commands', $command, 'options']) || return;
    $self->__validate_required_opts($h, $got_opts);
}

sub __validate_required_opts {
    my (undef, $h, $got_opts) = @_;

    for my $optname (keys %$h) {
        my $required = __get_key($h, [$optname, 'required']);
        if ($required && ! exists $got_opts->{$optname}) {
            $optname = length $optname == 1 ? "-$optname" : "--$optname";
            croak "required option '$optname' is missing.";
        }
    }
}

sub __build_parser_args {
    my ($self, $opts) = @_;
    my %ref_args;
    my %getopt_args;    # Getopt::Long::GetOptions()'s args.
    for my $store_name (keys %$opts) {
        my $info = $opts->{$store_name};

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

    my $cmdname = $self->{usage_name};
    my $version = defined $self->{usage_version} ? $self->{usage_version} : '';
    my $cmdargs = defined $self->{usage_args} ? $self->{usage_args} : 'COMMAND ARGS';
    my $available_commands = join "\n", map {
        my $name = $_;
        my $usage = __get_key($self, ['commands', $name, 'usage']);
        "  $name" . (defined $usage ? " - $usage" : '');
    } keys %{$self->{commands}};

    return <<EOM;
$cmdname $version
usage:
  $cmdname [options] $cmdargs

Avaiable commands are:
$available_commands

See '$cmdname help COMMAND' for more information on a specific command.
EOM
}

sub show_usage {
    my ($self, %opts) = @_;
    %opts = (filehandle => \*STDOUT, exit => 1, exit_status => 0, %opts);
    print {$opts{filehandle}} $self->get_usage;
    exit $opts{exit_status} if $opts{exit};
}

sub get_command_usage {
    my ($self, $command) = @_;
    my $cmd = __get_key($self, ['commands', $command]);
    return undef unless defined $cmd;

    my $cmdname = $self->{usage_name};
    my $cmdargs = defined $cmd->{usage_args} ? $cmd->{usage_args} : 'ARGS';
    my $cmdusage = defined $cmd->{usage} ? " - $cmd->{usage}" : '';
    my $options = $cmd->{options};
    my $available_options = '';
    if (defined $options) {
        $available_options = "options:\n" . join "\n", map {
            my $name = $_;
            my $optnames = __get_key($options, [$name, 'name']);
            if (is_array_ref $optnames) {
                $optnames = join ',', map {
                    length $_ == 1 ? "-$_" : "--$_"
                } @$optnames;
            }
            else {
                $optnames = length $optnames == 1 ? "-$optnames" : "--$optnames";
            }
            my $usage = __get_key($options, [$name, 'usage']);
            "  $optnames" . (defined $usage ? " - $usage" : '');
        } keys %$options;
    }
    return <<EOM;
usage:
  $cmdname [options] $command $cmdargs$cmdusage
$available_options
EOM
}

sub show_command_usage {
    my ($self, $command, %opts) = @_;
    %opts = (filehandle => \*STDOUT, exit => 1, exit_status => 0, %opts);
    my $usage = $self->get_command_usage($command);
    print {$opts{filehandle}} $usage if defined $usage;
    exit $opts{exit_status} if $opts{exit};
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
    return $h unless is_hash_ref $h;
    # Dereference anon-scalar values.
    +{map {
        $a = $h->{$_};
        ($_ => (is_scalar_ref($a) ? $$a : $a));
    } keys %$h}
}


sub __get_command {
    my ($self, $str_or_coderef) = @_;

    if (is_code_ref $str_or_coderef) {
        return $str_or_coderef;
    }
    if (is_string($str_or_coderef)
        && defined __get_key($self, ['commands', $str_or_coderef, 'sub']))
    {
        return $self->{commands}{$str_or_coderef}{sub};
    }
    return undef;
}

sub can_invoke_command {
    my ($self, $command) = @_;
    my $sub = __get_key($self, ['commands', $command, 'sub']);
    unless (is_code_ref $sub) {
        # Find aliases.
        my $aliases = $self->{aliases};
        if (defined $command && %$aliases) {
            my $alias_table = $self->{__cache}{alias_table} ||=
                Regexp::Assemble->new->track->add(keys %$aliases);
            if ($alias_table->match($command)) {
                my $cmd = $aliases->{$alias_table->matched};
                $sub = $self->__get_command($cmd);
            }
        }
    }
    $sub;
}

sub invoke_command {
    my $self = shift;
    my %opts = (@_ == 1 ? (command => shift) : @_);

    my $command = defined $opts{command} ? $opts{command} : $self->get_command;
    my $sub = $self->can_invoke_command($command);
    if (!is_code_ref($sub) && exists $opts{fallback}) {    # fallback.
        $sub = $self->__get_command($opts{fallback});
    }
    croak "fatal: No sub could be found." unless is_code_ref $sub;

    my @optional_args;
    if (is_array_ref $opts{optional_args}) {
        @optional_args = @{$opts{optional_args}};
    }

    # Process special option which are told to process at new().
    if (__get_key($self, ['commands', $self->get_command, 'auto_help_opt'])
        && defined($_ = $self->get_command_opts)
        && $_->{help})
    {
        $self->show_command_usage($command);
        exit 1;    # this will be never reached.
    }

    $sub->(
        $self->get_global_opts(),
        $self->get_command_opts(),
        $self->get_command_args(),
        @optional_args,
    );
}


# Accessing to value without creating empty key.
# Returns undef when it fails to get element.
# Returns element value when it succeeds.
# NOTE: this cannot work correctly for undef element.
sub __get_key {
    my ($hashref, $keys) = @_;
    my $key = shift @$keys;

    return undef unless is_string $key;
    return undef unless exists $hashref->{$key};
    return $hashref->{$key} unless @$keys;

    @_ = ($hashref->{$key}, $keys);
    goto &__get_key;
}


1;
__END__

=head1 NAME

Getopt::SubCommand - Simple sub-command parser


=head1 SYNOPSIS

    use Getopt::SubCommand;
    my $parser = Getopt::SubCommand->new(
        # args => \@ARGV,    # default to \@ARGV
        args => [qw(
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
        my $args = $parser->get_command_args();
        print "foo:", @$args;
    }

    # Or if "sub" exists in command's structure, simply invoke it.
    $parser->invoke_command;


    warn Dumper $self->get_global_opts();     # {global => 1, opt_hello => 'world'}
    warn Dumper $self->get_command();         # "foo"
    warn Dumper $self->get_command_opts();    # {opt_a => 1, opt_command => 1, opt_b => 'this is b', opt_c => 'this is c'}
    warn Dumper $self->get_command_args();    # ["bar", "baz"]



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
This becomes undef when no command is found.

=item get_command_args()

Get command arguments (array reference).

This is undef before calling $self->parse_args().
After call, This must not be undef.

=item get_command_opts()

Get command options.
This becomes undef when no command options are found.

=item get_global_opts()

Get global options.
This becomes undef when no global options are found.

=item can_invoke_command($command)

This returns code reference if $self has $command's sub.
Or not, returns undef.

=item invoke_command()

=item invoke_command(%opts)

Invoke command if "sub" exists in command's structure.

=item get_usage()

Get usage string.

=item show_usage()

Prints usage string and exit().

=item get_command_usage($command)

Get command usage string.

=item show_command_usage($command)

Prints command usage string and exit().

=item get_args()
Getter for arguments array reference.

=item set_args($args)

Setter for arguments array reference.

=item get_parser_config()

Getter for config array reference for Getopt::Long::Parser->new().

=item set_parser_config($config)

Setter for config array reference for Getopt::Long::Parser->new().

=item parse_args()

=item parse_args($args)

Parses $args.
If $args was not given,
$self->get_args()'s value is used instead.

Array reference will be destroyed
(it must be empty array reference after call).

=item split_args()

=item split_args($args)

Splits $args into 4 elements of array.
If $args was not given,
$self->get_args()'s value is used instead.

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
