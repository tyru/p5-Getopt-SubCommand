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
        is ref $parser->can_invoke_command('foo'), 'CODE', "can invoke 'foo' command.";
    },
    sub {
        is ref $parser->can_invoke_command('bar'), 'CODE', "can invoke 'bar' command.";
    },
    sub {
        is $parser->can_invoke_command('baz'), undef, "cannot invoke 'baz' command.";
    },
);
$_->() for @tests;
done_testing scalar @tests;

