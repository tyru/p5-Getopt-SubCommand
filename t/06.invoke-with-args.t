use Test::More;
use Test::Output;
use Test::Exception;
use Getopt::SubCommand;


my $parser;
my @tests = (
    sub {
        $parser = Getopt::SubCommand->new(
            commands => {
                foo => {
                    sub => sub { print "foo" }
                },
                bar => {
                    sub => sub { print "bar" }
                },
                baz => {
                    # usage => 'this is bar'
                },
            },
        );
        ok $parser, "creating instance";
    },

    sub {
        stdout_is {
            $parser->invoke_command('foo')
        } "foo", "invoking 'foo'.";
    },
    sub {
        stdout_is {
            $parser->invoke_command('bar')
        } "bar", "invoking 'bar'.";
    },
    sub {
        dies_ok {
            $parser->invoke_command('baz')
        } "invoking 'baz' must fail.";
    },
    sub {
        dies_ok {
            $parser->invoke_command('hello')
        } "invoking 'hello' must fail.";
    },

    sub {
        stdout_is {
            $parser->invoke_command({command => 'foo'})
        } "foo", "invoking 'foo'.";
    },
    sub {
        dies_ok {
            $parser->invoke_command({command => 'baz'})
        } "invoking 'baz' must fail.";
    },
    sub {
        my $invoked;
        lives_ok {
            $parser->invoke_command({
                command => 'hello',
                fallback => sub {
                    $invoked = 1
                },
            })
        } "invoking 'hello' must fail.";
        ok $invoked;
    },
    sub {},    # for previous test
);
$_->() for @tests;
done_testing scalar @tests;

