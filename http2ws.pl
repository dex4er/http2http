#!/usr/bin/env perl

# HTTP to WS router proxy server


use strict;
use warnings;

use App::http2http;


sub usage {
    die "Usage: $0 endpoint_url no_proxy\n";
};


my $proxy = App::http2http->new;

my $endpoint_url = $proxy->{argv}->[0] || usage;
my $no_proxy = $proxy->{argv}->[1] || '';

my $endpoint_uri = URI->new($endpoint_url);
my %no_proxy_list = map { $_ => 1 } split ',', $no_proxy;

$proxy->{filter} = sub {
    my ($self, $headers, $request) = @_;
    my $uri = $request->uri;
    if (not $no_proxy_list{$uri->host}) { 
        $headers->header('X-EndPoint-URL' => $uri->as_string);
        $request->uri($endpoint_uri);
        $headers->header('Host' => $endpoint_uri->host_port);
    };
};

$proxy->start;
