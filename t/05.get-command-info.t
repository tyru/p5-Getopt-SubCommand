use Test::More;
use Test::Output;
use Getopt::SubCommand;


my $parser;
my @tests = (
    sub {
        $parser = Getopt::SubCommand->new(
            commands => {
                foo => {
                    usage => 'this is foo'
                },
                bar => {
                    usage => 'this is bar'
                },
                baz => {
                    # usage => 'this is bar'
                },
            },
        );
        ok $parser, "creating instance";
    },
    sub {
        is $parser->get_command_usage(), undef, 'get_command_usage(): check arguments';
    },
    sub {
        is $parser->get_command_usage('foo'), 'this is foo', "get 'foo' usage.";
    },
    sub {
        is $parser->get_command_usage('bar'), 'this is bar', "get 'bar' usage.";
    },
    sub {
        is $parser->get_command_usage('baz'), undef, "'baz' does not have usage.";
    },
    sub {
        is $parser->get_command_usage('unko'), undef, "'unko' does not have usage.";
    },
    sub {
        stdout_is {
            $parser->show_command_usage('foo', exit => 0)
        } "this is foo", "output is 'this is foo'.";
    },
    sub {
        stdout_is {
            $parser->show_command_usage('foo', exit => 0)
        } "this is foo", "output is 'this is foo'.";
    },
    sub {
        stdout_is {
            $parser->show_command_usage('foo', exit => 0)
        } "this is foo", "output is 'this is foo'.";
    },
    sub {
        stderr_is {
            $parser->show_command_usage('foo', filehandle => \*STDERR, exit => 0)
        } "this is foo", "output is 'this is foo'.";
    },
);
$_->() for @tests;
done_testing scalar @tests;
