#!/usr/bin/env perl

# WS to HTTPS proxy server


use strict;
use warnings;

use App::http2http;


sub usage {
    die "Usage: $0\n";
};


my $proxy = App::http2http->new;

$proxy->{filter} = sub {
    my ($self, $headers, $request) = @_;
    my $endpoint = $headers->header('X-EndPoint-URL');
    if ($endpoint) {
        $endpoint->scheme('https');
        $request->uri($endpoint);
        $headers->remove_header('X-EndPoint-URL');
    };
};

$proxy->start;
