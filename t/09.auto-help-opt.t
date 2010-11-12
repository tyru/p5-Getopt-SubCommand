use Test::More;
use Test::Exception;
use Test::Exit;
use Getopt::SubCommand;

my @tests = (
    # "--help", auto_help_opt => 1
    do {
        SKIP: {
            skip "exits_ok() shows bad habit output?", 2;

            my $foo_is_called = 0;
            (
                sub {
                    exits_ok {
                        Getopt::SubCommand->new(
                            args_ref => [qw/foo --help/],
                            commands => {
                                foo => {
                                    sub => sub { $foo_is_called = 1 },
                                    usage => 'This is foo.',
                                    auto_help_opt => 1,
                                },
                            },
                        )->invoke_command;
                    } "exits with success";
                },
                sub {
                    ok !$foo_is_called, "foo is not called.";
                },
            )
        }
    },

    # "-h", auto_help_opt => 1
    do {
        SKIP: {
            skip "exits_ok() shows bad habit output?", 2;

            my $foo_is_called = 0;
            (
                sub {
                    exits_ok {
                        Getopt::SubCommand->new(
                            args_ref => [qw/foo -h/],
                            commands => {
                                foo => {
                                    sub => sub { $foo_is_called = 1 },
                                    usage => 'This is foo.',
                                    auto_help_opt => 1,
                                },
                            },
                        )->invoke_command;
                    } "exits with success";
                },
                sub {
                    ok !$foo_is_called, "foo is not called.";
                },
            )
        }
    },

    # "", auto_help_opt => 1
    do {
        my $foo_is_called = 0;
        (
            sub {
                never_exits_ok {
                    Getopt::SubCommand->new(
                        args_ref => [qw/foo/],
                        commands => {
                            foo => {
                                sub => sub { $foo_is_called = 1 },
                                usage => 'This is foo.',
                                auto_help_opt => 1,
                            },
                        },
                    )->invoke_command;
                } "never exits";
            },
            sub {
                ok $foo_is_called, "ok, foo is called.";
            },
        )
    },

    # "--help", auto_help_opt => 0
    do {
        my $foo_is_called = 0;
        (
            sub {
                never_exits_ok {
                    Getopt::SubCommand->new(
                        args_ref => [qw/foo --help/],
                        commands => {
                            foo => {
                                sub => sub { $foo_is_called = 1 },
                                usage => 'This is foo.',
                                auto_help_opt => 0,
                            },
                        },
                    )->invoke_command;
                } "never exits";
            },
            sub {
                ok $foo_is_called, "ok, foo is called.";
            },
        )
    },

    # "-h", auto_help_opt => 0
    do {
        my $foo_is_called = 0;
        (
            sub {
                never_exits_ok {
                    Getopt::SubCommand->new(
                        args_ref => [qw/foo -h/],
                        commands => {
                            foo => {
                                sub => sub { $foo_is_called = 1 },
                                usage => 'This is foo.',
                                auto_help_opt => 0,
                            },
                        },
                    )->invoke_command;
                } "never exits";
            },
            sub {
                ok $foo_is_called, "ok, foo is called.";
            },
        )
    },

    # "", auto_help_opt => 0
    do {
        my $foo_is_called = 0;
        (
            sub {
                never_exits_ok {
                    Getopt::SubCommand->new(
                        args_ref => [qw/foo/],
                        commands => {
                            foo => {
                                sub => sub { $foo_is_called = 1 },
                                usage => 'This is foo.',
                                auto_help_opt => 0,
                            },
                        },
                    )->invoke_command;
                } "never exits";
            },
            sub {
                ok $foo_is_called, "ok, foo is called.";
            },
        )
    },
);
$_->() for @tests;
done_testing;
