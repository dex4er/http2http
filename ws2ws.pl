#!/usr/bin/env perl

# WS to WS router proxy server


use strict;
use warnings;

use App::http2http;


sub usage {
    die "Usage: $0 endpoint_hostport default_hostport\n";
};


my $proxy = App::http2http->new;

my $endpoint_hostport = $proxy->{argv}->[0] || usage;
my $default_hostport = $proxy->{argv}->[1] || usage;

$proxy->{filter} = sub {
    my ($self, $headers, $request) = @_;
    my $endpoint = $headers->header('X-EndPoint-URL');
    if ($endpoint) {
        $request->uri->host_port($endpoint_hostport);
    }
    else {
        $request->uri->host_port($default_hostport);
    };
};

$proxy->start;
