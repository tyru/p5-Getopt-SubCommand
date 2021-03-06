use Test::More;
use Test::Output;
use Test::Exception;
use Getopt::SubCommand;

my $parser;
my @tests = (
    sub {
        $parser = Getopt::SubCommand->new(
            args => [],
            commands => {
                foo => {
                    sub => sub { print "foo" },
                },
                bar => {
                    sub => sub { print "bar" },
                },
                baz => {
                    # sub => sub { print "baz" },
                },
            },
        );
        ok $parser, "creating instance.";
    },
    sub {
        is ref $parser->can_invoke_command('foo'), 'CODE',
            "can invoke 'foo' command.";
    },
    sub {
        is ref $parser->can_invoke_command('bar'), 'CODE',
            "can invoke 'bar' command.";
    },
    sub {
        is $parser->can_invoke_command('baz'), undef,
            "cannot invoke 'baz' command.";
    },
    sub {
        is $parser->can_invoke_command(undef), undef,
            "return undef for invalid argument type.";
    },
    sub {
        is $parser->can_invoke_command([]), undef,
            "return undef for invalid argument type.";
    },
    sub {
        is $parser->can_invoke_command({}), undef,
            "return undef for invalid argument type.";
    },
    sub {
        is $parser->can_invoke_command(sub {}), undef,
            "return undef for invalid argument type.";
    },
);
$_->() for @tests;
done_testing scalar @tests;

