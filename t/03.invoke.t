use Test::More;
use Test::Exception;
use Test::Output;
use Getopt::SubCommand;


my @tests = (
    sub {
        dies_ok {
            Getopt::SubCommand->new(
                args_ref => [qw/foo -f bar baz/],
                commands => {
                    foo => {
                        # no command sub.
                    },
                    bar => {
                        sub => sub { print "bar" },
                    },
                },
            )->invoke
        } "no command sub in foo";
    },
    sub {
        lives_ok {
            Getopt::SubCommand->new(
                args_ref => [qw/foo -f bar baz/],
                commands => {
                    foo => {
                        # this must be called.
                        sub => sub { diag "foo" },
                    },
                    bar => {
                        sub => sub { print "bar" },
                    },
                },
            )->invoke
        } "'foo' must be called.";
    },
    sub {
        stdout_is {
            Getopt::SubCommand->new(
                args_ref => [qw/foo -f bar baz/],
                commands => {
                    foo => {
                        # this must be called.
                        sub => sub { print "foo" },
                    },
                    bar => {
                        sub => sub { print "bar" },
                    },
                },
            )->invoke
        } "foo", "check output of 'foo' command.";
    },
);
$_->() for @tests;
done_testing scalar @tests;

