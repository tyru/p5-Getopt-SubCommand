use Test::More;
use Test::Exception;
use Test::Exit;
use Getopt::SubCommand;

my @tests = (
    # "--help", auto_help_opt => 1
    sub {
        my $foo_is_called = 0;
        exits_zero {
            Getopt::SubCommand->new(
                args_ref => [qw/foo --help/],
                commands => {
                    foo => {
                        sub => sub { $foo_is_called = 1 },
                        auto_help_opt => 1,
                    },
                },
            )->invoke_command;
        } "exits with success";
        ok !$foo_is_called, "foo is not called.";
    },
    sub {},    # exits_zero(), ok()

    # "-h", auto_help_opt => 1
    sub {
        my $foo_is_called = 0;
        exits_zero {
            Getopt::SubCommand->new(
                args_ref => [qw/foo -h/],
                commands => {
                    foo => {
                        sub => sub { $foo_is_called = 1 },
                        auto_help_opt => 1,
                    },
                },
            )->invoke_command;
        } "exits with success";
        ok !$foo_is_called, "foo is not called.";
    },
    sub {},    # exits_zero(), ok()

    # "", auto_help_opt => 1
    sub {
        my $foo_is_called = 0;
        never_exits_ok {
            Getopt::SubCommand->new(
                args_ref => [qw/foo/],
                commands => {
                    foo => {
                        sub => sub { $foo_is_called = 1 },
                        auto_help_opt => 1,
                    },
                },
            )->invoke_command;
        } "never exits";
        ok $foo_is_called, "ok, foo is called.";
    },
    sub {},    # never_exits_ok(), ok()

    # "--help", auto_help_opt => 0
    sub {
        my $foo_is_called = 0;
        never_exits_ok {
            Getopt::SubCommand->new(
                args_ref => [qw/foo --help/],
                commands => {
                    foo => {
                        sub => sub { $foo_is_called = 1 },
                        auto_help_opt => 0,
                    },
                },
            )->invoke_command;
        } "never exits";
        ok $foo_is_called, "ok, foo is called.";
    },
    sub {},    # never_exits_ok(), ok()

    # "-h", auto_help_opt => 0
    sub {
        my $foo_is_called = 0;
        never_exits_ok {
            Getopt::SubCommand->new(
                args_ref => [qw/foo -h/],
                commands => {
                    foo => {
                        sub => sub { $foo_is_called = 1 },
                        auto_help_opt => 0,
                    },
                },
            )->invoke_command;
        } "never exits";
        ok $foo_is_called, "ok, foo is called.";
    },
    sub {},    # never_exits_ok(), ok()

    # "", auto_help_opt => 0
    sub {
        my $foo_is_called = 0;
        never_exits_ok {
            Getopt::SubCommand->new(
                args_ref => [qw/foo/],
                commands => {
                    foo => {
                        sub => sub { $foo_is_called = 1 },
                        auto_help_opt => 0,
                    },
                },
            )->invoke_command;
        } "never exits";
        ok $foo_is_called, "ok, foo is called.";
    },
    sub {},    # never_exits_ok(), ok()
);
$_->() for @tests;
done_testing scalar @tests;
