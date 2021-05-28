use strict;
use warnings;
use Path::Tiny qw( path );
use lib path(__FILE__)->parent->child('lib')->stringify;
use Greet;

print greet("Perl!"), "\n";
