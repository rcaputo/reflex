#!/usr/bin/env perl
# vim: ts=2 sw=2 noexpandtab

use Moose;
use Reflex::Decoder::Line;

use constant NEWLINE => '<nl>';

my $decoder = Reflex::Decoder::Line->new( newline => NEWLINE );
$decoder->push_stream("test ", "line ", "one", NEWLINE);
$decoder->push_stream("test ", "line ", "two", NEWLINE);

# Fails because you can't push a mix of datagrams and streams onto a
# streams-only decoder.
#$decoder->push_datagram("datagram one", "datagram two", NEWLINE);

$decoder->push_stream("test ", "line ", "three", NEWLINE);
$decoder->push_stream("test ", "line ", "four", NEWLINE);

$decoder->push_eof();

use YAML; print YAML::Dump($decoder);
while (my $next = $decoder->shift()) {
	use YAML; print YAML::Dump($next);
}

__END__

% perl -I../lib eg-02-encoding.pl
--- !!perl/hash:Reflex::Decoder::Line
messages:
	- !!perl/hash:Reflex::Codec::Message::Stream
		is_combinable: 1
		octets: 'test line one<nl>test line two<nl>test line three<nl>test line four<nl>'
		priority: 500
	- !!perl/hash:Reflex::Codec::Message::Eof
		is_combinable: 0
		priority: 500
newline: '<nl>'
--- !!perl/hash:Reflex::Codec::Message::Datagram
is_combinable: 0
octets: test line one
priority: 500
--- !!perl/hash:Reflex::Codec::Message::Datagram
is_combinable: 0
octets: test line two
priority: 500
--- !!perl/hash:Reflex::Codec::Message::Datagram
is_combinable: 0
octets: test line three
priority: 500
--- !!perl/hash:Reflex::Codec::Message::Datagram
is_combinable: 0
octets: test line four
priority: 500
--- !!perl/hash:Reflex::Codec::Message::Eof
is_combinable: 0
priority: 500
