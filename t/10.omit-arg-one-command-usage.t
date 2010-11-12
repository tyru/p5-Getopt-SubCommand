use Test::More;
use Getopt::SubCommand;

my @tests = (
    sub {
        my $parser = Getopt::SubCommand->new(
            args_ref => [qw/foo bar/],
            commands => {
                foo => {
                    usage => 'this is foo',
                }
            },
        );
        my $omitted = $parser->get_command_usage;
        my $specified = $parser->get_command_usage('foo');
        is $omitted, $specified,
            'if arg 1 is omitted, use $self->get_command() instead.';
    },
);
$_->() for @tests;
done_testing;

