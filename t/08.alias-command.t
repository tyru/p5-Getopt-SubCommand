use Test::More;
use Test::Output;
use Test::Exception;
use Getopt::SubCommand;

my $parser;
my @tests = (
    sub {
        $parser = Getopt::SubCommand->new(
            do_parse_args => 0,
            aliases => {
                "\\Afo*\\Z" => 'foo',
            },
            commands => {
                foo => {
                    sub => sub { print "foo" },
                },
            },
        );
        ok $parser, "creating instance.";
    },
    sub {
        $parser->parse_args([qw/f bar baz/]);
        stdout_is {
            eval { $parser->invoke_command }
        } "foo", "invoking 'foo' command.";
    },
    sub {
        $parser->parse_args([qw/fo bar baz/]);
        stdout_is {
            eval { $parser->invoke_command }
        } "foo", "invoking 'foo' command.";
    },
    sub {
        $parser->parse_args([qw/foooooooooo bar baz/]);
        stdout_is {
            eval { $parser->invoke_command }
        } "foo", "invoking 'foo' command.";
    },
    sub {
        $parser->parse_args([qw/hello bar baz/]);
        dies_ok {
            $parser->invoke_command
        } "invoking 'hello' command will fail.";
    },
);
$_->() for @tests;
done_testing scalar @tests;
