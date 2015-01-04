#!/usr/bin/env perl6

use Test;
use JSON::Tiny;

use PDF::Grammar::PDF;
use PDF::Grammar::PDF::Actions;
use PDF::Grammar::Test;
use PDF::Core;

my $actions = PDF::Grammar::PDF::Actions.new();

for 't/pdf'.IO.dir.list {

    next unless / [\w|'-']*? '.json'$/;
    my $json-file = ~$_;
    my %pdf-data = %( from-json( $json-file.IO.slurp ) );

    my $pdf-input-file = $json-file.subst( /'.json'$/, '.in' );
    my $pdf-output-file = $json-file.subst( /'.json'$/, '.out' );
    my $pdf-input = $pdf-input-file.IO.slurp;

    my $pdf = PDF::Core.new( :root(%pdf-data), :input($pdf-input) );
    %pdf-data<offset> = 0;
    my $pdf-output = $pdf.write( |%pdf-data );
    $pdf-output-file.IO.spurt: $pdf-output;
    %pdf-data<offset>:delete;

    my ($rule) = %pdf-data.keys;
    my %expected = ast => %pdf-data;
    my $class = PDF::Grammar::PDF;

    PDF::Grammar::Test::parse-tests($class, $pdf-input, :$rule, :$actions, :suite("[$pdf-input-file]"), :%expected );
    PDF::Grammar::Test::parse-tests($class, $pdf-output, :$rule, :$actions, :suite("[$pdf-output-file]"), :%expected );

}

done;
