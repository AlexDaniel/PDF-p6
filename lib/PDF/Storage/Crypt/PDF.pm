use v6;

use PDF::Storage::Crypt::AST;

class PDF::Storage::Crypt::PDF
    does PDF::Storage::Crypt::AST {
    use PDF::Storage::Crypt;
    use PDF::Storage::Crypt::RC4;
    use PDF::Storage::Crypt::AES;

    has PDF::Storage::Crypt $!stm-f; #| stream filter (/StmF)
    has PDF::Storage::Crypt $!str-f; #| string filter (/StrF)

    submethod TWEAK(:$doc!, Str :$owner-pass, |c) {
        $owner-pass
            ?? self!generate( :$doc, :$owner-pass, |c)
            !! self!load( :$doc, |c)
    }

    #| generate encryption
    submethod !generate( Hash :$doc!, Bool :$aes, UInt :$V = $aes ?? 4 !! 3, |c ) {
        my $class = $aes
            ?? PDF::Storage::Crypt::AES
            !! PDF::Storage::Crypt::RC4;
        die "/V 4 is required for AES encryption"
            if $aes && $V < 4;
        $!stm-f = $class.new( :$doc, :$V, |c );
        $!str-f := $!stm-f;
    }

    method !v4-crypt( Hash $doc, PDF::DAO::Type::Encrypt $encrypt, Str $cf-entry, |c) {
        return Nil
            if $cf-entry eq 'Identity';

        my Hash \CF = $encrypt.CF{$cf-entry};
        my Str \CFM = CF<CFM> // 'None';
        my $class = do given CFM {
            when 'V2'    { PDF::Storage::Crypt::RC4 }
            when 'AESV2' { PDF::Storage::Crypt::AES }
            when 'None' {
                die "Security handlers are NYI";
            }
            default {
                die "Encryption scheme /$cf-entry /CFM is not 'V2', 'AESV2', or 'None': $_";
            }
        };
        $class.new( :$doc, |$encrypt, |CF, |c );
    }
        
    #| read existing encryption
    submethod !load( Hash :$doc!, |c ) is default {
	die "document is not encrypted"
            unless $doc<Encrypt>:exists;

        die 'This PDF lacks an ID.  The document cannot be decrypted'
	    unless $doc<ID>;

        my $encrypt = $doc<Encrypt>;
        PDF::DAO.delegator.coerce($encrypt, PDF::DAO::Type::Encrypt);
        
	given $encrypt.V {
	    when 1..3 {
                # stream and string channels are identical
                $!stm-f := PDF::Storage::Crypt::RC4.new( :$doc, |$encrypt, |c );
                $!str-f := $!stm-f;
	    }
            when 4 {
                # Determined by /CF /StmF and /StrF entries
                my $stmf = $encrypt.StmF // 'Identity';
                my $strf = $encrypt.StrF // 'Identity';
                $!stm-f = self!v4-crypt( $doc, $encrypt, $stmf, |c);
                $!str-f = $stmf eqv $strf
                    ?? $!stm-f
                    !! self!v4-crypt( $doc, $encrypt, $strf, |c)
            }
	    default {
		die "unsupported encryption version: $_";
	    }
	}
    }

    multi method crypt(Str $v, :$key! where 'hex-string' | 'literal', |c) {
        with $!str-f { .crypt($v, |c) } else { $v }
    }

    multi method crypt($v, |c) is default {
        with $!stm-f { .crypt($v, |c) } else { $v }
    }

    method authenticate( $pass ) {
        .authenticate($pass) with $!str-f;
        unless $!str-f === $!stm-f {
            .authenticate($pass) with $!stm-f
        }
    }

    method is-owner {
        for $!stm-f, $!str-f {
            return False if .defined && ! .is-owner;
        }
        True;
    }

}
