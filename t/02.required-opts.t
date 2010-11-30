use Test::More;
use Test::Exception;
use Getopt::SubCommand;


my @tests = (
    sub {
        lives_ok {
            Getopt::SubCommand->new(
                args => [qw/delete -f/],
                commands => {
                    delete => {
                        sub => sub { print "!!! DELETE SOMETHING IMPORTANT !!!" },
                        options => {
                            force => {name => [qw/f force/], required => 1},
                        },
                    },
                },
            )->validate_required_opts;
        } "required option is given. it must live";
    },
    sub {
        dies_ok {
            Getopt::SubCommand->new(
                args => [qw/delete/],    # no -f, it must die
                commands => {
                    delete => {
                        sub => sub { print "!!! DELETE SOMETHING IMPORTANT !!!" },
                        options => {
                            force => {name => [qw/f force/], required => 1},
                        },
                    },
                },
            )->validate_required_opts;
        } "required option is missing. it must die";
    },
);
$_->() for @tests;
done_testing scalar @tests;
