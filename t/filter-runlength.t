use Test;
# this test based on PDF-API2/t/filter-runlengthdecode.t
plan 7;

use PDF::Basic::Filter::RunLength;
use PDF::Basic::Filter;

my $in = '--- Look at this test string. ---';
my $out = "\x[fe]-\x01 L\xffo\x16k at this test string. \xfe-";
my $filter = PDF::Basic::Filter::RunLength.new;

is_deeply $filter.encode($in),
   $out,
   q{RunLength test string is encoded correctly};

is_deeply $filter.decode($out),
   $in,
   q{RunLength test string is decoded correctly};

dies_ok { $filter.decode($out, :eod) },
    q{RunLength missing EOD marker is handled correctly};

my %dict = :Filter<RunLengthDecode>;

is(PDF::Basic::Filter.decode($out, :%dict),
   $in,
   q{ASCIIHex test string is decoded correctly});

is(PDF::Basic::Filter.encode($in, :%dict),
   $out,
   q{ASCIIHex test string is encoded correctly});

# Add the end-of-document marker
$out ~= "\x80";

is $filter.encode($in, :eod),
   $out,
   q{RunLength test string with EOD marker is encoded correctly};

is $filter.decode($out, :eod),
   $in,
   q{RunLength test string with EOD marker is decoded correctly};
