#!/usr/bin/env perl

# HTTP to HTTPS proxy server


use strict;
use warnings;

use App::http2http;


my $proxy = App::http2http->new;

$proxy->{filter} = sub {
    my ($self, $headers, $request) = @_;
    $request->uri->scheme('https');
};

$proxy->start;
