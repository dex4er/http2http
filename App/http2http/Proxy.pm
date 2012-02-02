#!/usr/bin/env perl -c

package App::http2http::Proxy;

=head1 NAME

App::http2http::Proxy - wrapper for HTTP::Proxy with log4perl logger

=cut


use strict;
use warnings;

our $VERSION = '0.01';


use Log::Log4perl qw(:levels get_logger);

use HTTP::Proxy ':log';

use base 'HTTP::Proxy';


sub log {
    my $self  = shift;
    my $level = shift;

    return unless $self->logmask & $level || $level == ERROR;

    my $category = shift;

    my $logger = get_logger($category);

    my $message = join '', @_;
    $message =~ s/\015?\012/ /gs;

    $logger->log($level == ERROR ? $ERROR : $INFO, $message);
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
