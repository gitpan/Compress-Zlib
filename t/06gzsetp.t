
use lib 't';
use strict;
local ($^W) = 1; #use warnings;
# use bytes;
 
use Test::More ;
use MyTestUtils;
 
use Compress::Zlib 2 ;

use IO::Gzip ;
use IO::Gunzip ;

use IO::Deflate ;
use IO::Inflate ;

use IO::RawDeflate ;
use IO::RawInflate ;

use vars qw($extra);

 
BEGIN 
{ 
    # use Test::NoWarnings, if available
    $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };
}

my $ver = Compress::Zlib::zlib_version();
plan skip_all => "gzsetparams needs zlib 1.0.6 or better. You have $ver\n"
    if ZLIB_VERNUM() < 0x1060 ;

plan tests => 51 + $extra ;

# Check zlib_version and ZLIB_VERSION are the same.
is Compress::Zlib::zlib_version, ZLIB_VERSION,
    "ZLIB_VERSION matches Compress::Zlib::zlib_version" ;
 
{
    # gzsetparams
    title "Testing gzsetparams";

    my $hello = "I am a HAL 9000 computer" x 2001 ;
    my $len_hello = length $hello ;
    my $goodbye = "Will I dream?" x 2010;
    my $len_goodbye = length $goodbye;

    my ($input, $err, $answer, $X, $status, $Answer);
     
    my $name = "test.gz" ;
    unlink $name ;
    ok my $x = gzopen($name, "wb");

    $input .= $hello;
    is $x->gzwrite($hello), $len_hello, "gzwrite returned $len_hello" ;
    
    # Error cases
    eval { $x->gzsetparams() };
    like $@, mkErr('^Usage: Compress::Zlib::gzFile::gzsetparams\(file, level, strategy\)');

    # Change both Level & Strategy
    $status = $x->gzsetparams(Z_BEST_SPEED, Z_HUFFMAN_ONLY) ;
    cmp_ok $status, '==', Z_OK, "status is Z_OK";
    
    $input .= $goodbye;
    is $x->gzwrite($goodbye), $len_goodbye, "gzwrite returned $len_goodbye" ;
    
    ok ! $x->gzclose, "closed" ;

    ok my $k = gzopen($name, "rb") ;
     
    # calling gzsetparams on reading is not allowed.
    $status = $k->gzsetparams(Z_BEST_SPEED, Z_HUFFMAN_ONLY) ;
    cmp_ok $status, '==', Z_STREAM_ERROR, "status is Z_STREAM_ERROR" ;

    my $len = length $input ;
    my $uncompressed;
    is $len, $k->gzread($uncompressed, $len) ;

    ok $uncompressed eq  $input ;
    ok $k->gzeof ;
    ok ! $k->gzclose ;
    ok $k->gzeof  ;
    unlink $name;
}


foreach my $CompressClass ('IO::Gzip',
                           'IO::Deflate',
                           'IO::RawDeflate',
                          )
{
    my $UncompressClass = getInverse($CompressClass);

    title "Testing $CompressClass";


    # deflateParams

    my $hello = "I am a HAL 9000 computer" x 2001 ;
    my $len_hello = length $hello ;
    my $goodbye = "Will I dream?" x 2010;
    my $len_goodbye = length $goodbye;

    #my ($input, $err, $answer, $X, $status, $Answer);
    my $compressed;

    ok my $x = new $CompressClass(\$compressed) ;

    my $input .= $hello;
    is $x->write($hello), $len_hello ;
    
    # Change both Level & Strategy
    ok $x->deflateParams(Z_BEST_SPEED, Z_HUFFMAN_ONLY);

    $input .= $goodbye;
    is $x->write($goodbye), $len_goodbye ;
    
    ok $x->close ;

    ok my $k = new $UncompressClass(\$compressed);
     
    my $len = length $input ;
    my $uncompressed;
    is $k->read($uncompressed, $len), $len 
       or diag "$IO::Gunzip::GunzipError" ;

    ok $uncompressed eq  $input ;
    ok $k->eof ;
    ok $k->close ;
    ok $k->eof  ;
}