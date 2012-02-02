#!/usr/bin/env perl -c

package App::http2http;

=head1 NAME

App::http2http - generic HTTP proxy server with logging

=cut


use strict;
use warnings;

our $VERSION = '0.01';


use Log::Log4perl;

use App::http2http::Proxy;

use HTTP::Proxy ':log';
use HTTP::Proxy::HeaderFilter::simple;
use HTTP::Proxy::BodyFilter::simple;
use HTTP::Proxy::BodyFilter::complete;

use constant::boolean;


sub new {
    my ($class, %args) = @_;

    my $conf = q(
        log4perl.logger                     = DEBUG, Logfile
        log4perl.appender.Logfile           = Log::Dispatch::File::Stamped
        log4perl.appender.Logfile.stamp_fmt = %Y-%m-%d-%H
        log4perl.appender.Logfile.filename  = http2http.log
        log4perl.appender.Logfile.layout    = PatternLayout
        log4perl.appender.Logfile.layout.ConversionPattern = %d{ISO8601}: %c: %m{chomp}%n
    );

    Log::Log4perl->init( \$conf );

    return bless {
        filter => sub { },
        %args,
    } => $class;
};


sub start {
    my ($self) = @_;

    my $proxy = App::http2http::Proxy->new(
        host => '127.0.0.1',
        port => 8080,
        logmask => PROCESS | SOCKET | STATUS | DATA,
        %$self,
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

    $proxy->push_filter(
        mime => '*/*',
        request => HTTP::Proxy::HeaderFilter::simple->new(
            $self->{filter}
        ),
    );

    $proxy->start;
};


=head1 SEE ALSO

L<HTTP::Proxy>.

=head1 BUGS

If you find the bug or want to implement new features, please report it at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-http2http>

=for readme continue

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 COPYRIGHT

Copyright (C) 2012 by Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>
