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
        is $parser->get_command_usage(), undef,
            'get_command_usage(): check arguments';
    },
    sub {
        like $parser->get_command_usage('foo'), qr/this is foo/,
            "get 'foo' usage.";
    },
    sub {
        like $parser->get_command_usage('bar'), qr/this is bar/,
            "get 'bar' usage.";
    },
    sub {
        like $parser->get_command_usage('baz'), qr/.+/,    # no usage
            "'baz' does not have usage but output is generated because it exists.";
    },
    sub {
        is $parser->get_command_usage('unko'), undef,
            "'unko' does not have usage.";
    },
    sub {
        stdout_like {
            $parser->show_command_usage('foo', exit => 0)
        } qr/this is foo/, "output is 'this is foo'.";
    },
    sub {
        stdout_like {
            $parser->show_command_usage('bar', exit => 0)
        } qr/this is bar/, "output is 'this is bar'.";
    },
    sub {
        stdout_isnt {
            $parser->show_command_usage('baz', exit => 0)
        } '', "has output.";
    },
    sub {
        stdout_is {
            $parser->show_command_usage('unko', exit => 0)
        } '', "'unko' does not have usage.";
    },
    sub {
        stderr_like {
            $parser->show_command_usage('foo', filehandle => \*STDERR, exit => 0)
        } qr/this is foo/, "'foo' does not have usage.";
    },
);
$_->() for @tests;
done_testing scalar @tests;
