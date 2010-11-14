use Test::More;
use Test::Output;
use Test::Exception;
use Getopt::SubCommand;

my $parser;
my $help_is_called = 0;
my @tests = (
    sub {
        $parser = Getopt::SubCommand->new(
            commands => {
                help => {
                    sub => sub { $help_is_called = 1 },
                    usage => "E478: Don't panic!",
                },
            },
        );
        ok $parser, "creating instance.";
    },
    sub {
        is $parser->get_command_usage('help'), "E478: Don't panic!",
            "can get usage text of 'help' command.";
    },
    sub {
        eval { $parser->invoke_command('help') };
        ok !$@, "no error while invoking 'help' command.";
    },
    sub {
        ok $help_is_called, "ok, 'help' command is called.";
    },
);
$_->() for @tests;
done_testing scalar @tests;


