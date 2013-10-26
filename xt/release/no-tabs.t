use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.05

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'examples/MyApp/Client.pm',
    'examples/advent_2012_1.pl',
    'examples/advent_2012_2.pl',
    'examples/advent_2012_3.pl',
    'examples/application_client_test.t',
    'examples/call_psgi.t',
    'examples/myapp.psgi',
    'lib/Test/LWP/UserAgent.pm'
);

notabs_ok($_) foreach @files;
done_testing;
