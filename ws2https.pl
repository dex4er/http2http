#!/usr/bin/env perl

# WS to HTTPS proxy server


use strict;
use warnings;

use App::http2http;


my $proxy = App::http2http->new;

$proxy->{filter} = sub {
    my ($self, $headers, $request) = @_;
    my $endpoint = $headers->header('X-EndPoint-URL');
    if ($endpoint) {
        $request->uri($endpoint);
        $headers->remove_header('X-EndPoint-URL');
    };
    $request->uri->scheme('https');
};

$proxy->start;
