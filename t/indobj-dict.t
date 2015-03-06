use v6;
use Test;

plan 14;

use PDF::Tools::IndObj;
use PDF::Object :unbox, :box;
use PDF::Object::Dict;
use PDF::Grammar::Test :is-json-equiv;

sub ind-obj-tests( :$ind-obj!, :$class!, :$unboxed!) {
    my $dict-obj = PDF::Tools::IndObj.new( :$ind-obj );
    my $object = $dict-obj.object;
    isa_ok $object, $class;
    is $dict-obj.obj-num, $ind-obj[0], '$.obj-num';
    is $dict-obj.gen-num, $ind-obj[1], '$.gen-num';
    my $content = $dict-obj.content;
    isa_ok $content, Pair;
    isa_ok unbox( $content ), Hash, '$.content unboxed';
    is-json-equiv unbox( $content ), $unboxed, '$.content unboxed';
    is-json-equiv $dict-obj.ast, (:$ind-obj), 'ast regeneration';
}

ind-obj-tests(
    :ind-obj[ 21, 0, :dict{ D => :array[ :ind-ref[216, 0], :name<XYZ>, :int(0), :int(441), :null(Any)],
                            S => :name<GoTo>}],
    :class(PDF::Object::Dict),
    :unboxed{ :D[ :ind-ref[216, 0], "XYZ", 0, 441, Any], :S<GoTo> },
    );

ind-obj-tests(
    :ind-obj[29, 0, :dict{ P => :ind-ref[142, 0],
                           S => :name<Link>,
                           K => :array[ :ind-ref[207, 0],
                                        :dict{Type => :name<OBJR>,
                                              Pg => :ind-ref[216, 0],
                                              Obj => :ind-ref[233, 0]},
                               ]},
    ],
    :class(PDF::Object::Dict),
    :unboxed{ :P{ :ind-ref[ 142, 0 ] },
              :S<Link>,
              :K[ :ind-ref[ 207, 0 ],
                  { :Type<OBJR>,
                    :Pg{ :ind-ref[ 216, 0 ] },
                    :Obj{ :ind-ref[ 233, 0 ] },
                  }
                  ] },
    );