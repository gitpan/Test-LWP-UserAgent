use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.08

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
    'lib/Test/LWP/UserAgent.pm',
    't/00-report-prereqs.t',
    't/01-basic.t',
    't/02-overload.t',
    't/03-handlers.t',
    't/04-psgi.t',
    't/05-exceptions.t',
    't/06-network-fallback.t',
    't/07-mask-response.t',
    't/08-isa-coderef.t',
    't/09-dispatch-to-request-method.t',
    't/10-request-args-network.t',
    't/11-request-args-internal.t',
    't/50-examples-application_client_test.t',
    't/51-call_psgi.t',
    'xt/author/00-compile.t',
    'xt/author/pod-spell.t',
    'xt/release/changes_has_content.t',
    'xt/release/clean-namespaces.t',
    'xt/release/cpan-changes.t',
    'xt/release/distmeta.t',
    'xt/release/eol.t',
    'xt/release/kwalitee.t',
    'xt/release/minimum-version.t',
    'xt/release/mojibake.t',
    'xt/release/no-tabs.t',
    'xt/release/pod-coverage.t',
    'xt/release/pod-no404s.t',
    'xt/release/pod-syntax.t',
    'xt/release/portability.t'
);

notabs_ok($_) foreach @files;
done_testing;
