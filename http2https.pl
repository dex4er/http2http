#!/usr/bin/env perl

# HTTP to HTTPS proxy server
#
# Usage:
#   http2https.pl [host:port]

use strict;
use warnings;

use constant SERVER_PORT => 8080;

use HTTP::Proxy ':log';
use HTTP::Proxy::HeaderFilter::simple;
use HTTP::Proxy::BodyFilter::simple;
use HTTP::Proxy::BodyFilter::complete;

use constant::boolean;


my ($host, $port) = split /:/, $ARGV[0] if $ARGV[0];

my $proxy = HTTP::Proxy->new(
    host => $host || '127.0.0.1',
    port => $port || SERVER_PORT,
    logmask => PROCESS | SOCKET | STATUS | DATA,
    via => undef,
    x_forwarded_for => undef,
);

$proxy->push_filter(
    mime => '*/*',
    request => HTTP::Proxy::HeaderFilter::simple->new(
        sub {
            my ($self, $headers, $request) = @_;
            my $uri = $request->uri;
            #$uri->scheme("https");
        }
    ),
);

$proxy->push_filter(
    mime => '*/*',
    request => HTTP::Proxy::HeaderFilter::simple->new(
        sub {
            my ($self, $headers, $request) = @_;
            my $content = $request->content;
            $content =~ s/\n/ /sg;
            my $uri = $request->uri;
            $proxy->log(DATA, 'REQUEST', sprintf '%s:%s|%s %s|%s|%s',
                $proxy->client_socket->peerhost, $proxy->client_socket->peerport,
                $request->method, $uri->as_string, $request->headers->as_string('|'), $content);
        }
    ),
    response => HTTP::Proxy::BodyFilter::complete->new,
    response => HTTP::Proxy::BodyFilter::simple->new(
        sub {
            my ($self, $dataref, $response, $protocol, $buffer) = @_;
            return if defined $buffer;
            my $content = $$dataref;
            $content =~ s/\n/ /sg;
            $proxy->log(DATA, 'RESPONSE', sprintf '%s:%s|%s|%s|%s',
                $proxy->client_socket->peerhost, $proxy->client_socket->peerport,
                $response->status_line, $response->headers->as_string('|'), $content);
        }
    ),
);

$proxy->start;
