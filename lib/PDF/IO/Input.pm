use v6;

class PDF::IO::Input {
    # a poor man's polymorphism: allow pdf input from IO handles or strings
    # could be obseleted by cat-strings, when available
    has Str $.path is rw;

    proto method coerce( $value ) returns PDF::IO::Input {*}

    multi method coerce( PDF::IO::Input $value!, :$path ) {
        # don't recoerce
        $value.path = $_ with $path;
        $value;
    }

    multi method coerce( IO::Path $value, |c ) {
	self.coerce( $value.open( :enc<latin-1>, |c ) );
    }

    multi method coerce( IO::Handle $value!, |c ) {
        require PDF::IO::Input::IOH;
        ::('PDF::IO::Input::IOH').bless( :$value, |c );
    }

    multi method coerce( Str $value! where { !.isa(PDF::IO::Input) }, |c) {
        require PDF::IO::Input::Str;
        ::('PDF::IO::Input::Str').bless( :$value, |c );
    }

    multi method stream-data( Array :$ind-obj! ) {
        $.stream-data( |$ind-obj[2] );
    }
    multi method stream-data( Hash :$stream! ) is default {
        $stream<encoded>
    }

}