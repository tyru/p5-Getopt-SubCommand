use Test::More;
use Test::Exception;
use Getopt::SubCommand;

my $parser;
my @tests = (
    sub {
        lives_ok {
            $parser = Getopt::SubCommand->new(
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
                },
            );
        };
    },
    sub {
        is_deeply $parser->args_ref, [
            '--global',
            '--hello=world',
            'foo',
            '-a',
            '--command',
            '-b=this is b',
            '-c',
            'this is c',
        ], '$parser->parse_args() does NOT destroy $parser->args_ref.';
    },
    sub {
        dies_ok { Getopt::SubCommand->new() };
    },
    sub {
        dies_ok { Getopt::SubCommand->new(commands => undef) };
    },
    sub {
        dies_ok { Getopt::SubCommand->new(commands => '') };
    },
    sub {
        dies_ok { Getopt::SubCommand->new(commands => []) };
    },
    sub {
        is_deeply $parser->get_global_opts(), {
            global => 1,
            opt_hello => 'world',
        }, "command name is 'foo'";
    },
    sub {
        is $parser->get_command, 'foo', "command name is 'foo'";
    },
    sub {
        is_deeply $parser->get_command_opts, {
            opt_a => 1,
            opt_command => 1,
            opt_b => 'this is b',
            opt_c => 'this is c',
        }, "command name is 'foo'";
    },
);
$_->() for @tests;
done_testing scalar @tests;
