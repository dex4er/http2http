#!/usr/bin/perl

use HTTP::Proxy ':log';
use HTTP::Proxy::HeaderFilter::simple;

my $proxy = HTTP::Proxy->new(
    port => 8080,
    logmask => STATUS | PROCESS,
);

$proxy->push_filter(
    mime => '*/*',
    request => HTTP::Proxy::HeaderFilter::simple->new(
        sub {
            my ($self, $headers, $message) = @_;

            my $uri = $message->uri;
            $uri->scheme("https");
        }
    ),
);

$proxy->start;
