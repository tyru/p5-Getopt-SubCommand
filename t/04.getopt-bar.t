use Test::More;
use Getopt::SubCommand;


my $parser;
my @tests = (
    sub {
        $parser = Getopt::SubCommand->new(
            args => [qw/--global -- -a foo/],
            global_opts => {
                global => {name => 'global'},
                a      => {name => 'a'},
            },
            commands => {},
        );
        ok $parser, "creating instance";
    },
    sub {
        is_deeply
            $parser->get_global_opts(),
            {global => 1},
            '-a is not included to $parser->global_opts()';
    },
    sub {
        is
            $parser->get_command(),
            '-a',
            '-a is command name.';
    },
    sub {
        ok
            ! defined $parser->get_command_opts(),
            q(no command options because 'commands' is empty hashref.);
    },
    sub {
        is_deeply
            scalar $parser->get_command_args(),
            [qw/foo/],
            'checking command arguments.';
    },
);
$_->() for @tests;
done_testing scalar @tests;
