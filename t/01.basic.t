use Test::More;
use Test::Exception;
use Test::Output;
use Getopt::SubCommand;

my $parser;
my @test_args = (
    qw(
        --global --hello=world
        foo
        -a --command
    ),
    q(-b=this is b),
    q(-c), q(this is c),
    qw(bar baz),
);

my @tests = (
    sub {
        lives_ok {
            $parser = Getopt::SubCommand->new(
                do_parse_args => 0,    # do not parse_args() at new().
                args => [@test_args],
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
                        sub => sub { print "foo" },
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
        is_deeply $parser->get_args, [@test_args]
            ,'$parser->new(do_parse_args => 0, ...)'
                . 'does NOT destroy $parser->get_args() yet.';
    },
    sub {
        $parser->parse_args();
        is_deeply $parser->get_args, []
            ,'now $parser->get_args() is empty array-ref.';
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
    sub {
        is_deeply $parser->get_command_args, [qw/bar baz/], "command's args is 'bar', 'baz'.";
    },
    sub {
        stdout_is sub { $parser->invoke_command() }, 'foo', 'invoking "foo" command.';
    },
);
$_->() for @tests;
done_testing scalar @tests;
