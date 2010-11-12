use Test::More;
use Test::Output;
use Test::Exception;
use Getopt::SubCommand;

my $parser;
my @tests = (
    sub {
        $parser = Getopt::SubCommand->new(
            do_parse_args => 0,
            commands => {
                foo => {
                    sub => sub { print "foo" },
                },
                bar => {
                    sub => sub { print "bar" },
                },
                baz => {
                    sub => sub { print "baz" },
                },
                hello => {
                    sub => sub { print "hello" },
                },
            },
        );
        ok $parser, "creating instance.";
    },
    sub {
        $parser->parse_args([qw/foo arg1 arg2/]);
        stdout_is {
            eval { $parser->invoke_command }
        } "foo", "invoking 'foo' command.";
    },
    sub {
        $parser->parse_args([qw/bar arg1 arg2/]);
        stdout_is {
            eval { $parser->invoke_command }
        } "bar", "invoking 'bar' command.";
    },
    sub {
        $parser->parse_args([qw/baz arg1 arg2/]);
        stdout_is {
            eval { $parser->invoke_command }
        } "baz", "invoking 'baz' command.";
    },
    sub {
        $parser->parse_args([qw/hello arg1 arg2/]);
        stdout_is {
            eval { $parser->invoke_command }
        } "hello", "invoking 'hello' command.";
    },
);
$_->() for @tests;
done_testing scalar @tests;
