
use Compress::Zlib ;

sub ok
{
    my ($no, $ok) = @_ ;

    #++ $total ;
    #++ $totalBad unless $ok ;

    print "ok $no\n" if $ok ;
    print "not ok $no\n" unless $ok ;
}


$hello = <<EOM ;
hello world
this is a test
EOM

$len   = length $hello ;

print "1..130\n" ;

# Check zlib_version and ZLIB_VERSION are the same.
ok(1, Compress::Zlib::zlib_version eq ZLIB_VERSION) ;

# gzip tests
#===========

$name = "test.gz" ;

ok(2, $fil = gzopen($name, "wb")) ;

ok(3, $fil->gzwrite($hello) == $len) ;

ok(4, ! $fil->gzclose ) ;

ok(5, $fil = gzopen($name, "rb") ) ;

ok(6, ($x = $fil->gzread($uncomp)) == $len) ;

ok(7, ! $fil->gzclose ) ;

unlink $name ;

ok(8, $hello eq $uncomp) ;

# now a bigger gzip test

$text = 'text' ;
$file = "$text.gz" ;

ok(9, $f = gzopen($file, "wb")) ;

# generate a long random string
$contents = '' ;
foreach (1 .. 5000)
  { $contents .= chr int rand 255 }

$len = length $contents ;

ok(10, $f->gzwrite($contents) == $len ) ;

ok(11, ! $f->gzclose );

ok(12, $f = gzopen($file, "rb")) ;
 
ok(13, $f->gzread($uncompressed, $len) == $len) ;

ok(14, $contents eq $uncompressed) ;

ok(15, ! $f->gzclose ) ;

unlink($file) ;

# gzip - readline tests
# ======================

# first create a small gzipped text file
$name = "test.gz" ;
@text = (<<EOM, <<EOM, <<EOM, <<EOM) ;
this is line 1
EOM
the second line
EOM
the line after the previous line
EOM
the final line
EOM

$text = join("", @text) ;

ok(16, $fil = gzopen($name, "wb")) ;
ok(17, $fil->gzwrite($text) == length $text) ;
ok(18, ! $fil->gzclose ) ;

# now try to read it back in
ok(19, $fil = gzopen($name, "rb")) ;
$aok = 1 ; 
$remember = '';
$line = '';
$lines = 0 ;
while ($fil->gzreadline($line) > 0) {
    ($aok = 0), last
	if $line ne $text[$lines] ;
    $remember .= $line ;
    ++ $lines ;
}
ok(20, $aok) ;
ok(21, $remember eq $text) ;
ok(22, $lines == @text) ;
ok(23, ! $fil->gzclose ) ;
unlink($name) ;

# a text file with a very long line (bigger than the internal buffer)
$line1 = ("abcdefghijklmnopq" x 2000) . "\n" ;
$line2 = "second line\n" ;
$text = $line1 . $line2 ;
ok(24, $fil = gzopen($name, "wb")) ;
ok(25, $fil->gzwrite($text) == length $text) ;
ok(26, ! $fil->gzclose ) ;

# now try to read it back in
ok(27, $fil = gzopen($name, "rb")) ;
$i = 0 ;
while ($fil->gzreadline($line) > 0) {
    $got[$i] = $line ;    
    ++ $i ;
}
ok(28, $i == 2) ;
ok(29, $got[0] eq $line1 ) ;
ok(30, $got[1] eq $line2) ;

ok(31, ! $fil->gzclose ) ;

unlink $name ;

# a text file which is not termined by an EOL

$line1 = "hello hello, I'm back again\n" ;
$line2 = "there is no end in sight" ;

$text = $line1 . $line2 ;
ok(32, $fil = gzopen($name, "wb")) ;
ok(33, $fil->gzwrite($text) == length $text) ;
ok(34, ! $fil->gzclose ) ;

# now try to read it back in
ok(35, $fil = gzopen($name, "rb")) ;
@got = () ; $i = 0 ;
while ($fil->gzreadline($line) > 0) {
    $got[$i] = $line ;    
    ++ $i ;
}
ok(36, $i == 2) ;
ok(37, $got[0] eq $line1 ) ;
ok(38, $got[1] eq $line2) ;

ok(39, ! $fil->gzclose ) ;

unlink $name ;


# mix gzread and gzreadline <

# case 1: read a line, then a block. The block is
#         smaller than the internal block used by
#	  gzreadline
$line1 = "hello hello, I'm back again\n" ;
$line2 = "abc" x 200 ; 
$line3 = "def" x 200 ;

$text = $line1 . $line2 . $line3 ;
ok(40, $fil = gzopen($name, "wb")) ;
ok(41, $fil->gzwrite($text) == length $text) ;
ok(42, ! $fil->gzclose ) ;

# now try to read it back in
ok(43, $fil = gzopen($name, "rb")) ;
ok(44, $fil->gzreadline($line) > 0) ;
ok(45, $line eq $line1) ;
ok(46, $fil->gzread($line, length $line2) > 0) ;
ok(47, $line eq $line2) ;
ok(48, $fil->gzread($line, length $line3) > 0) ;
ok(49, $line eq $line3) ;
ok(50, ! $fil->gzclose ) ;
unlink $name ;

# change $/ <<TODO

# gzip - filehandle tests
# ========================

{
  use IO::File ;
  my $filename = "fh.gz" ;
  my $hello = "hello, hello, I'm back again" ;
  my $len = length $hello ;

  my $f = new IO::File ">$filename" ;
  binmode $f ; # for OS/2

  ok(51, $f) ;

  print $f "first line\n" ;
  
  ok(52, $fil = gzopen($f, "wb")) ;
 
  ok(53, $fil->gzwrite($hello) == $len) ;
 
  ok(54, ! $fil->gzclose ) ;

 
  ok(55, my $g = new IO::File "<$filename") ;
  binmode $g ; # for OS/2
 
  my $first = <$g> ;

  ok(56, $first eq "first line\n") ;

  ok(57, $fil = gzopen($g, "rb") ) ;
  ok(58, ($x = $fil->gzread($uncomp)) == $len) ;
 
  ok(59, ! $fil->gzclose ) ;
 
  unlink $filename ;
 
  ok(60, $hello eq $uncomp) ;

}

{
  my $filename = "fh.gz" ;
  my $hello = "hello, hello, I'm back again" ;
  my $len = length $hello ;
  local (*FH1) ;
  local (*FH2) ;
 
  ok(61, open FH1, ">$filename") ;
  binmode FH1; # for OS/2
 
  print FH1 "first line\n" ;
 
  ok(62, $fil = gzopen(\*FH1, "wb")) ;
 
  ok(63, $fil->gzwrite($hello) == $len) ;
 
  ok(64, ! $fil->gzclose ) ;
 
 
  ok(65, my $g = open FH2, "<$filename") ;
  binmode FH2; # for OS/2
 
  my $first = <FH2> ;
 
  ok(66, $first eq "first line\n") ;
 
  ok(67, $fil = gzopen(*FH2, "rb") ) ;
  ok(68, ($x = $fil->gzread($uncomp)) == $len) ;
 
  ok(69, ! $fil->gzclose ) ;
 
  unlink $filename ;
 
  ok(70, $hello eq $uncomp) ;
 
}


# compress/uncompress tests
# =========================

$hello = "hello mum" ;

$compr = compress($hello) ;
ok(71, $compr ne "") ;


$uncompr = uncompress ($compr) ;

ok(72, $hello eq $uncompr) ;


# bigger compress

$compr = compress ($contents) ;
ok(73, $compr ne "") ;

$uncompr = uncompress ($compr) ;

ok(74, $contents eq $uncompr) ;

# buffer reference

$compr = compress(\$hello) ;
ok(75, $compr ne "") ;


$uncompr = uncompress (\$compr) ;
ok(76, $hello eq $uncompr) ;

# deflate/inflate - small buffer
# ==============================

$hello = "I am a HAL 9000 computer" ;
@hello = split('', $hello) ;
 
ok(77,  ($x, $err) = deflateInit( {-Bufsize => 1} ) ) ;
ok(78, $x) ;
ok(79, $err == Z_OK) ;
 
$Answer = '';
foreach (@hello)
{
    ($X, $status) = $x->deflate($_) ;
    last unless $status == Z_OK ;

    $Answer .= $X ;
}
 
ok(80, $status == Z_OK) ;

ok(81,    (($X, $status) = $x->flush())[1] == Z_OK ) ;
$Answer .= $X ;
 
 
@Answer = split('', $Answer) ;
 
ok(82, ($k, $err) = inflateInit( {-Bufsize => 1}) ) ;
ok(83, $k) ;
ok(84, $err == Z_OK) ;
 
$GOT = '';
foreach (@Answer)
{
    ($Z, $status) = $k->inflate($_) ;
    $GOT .= $Z ;
    last if $status == Z_STREAM_END or $status != Z_OK ;
 
}
 
ok(85, $status == Z_STREAM_END) ;
ok(86, $GOT eq $hello ) ;


 
# deflate/inflate - larger buffer
# ==============================


ok(87, $x = deflateInit() ) ;
 
ok(88, (($X, $status) = $x->deflate($contents))[1] == Z_OK) ;

$Y = $X ;
 
 
ok(89, (($X, $status) = $x->flush() )[1] == Z_OK ) ;
$Y .= $X ;
 
 
 
ok(90, $k = inflateInit() ) ;
 
($Z, $status) = $k->inflate($Y) ;
 
ok(91, $status == Z_STREAM_END) ;
ok(92, $contents eq $Z ) ;

# deflate/inflate - preset dictionary
# ===================================

$dictionary = "hello" ;
ok(93, $x = deflateInit({-Level => Z_BEST_COMPRESSION,
			 -Dictionary => $dictionary})) ;
 
$dictID = $x->dict_adler() ;

($X, $status) = $x->deflate($hello) ;
ok(94, $status == Z_OK) ;
($Y, $status) = $x->flush() ;
ok(95, $status == Z_OK) ;
$X .= $Y ;
$x = 0 ;
 
ok(96, $k = inflateInit(-Dictionary => $dictionary) ) ;
 
($Z, $status) = $k->inflate($X);
ok(97, $status == Z_STREAM_END) ;
ok(98, $k->dict_adler() == $dictID);
ok(99, $hello eq $Z ) ;

##ok(76, $k->inflateSetDictionary($dictionary) == Z_OK);
# 
#$Z='';
#while (1) {
#    ($Z, $status) = $k->inflate($X) ;
#    last if $status == Z_STREAM_END or $status != Z_OK ;
#print "status=[$status] hello=[$hello] Z=[$Z]\n";
#}
#ok(77, $status == Z_STREAM_END) ;
#ok(78, $hello eq $Z ) ;
#print "status=[$status] hello=[$hello] Z=[$Z]\n";
#
#
## all done.
#
#
#


# inflate - check remaining buffer after Z_STREAM_END
# ===================================================
 
{
    ok(100, $x = deflateInit(-Level => Z_BEST_COMPRESSION )) ;
 
    ($X, $status) = $x->deflate($hello) ;
    ok(101, $status == Z_OK) ;
    ($Y, $status) = $x->flush() ;
    ok(102, $status == Z_OK) ;
    $X .= $Y ;
    $x = 0 ;
 
    ok(103, $k = inflateInit() ) ;
 
    my $first = substr($X, 0, 2) ;
    my $last  = substr($X, 2) ;
    ($Z, $status) = $k->inflate($first);
    ok(104, $status == Z_OK) ;
    ok(105, $first eq "") ;

    $last .= "appendage" ;
    ($T, $status) = $k->inflate($last);
    ok(106, $status == Z_STREAM_END) ;
    ok(107, $hello eq $Z . $T ) ;
    ok(108, $last eq "appendage") ;

}

# minGzip
{
    my $name = "test.gz" ;
    my $buffer = <<EOM;
some sample 
text

EOM

    my $len = length $buffer ;
    my ($x, $uncomp) ;


    # create an in-memory gzip file
    my $dest = Compress::Zlib::memGzip($buffer) ;
    ok(109, length $dest) ;

    # write it to disk
    ok(110, open(FH, ">$name")) ;
    print FH $dest ;
    close FH ;

    # uncompress with gzopen
    ok(111, my $fil = gzopen($name, "rb") ) ;
 
    ok(112, ($x = $fil->gzread($uncomp)) == $len) ;
 
    ok(113, ! $fil->gzclose ) ;

    ok(114, $uncomp eq $buffer) ;
 
    unlink $name ;
 
    # now do the same but use a reference 

    $dest = Compress::Zlib::memGzip(\$buffer) ; 
    ok(115, length $dest) ;

    # write it to disk
    ok(116, open(FH, ">$name")) ;
    print FH $dest ;
    close FH ;

    # uncompress with gzopen
    ok(117, $fil = gzopen($name, "rb") ) ;
 
    ok(118, ($x = $fil->gzread($uncomp)) == $len) ;
 
    ok(119, ! $fil->gzclose ) ;

    ok(120, $uncomp eq $buffer) ;
 
    unlink $name ;
}

{

    # Check - MAX_WBITS
    # =================
    
    $hello = "Test test test test test";
    @hello = split('', $hello) ;
     
    ok(121,  ($x, $err) = deflateInit( -Bufsize => 1, -WindowBits => -MAX_WBITS() ) ) ;
    ok(122, $x) ;
    ok(123, $err == Z_OK) ;
     
    $Answer = '';
    foreach (@hello)
    {
        ($X, $status) = $x->deflate($_) ;
        last unless $status == Z_OK ;
    
        $Answer .= $X ;
    }
     
    ok(124, $status == Z_OK) ;
    
    ok(125,    (($X, $status) = $x->flush())[1] == Z_OK ) ;
    $Answer .= $X ;
     
     
    @Answer = split('', $Answer) ;
    # Undocumented corner -- extra byte needed to get inflate to return 
    # Z_STREAM_END when done.  
    push @Answer, " " ; 
     
    ok(126, ($k, $err) = inflateInit(-Bufsize => 1, -WindowBits => -MAX_WBITS()) ) ;
    ok(127, $k) ;
    ok(128, $err == Z_OK) ;
     
    $GOT = '';
    foreach (@Answer)
    {
        ($Z, $status) = $k->inflate($_) ;
        $GOT .= $Z ;
        last if $status == Z_STREAM_END or $status != Z_OK ;
     
    }
     
    ok(129, $status == Z_STREAM_END) ;
    ok(130, $GOT eq $hello ) ;
    
}
