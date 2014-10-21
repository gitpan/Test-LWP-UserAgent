package Test::LWP::UserAgent;
{
  $Test::LWP::UserAgent::VERSION = '0.007';
}
# git description: v0.006-TRIAL-12-gfbbc912


use strict;
use warnings;

use parent 'LWP::UserAgent';
use Scalar::Util qw(blessed reftype);
use Storable 'freeze';
use HTTP::Request;
use HTTP::Response;
use URI;
use HTTP::Date;

my $last_http_request_sent;
my $last_http_response_received;
my @response_map;

sub new
{
    my $class = shift;

    my $self = $class->SUPER::new(@_);
    $self->{__last_http_request_sent} = undef;
    $self->{__last_http_response_received} = undef;
    $self->{__response_map} = [];

    # strips default User-Agent header added by LWP::UserAgent, to make it
    # easier to define literal HTTP::Requests to match against
    $self->agent(undef) if defined $self->agent and $self->agent eq $self->_agent;

    return $self;
}

sub map_response
{
    my ($self, $request_description, $response) = @_;

    if (not defined $response and not reftype $request_description and blessed $self)
    {
        # mask a global domain mapping
        my @indexes = grep {
            not reftype $_->[0] and $_->[0] eq $request_description
        } @{$self->{__response_map}};

        if (@indexes)
        {
            undef @{$self->{__response_map}}[@indexes];
        }
        else
        {
            push @{$self->{__response_map}}, [ $request_description, undef ];
        }
        return;
    }

    warn "map_response: response is not an HTTP::Response, it's a " . blessed($response)
        unless eval { \&$response } or eval { $response->isa('HTTP::Response') };

    if (blessed $self)
    {
        push @{$self->{__response_map}}, [ $request_description, $response ];
    }
    else
    {
        push @response_map, [ $request_description, $response ];
    }
}

sub unmap_all
{
    my ($self, $instance_only) = @_;

    if (blessed $self)
    {
        $self->{__response_map} = [];
        @response_map = () unless $instance_only;
    }
    else
    {
        warn 'instance-only unmap requests make no sense when called globally'
            if $instance_only;
        @response_map = ();
    }
}

sub register_psgi
{
    my ($self, $domain, $app) = @_;

    return $self->map_response($domain, undef) if not defined $app;

    warn "register_psgi: app is not a coderef, it's a " . ref($app)
        unless eval { \&$app };

    warn "register_psgi: did you forget to load HTTP::Message::PSGI?"
        unless HTTP::Request->can('to_psgi') and HTTP::Response->can('from_psgi');

    return $self->map_response(
        $domain,
        sub { HTTP::Response->from_psgi($app->($_[0]->to_psgi)) },
    );
}

sub unregister_psgi
{
    my ($self, $domain, $instance_only) = @_;

    if (blessed $self)
    {
        @{$self->{__response_map}} = grep { $_->[0] ne $domain } @{$self->{__response_map}};

        @response_map = grep { $_->[0] ne $domain } @response_map
            unless $instance_only;
    }
    else
    {
        @response_map = grep { $_->[0] ne $domain } @response_map;
    }
}

sub last_http_request_sent
{
    my $self = shift;
    return blessed($self)
        ? $self->{__last_http_request_sent}
        : $last_http_request_sent;
}

sub last_http_response_received
{
    my $self = shift;
    return blessed($self)
        ? $self->{__last_http_response_received}
        : $last_http_response_received;
}

sub __is_regexp($);

sub send_request
{
    my ($self, $request) = @_;

    $self->progress("begin", $request);
    my $matched_response = $self->run_handlers("request_send", $request);

    my $uri = $request->uri;

    foreach my $entry (@{$self->{__response_map}}, @response_map)
    {
        last if $matched_response;
        next if not defined $entry;
        my ($request_desc, $response) = @$entry;

        if (eval { $request_desc->isa('HTTP::Request') })
        {
            $matched_response = $response, last
                if freeze($request) eq freeze($request_desc);
        }
        elsif (not reftype $request_desc)
        {
            $uri = URI->new($uri) if not eval { $uri->isa('URI') };
            $matched_response = $response, last
                if $uri->host eq $request_desc;
        }
        elsif (eval { \&$request_desc })
        {
            $matched_response = $response, last
                if $request_desc->($request);
        }
        elsif (__is_regexp $request_desc)
        {
            $matched_response = $response, last
                if $request->uri =~ $request_desc;
        }
        else
        {
            warn 'unknown request type found in ' . blessed($self) . ' mapping!';
        }
    }

    $last_http_request_sent = $self->{__last_http_request_sent} = $request;

    my $response = defined $matched_response ? $matched_response : HTTP::Response->new(404);

    if (eval { \&$response })
    {
        $response = $response->($request);

        warn "response from coderef is not a HTTP::Response, it's a ", blessed($response)
            unless eval { $response->isa('HTTP::Response') };
    }

    $last_http_response_received = $self->{__last_http_response_received} = $response;

    # bookkeeping that the real LWP::UserAgent does
    $response->request($request);  # record request for reference
    $response->header("Client-Date" => HTTP::Date::time2str(time));
    $self->run_handlers("response_done", $response);
    $self->progress("end", $response);

    return $response;
}

sub __is_regexp($)
{
    $^V < 5.009005 ? ref(shift) eq 'Regexp' : re::is_regexp(shift);
}

1;
__END__

=pod

=head1 NAME

Test::LWP::UserAgent - a LWP::UserAgent suitable for simulating and testing network calls

=head1 VERSION

version 0.007

=head1 SYNOPSIS

In your real code:

    use URI;
    use HTTP::Request::Common;
    use LWP::UserAgent;

    my $ua = $self->useragent || LWP::UserAgent->new;

    my $uri = URI->new('http://example.com');
    $uri->port(3000);
    $uri->path('success');
    my $request = POST($uri, a => 1);
    my $response = $ua->request($request);

Then, in your tests:

    use Test::LWP::UserAgent;
    use Test::More;

    Test::LWP::UserAgent->map_response(
        qr{example.com/success}, HTTP::Response->new(200, 'OK', ['Content-Type' => 'text/plain'], ''));
    Test::LWP::UserAgent->map_response(
        qr{example.com/fail}, HTTP::Response->new(500, 'ERROR', ['Content-Type' => 'text/plain'], ''));
    Test::LWP::UserAgent->map_response(
        qr{example.com/conditional},
        sub {
            my $request = shift;
            my $success = $request->uri =~ /success/;
            return HTTP::Response->new(
                ($success ? ( 200, 'OK') : (500, 'ERROR'),
                ['Content-Type' => 'text/plain'], '')
            )
        },
    );

OR, you can use a L<PSGI> app to handle the requests:

    use HTTP::Message::PSGI;
    Test::LWP::UserAgent->register_psgi('example.com' => sub {
        my $env = shift;
        # logic here...
        [ 200, [ 'Content-Type' => 'text/plain' ], [ 'some body' ] ],
    );

And then:

    # <something which calls the code being tested...>

    my $last_request = Test::LWP::UserAgent->last_http_request_sent;
    is($last_request->uri, 'http://example.com/success:3000', 'URI');
    is($last_request->content, 'a=1', 'POST content');

    # <now test that your code responded to the 200 response properly...>

One common mechanism to swap out the useragent implementation is via a
lazily-built Moose attribute; if no override is provided at construction time,
default to C<< LWP::UserAgent->new(%options) >>.

=head1 METHODS

All methods may be called on a specific object instance, or as a class method.
If called as on a blessed object, the action performed or data returned is
limited to just that object; if called as a class method, the action or data is
global.

=over

=item C<map_response($request_description, $http_response)>

With this method, you set up what L<HTTP::Response> should be returned for each
request received.

The request match specification can be described in multiple ways:

=over

=item string

The string is matched identically against the C<host> field of the L<URI> in the request.

Example:

    $test_ua->map_response('example.com', HTTP::Response->new(500));

=item regexp

The regexp is matched against the URI in the request.

Example:

    $test_ua->map_response(qr{foo/bar}, HTTP::Response->new(200));
    $test_ua->map_response(qr{baz/quux}, HTTP::Response->new(500));

=item code

An arbitrary coderef is passed a single argument, the L<HTTP::Request>, and
returns a boolean indicating if there is a match.

    $test_ua->map_response(sub {
            my $request = shift;
            return 1 if $request->method eq 'GET' || $request->method eq 'POST';
        },
        HTTP::Response->new(200),
    );

=item L<HTTP::Request> object

The L<HTTP::Request> object is matched identically (including all query
parameters, headers etc) against the provided object.

=back

The response can be represented either as a literal L<HTTP::Request> object, or
as a coderef that is run at the time of matching, with the request passed as
the single argument:

    HTTP::Response->new(...);

or

    sub {
        my $request = shift;
        HTTP::Response->new(...);
    }

Instance mappings take priority over global (class method) mappings - if no
matches are found from mappings added to the instance, the global mappings are
then examined. After no matches have been found, a 404 response is returned.

=item C<unmap_all(instance_only?)>

When called as a class method, removes all mappings set up globally (across all
objects). Mappings set up on an individual object will still remain.

When called as an object method, removes I<all> mappings both globally and on
this instance, unless a true value is passed as an argument, in which only
mappings local to the object will be removed. (Any true value will do, so you
can pass a meaningful string.)

=item C<register_psgi($domain, $app)>

Register a particular L<PSGI> app (code reference) to be used when requests
for a domain are received (matches are made exactly against
C<< $request->uri->host >>).  The request is passed to the C<$app> for processing,
and the L<PSGI> response is converted back to an L<HTTP::Response> (you must
already have loaded L<HTTP::Message::PSGI> or equivalent, as this is not done
for you).

You can also use C<register_psgi> with a regular expression as the first
argument, or any of the other forms used by C<map_response>, if you wish, as
calling C<< $test_ua->register_psgi($domain, $app) >> is equivalent to:

    $test_ua->map_response(
        $domain,
        sub { HTTP::Response->from_psgi($app->($_[0]->to_psgi)) },
    );

=item C<unregister_psgi($domain, instance_only?)>

When called as a class method, removes a domain->PSGI app entry that had been
registered globally.  Some mappings set up on an individual object may still
remain.

When called as an object method, removes a domain registration that was made
both globally and locally, unless a true value was passed as the second
argument, in which case only the registration local to the object will be
removed. This allows a different mapping made globally to take over.

If you want to mask a global registration on just one particular instance,
then add C<undef> as a mapping on your instance:

    $useragent->map_response($domain, undef);

=item C<last_http_request_sent>

The last L<HTTP::Request> object that this object (if called on an object) or
module (if called as a class method) processed, whether or not it matched a
mapping you set up earlier.

=item C<last_http_response_received>

The last L<HTTP::Response> object that this module returned, as a result of a
mapping you set up earlier with C<map_response>. You shouldn't normally need to
use this, as you know what you responded with - you should instead be testing
how your code reacted to receiving this response.

=item C<send_request($request)>

This is the only method from L<LWP::UserAgent> that has been overridden, which
processes the L<HTTP::Request>, sends to the network, then creates the
L<HTTP::Response> object from the reply received. Here, we loop through your
local and global domain registrations, and local and global mappings (in this
order) and returns the first match found; otherwise, a simple 404 response is
returned.

=back

All other methods from L<LWP::UserAgent> are available unchanged.

=head1 MOTIVATION

Most mock libraries on the CPAN use L<Test::MockObject>, which is widely considered
not good practice (among other things, C<@ISA> is violated, it requires
knowing far too much about the module's internals, and is very clumsy to work
with).

This module is a direct descendant of L<LWP::UserAgent>, exports nothing into
your namespace, and all access is via method calls, so it is fully inheritable
should you desire to add more features or override some bits of functionality.

(Aside from the constructor), it only overrides the one method in L<LWP::UserAgent> that issues calls to the
network, so real L<HTTP::Request> and L<HTTP::Headers> objects are used
throughout. It provides a method (C<last_http_request_sent>) to access the last
L<HTTP::Request>, for testing things like the URI and headers that your code
sent to L<LWP::UserAgent>.

=head1 TODO (possibly)

=over

=item Option to locally or globally override useragent implementations via
symbol table swap

=item Ability to route certain requests through the real network, to gain the
benefits of C<last_http_request_sent> and C<last_http_response_received>

=back

=head1 ACKNOWLEDGEMENTS

L<AirG Inc.|http://corp.airg.com>, my employer, and the first user of this distribution.

mst - Matt S. Trout <mst@shadowcat.co.uk>, for the better name of this
distribution, and for the PSGI registration concept.

Also Yury Zavarin, whose L<Test::Mock::LWP::Dispatch> inspired me to write this
module, and from where I borrowed some aspects of the API.

=head1 SEE ALSO

L<Test::Mock::LWP::Dispatch>

L<Test::Mock::LWP::UserAgent>

L<LWP::UserAgent>

L<PSGI>, L<HTTP::Message::PSGI>

=head1 COPYRIGHT

This software is copyright (c) 2012 by Karen Etheridge, <ether@cpan.org>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

