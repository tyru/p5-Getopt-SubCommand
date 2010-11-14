use Test::More;
use Test::Exception;
use Test::Output;
use Getopt::SubCommand;


my @tests = (
    sub {
        dies_ok {
            Getopt::SubCommand->new(
                args => [qw/foo -f bar baz/],
                commands => {
                    foo => {
                        # no command sub.
                    },
                    bar => {
                        sub => sub { print "bar" },
                    },
                },
            )->invoke_command
        } "no command sub in foo";
    },
    sub {
        lives_ok {
            Getopt::SubCommand->new(
                args => [qw/foo -f bar baz/],
                commands => {
                    foo => {
                        # this must be called.
                        sub => sub { diag "foo" },
                    },
                    bar => {
                        sub => sub { print "bar" },
                    },
                },
            )->invoke_command
        } "'foo' must be called.";
    },
    sub {
        stdout_is {
            Getopt::SubCommand->new(
                args => [qw/foo -f bar baz/],
                commands => {
                    foo => {
                        # this must be called.
                        sub => sub { print "foo" },
                    },
                    bar => {
                        sub => sub { print "bar" },
                    },
                },
            )->invoke_command
        } "foo", "check output of 'foo' command.";
    },
);
$_->() for @tests;
done_testing scalar @tests;

