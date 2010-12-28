use Test::More;
use Getopt::SubCommand;

my $parser = Getopt::SubCommand->new(
    args => [qw(
        --global --hello=world
        foo
        -a --command
    )],
    global_opts => {
        global => {
            name => [qw/g global/],
        },
        hello => {
            name => 'hello',
            attribute => '=s',
        },
    },
    commands => {
        foo => {
            options => {
                all => {
                    name => [qw/a all/],
                },
                command => {
                    name => [qw/c command/],
                },
            },
        },
    },
);

my @tests = (
    sub {
        is
            $parser->get_global_opts('global'),
            1,
            '$parser->get_global_opts()';
    },
    sub {
        is
            $parser->get_global_opts('hello'),
            "world",
            '$parser->get_global_opts()';
    },
    sub {
        is
            $parser->get_global_opts('unko'),
            undef,
            '$parser->get_global_opts()';
    },
    sub {
        is
            $parser->get_global_opts('unko', 'kuso'),
            'kuso',
            '$parser->get_global_opts()';
    },


    sub {
        is
            $parser->get_command_opts('all'),
            1,
            '$parser->get_command_opts()';
    },
    sub {
        is
            $parser->get_command_opts('command'),
            1,
            '$parser->get_command_opts()';
    },
    sub {
        is
            $parser->get_command_opts('unko'),
            undef,
            '$parser->get_command_opts()';
    },
    sub {
        is
            $parser->get_command_opts('unko', 'kuso'),
            'kuso',
            '$parser->get_command_opts()';
    },
);
$_->() for @tests;
done_testing scalar @tests;
