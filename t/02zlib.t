

use strict ;
local ($^W) = 1; #use warnings ;

use Compress::Zlib ;

sub ok
{
    my ($no, $ok) = @_ ;

    #++ $total ;
    #++ $totalBad unless $ok ;

    print "ok $no\n" if $ok ;
    print "not ok $no\n" unless $ok ;
}

sub readFile
{
    my ($filename) = @_ ;
    my ($string) = '' ;
 
    open (F, "<$filename")
        or die "Cannot open $filename: $!\n" ;
    binmode(F);
    while (<F>)
      { $string .= $_ }
    close F ;
    $string ;
}     

my $hello = <<EOM ;
hello world
this is a test
EOM

my $len   = length $hello ;


print "1..230\n" ;

# Check zlib_version and ZLIB_VERSION are the same.
ok(1, Compress::Zlib::zlib_version eq ZLIB_VERSION) ;

# gzip tests
#===========

my $name = "test.gz" ;
my ($x, $uncomp) ;

ok(2, my $fil = gzopen($name, "wb")) ;

ok(3, $fil->gzwrite($hello) == $len) ;

ok(4, ! $fil->gzclose ) ;

ok(5, $fil = gzopen($name, "rb") ) ;

ok(6, ($x = $fil->gzread($uncomp)) == $len) ;

ok(7, ! $fil->gzclose ) ;

unlink $name ;

ok(8, $hello eq $uncomp) ;

# check that a number can be gzipped
my $number = 7603 ;
my $num_len = 4 ;

ok(9, $fil = gzopen($name, "wb")) ;

ok(10, $fil->gzwrite($number) == $num_len) ;

ok(11, ! $fil->gzclose ) ;

ok(12, $fil = gzopen($name, "rb") ) ;

ok(13, ($x = $fil->gzread($uncomp)) == $num_len) ;

ok(14, ! $fil->gzclose ) ;

unlink $name ;

ok(15, $number == $uncomp) ;
ok(16, $number eq $uncomp) ;


# now a bigger gzip test

my $text = 'text' ;
my $file = "$text.gz" ;

ok(17, my $f = gzopen($file, "wb")) ;

# generate a long random string
my $contents = '' ;
foreach (1 .. 5000)
  { $contents .= chr int rand 255 }

$len = length $contents ;

ok(18, $f->gzwrite($contents) == $len ) ;

ok(19, ! $f->gzclose );

ok(20, $f = gzopen($file, "rb")) ;
 
my $uncompressed ;
ok(21, $f->gzread($uncompressed, $len) == $len) ;

ok(22, $contents eq $uncompressed) ;

ok(23, ! $f->gzclose ) ;

unlink($file) ;

# gzip - readline tests
# ======================

# first create a small gzipped text file
$name = "test.gz" ;
my @text = (<<EOM, <<EOM, <<EOM, <<EOM) ;
this is line 1
EOM
the second line
EOM
the line after the previous line
EOM
the final line
EOM

$text = join("", @text) ;

ok(24, $fil = gzopen($name, "wb")) ;
ok(25, $fil->gzwrite($text) == length $text) ;
ok(26, ! $fil->gzclose ) ;

# now try to read it back in
ok(27, $fil = gzopen($name, "rb")) ;
my $aok = 1 ; 
my $remember = '';
my $line = '';
my $lines = 0 ;
while ($fil->gzreadline($line) > 0) {
    ($aok = 0), last
	if $line ne $text[$lines] ;
    $remember .= $line ;
    ++ $lines ;
}
ok(28, $aok) ;
ok(29, $remember eq $text) ;
ok(30, $lines == @text) ;
ok(31, ! $fil->gzclose ) ;
unlink($name) ;

# a text file with a very long line (bigger than the internal buffer)
my $line1 = ("abcdefghijklmnopq" x 2000) . "\n" ;
my $line2 = "second line\n" ;
$text = $line1 . $line2 ;
ok(32, $fil = gzopen($name, "wb")) ;
ok(33, $fil->gzwrite($text) == length $text) ;
ok(34, ! $fil->gzclose ) ;

# now try to read it back in
ok(35, $fil = gzopen($name, "rb")) ;
my $i = 0 ;
my @got = ();
while ($fil->gzreadline($line) > 0) {
    $got[$i] = $line ;    
    ++ $i ;
}
ok(36, $i == 2) ;
ok(37, $got[0] eq $line1 ) ;
ok(38, $got[1] eq $line2) ;

ok(39, ! $fil->gzclose ) ;

unlink $name ;

# a text file which is not termined by an EOL

$line1 = "hello hello, I'm back again\n" ;
$line2 = "there is no end in sight" ;

$text = $line1 . $line2 ;
ok(40, $fil = gzopen($name, "wb")) ;
ok(41, $fil->gzwrite($text) == length $text) ;
ok(42, ! $fil->gzclose ) ;

# now try to read it back in
ok(43, $fil = gzopen($name, "rb")) ;
@got = () ; $i = 0 ;
while ($fil->gzreadline($line) > 0) {
    $got[$i] = $line ;    
    ++ $i ;
}
ok(44, $i == 2) ;
ok(45, $got[0] eq $line1 ) ;
ok(46, $got[1] eq $line2) ;

ok(47, ! $fil->gzclose ) ;

unlink $name ;


# mix gzread and gzreadline <

# case 1: read a line, then a block. The block is
#         smaller than the internal block used by
#	  gzreadline
$line1 = "hello hello, I'm back again\n" ;
$line2 = "abc" x 200 ; 
my $line3 = "def" x 200 ;

$text = $line1 . $line2 . $line3 ;
ok(48, $fil = gzopen($name, "wb")) ;
ok(49, $fil->gzwrite($text) == length $text) ;
ok(50, ! $fil->gzclose ) ;

# now try to read it back in
ok(51, $fil = gzopen($name, "rb")) ;
ok(52, $fil->gzreadline($line) > 0) ;
ok(53, $line eq $line1) ;
ok(54, $fil->gzread($line, length $line2) > 0) ;
ok(55, $line eq $line2) ;
ok(56, $fil->gzread($line, length $line3) > 0) ;
ok(57, $line eq $line3) ;
ok(58, ! $fil->gzclose ) ;
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

  ok(59, $f) ;

  my $line_one =  "first line\n" ;
  print $f $line_one;
  
  ok(60, $fil = gzopen($f, "wb")) ;
 
  ok(61, $fil->gzwrite($hello) == $len) ;
 
  ok(62, ! $fil->gzclose ) ;

 
  ok(63, my $g = new IO::File "<$filename") ;
  binmode $g ; # for OS/2
 
  my $first ;
  my $ret = read($g, $first, length($line_one));
  ok(64, $ret == length($line_one));

  ok(65, $first eq $line_one) ;

  ok(66, $fil = gzopen($g, "rb") ) ;
  my $uncomp;
  ok(67, ($x = $fil->gzread($uncomp)) == $len) ;
 
  ok(68, ! $fil->gzclose ) ;
 
  unlink $filename ;
 
  ok(69, $hello eq $uncomp) ;

}

{
  my $filename = "fh.gz" ;
  my $hello = "hello, hello, I'm back again" ;
  my $len = length $hello ;
  my $uncomp;
  local (*FH1) ;
  local (*FH2) ;
 
  ok(70, open FH1, ">$filename") ;
  binmode FH1; # for OS/2
 
  my $line_one =  "first line\n" ;
  print FH1 $line_one;
 
  ok(71, $fil = gzopen(\*FH1, "wb")) ;
 
  ok(72, $fil->gzwrite($hello) == $len) ;
 
  ok(73, ! $fil->gzclose ) ;
 
 
  ok(74, my $g = open FH2, "<$filename") ;
  binmode FH2; # for OS/2
 
  my $first ;
  my $ret = read(FH2, $first, length($line_one));
  ok(75, $ret == length($line_one));
 
  ok(76, $first eq $line_one) ;
 
  ok(77, $fil = gzopen(*FH2, "rb") ) ;
  ok(78, ($x = $fil->gzread($uncomp)) == $len) ;
 
  ok(79, ! $fil->gzclose ) ;
 
  unlink $filename ;
 
  ok(80, $hello eq $uncomp) ;
 
}


# compress/uncompress tests
# =========================

$hello = "hello mum" ;
my $keep_hello = $hello ;

my $compr = compress($hello) ;
ok(81, $compr ne "") ;

my $keep_compr = $compr ;

my $uncompr = uncompress ($compr) ;

ok(82, $hello eq $uncompr) ;

ok(83, $hello eq $keep_hello) ;
ok(84, $compr eq $keep_compr) ;

# compress a number
$hello = 7890 ;
$keep_hello = $hello ;

$compr = compress($hello) ;
ok(85, $compr ne "") ;

$keep_compr = $compr ;

$uncompr = uncompress ($compr) ;

ok(86, $hello eq $uncompr) ;

ok(87, $hello eq $keep_hello) ;
ok(88, $compr eq $keep_compr) ;

# bigger compress

$compr = compress ($contents) ;
ok(89, $compr ne "") ;

$uncompr = uncompress ($compr) ;

ok(90, $contents eq $uncompr) ;

# buffer reference

$compr = compress(\$hello) ;
ok(91, $compr ne "") ;


$uncompr = uncompress (\$compr) ;
ok(92, $hello eq $uncompr) ;

# bad level
$compr = compress($hello, 1000) ;
ok(93, ! defined $compr);

# change level
$compr = compress($hello, Z_BEST_COMPRESSION) ;
ok(94, defined $compr);
$uncompr = uncompress (\$compr) ;
ok(95, $hello eq $uncompr) ;

# deflate/inflate - small buffer
# ==============================

$hello = "I am a HAL 9000 computer" ;
my @hello = split('', $hello) ;
my ($err, $X, $status);
 
ok(96,  ($x, $err) = deflateInit( {-Bufsize => 1} ) ) ;
ok(97, $x) ;
ok(98, $err == Z_OK) ;
 
my $Answer = '';
foreach (@hello)
{
    ($X, $status) = $x->deflate($_) ;
    last unless $status == Z_OK ;

    $Answer .= $X ;
}
 
ok(99, $status == Z_OK) ;

ok(100,    (($X, $status) = $x->flush())[1] == Z_OK ) ;
$Answer .= $X ;
 
 
my @Answer = split('', $Answer) ;
 
my $k;
ok(101, ($k, $err) = inflateInit( {-Bufsize => 1}) ) ;
ok(102, $k) ;
ok(103, $err == Z_OK) ;
 
my $GOT = '';
my $Z;
foreach (@Answer)
{
    ($Z, $status) = $k->inflate($_) ;
    $GOT .= $Z ;
    last if $status == Z_STREAM_END or $status != Z_OK ;
 
}
 
ok(104, $status == Z_STREAM_END) ;
ok(105, $GOT eq $hello ) ;


# deflate/inflate - small buffer with a number
# ==============================

$hello = 6529 ;
 
ok(106,  ($x, $err) = deflateInit( {-Bufsize => 1} ) ) ;
ok(107, $x) ;
ok(108, $err == Z_OK) ;
 
$Answer = '';
{
    ($X, $status) = $x->deflate($hello) ;

    $Answer .= $X ;
}
 
ok(109, $status == Z_OK) ;

ok(110,    (($X, $status) = $x->flush())[1] == Z_OK ) ;
$Answer .= $X ;
 
 
@Answer = split('', $Answer) ;
 
ok(111, ($k, $err) = inflateInit( {-Bufsize => 1}) ) ;
ok(112, $k) ;
ok(113, $err == Z_OK) ;
 
$GOT = '';
foreach (@Answer)
{
    ($Z, $status) = $k->inflate($_) ;
    $GOT .= $Z ;
    last if $status == Z_STREAM_END or $status != Z_OK ;
 
}
 
ok(114, $status == Z_STREAM_END) ;
ok(115, $GOT eq $hello ) ;


 
# deflate/inflate - larger buffer
# ==============================


ok(116, $x = deflateInit() ) ;
 
ok(117, (($X, $status) = $x->deflate($contents))[1] == Z_OK) ;

my $Y = $X ;
 
 
ok(118, (($X, $status) = $x->flush() )[1] == Z_OK ) ;
$Y .= $X ;
 
 
 
ok(119, $k = inflateInit() ) ;
 
($Z, $status) = $k->inflate($Y) ;
 
ok(120, $status == Z_STREAM_END) ;
ok(121, $contents eq $Z ) ;

# deflate/inflate - preset dictionary
# ===================================

my $dictionary = "hello" ;
ok(122, $x = deflateInit({-Level => Z_BEST_COMPRESSION,
			 -Dictionary => $dictionary})) ;
 
my $dictID = $x->dict_adler() ;

($X, $status) = $x->deflate($hello) ;
ok(123, $status == Z_OK) ;
($Y, $status) = $x->flush() ;
ok(124, $status == Z_OK) ;
$X .= $Y ;
$x = 0 ;
 
ok(125, $k = inflateInit(-Dictionary => $dictionary) ) ;
 
($Z, $status) = $k->inflate($X);
ok(126, $status == Z_STREAM_END) ;
ok(127, $k->dict_adler() == $dictID);
ok(128, $hello eq $Z ) ;

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
    ok(129, $x = deflateInit(-Level => Z_BEST_COMPRESSION )) ;
 
    ($X, $status) = $x->deflate($hello) ;
    ok(130, $status == Z_OK) ;
    ($Y, $status) = $x->flush() ;
    ok(131, $status == Z_OK) ;
    $X .= $Y ;
    $x = 0 ;
 
    ok(132, $k = inflateInit() ) ;
 
    my $first = substr($X, 0, 2) ;
    my $last  = substr($X, 2) ;
    ($Z, $status) = $k->inflate($first);
    ok(133, $status == Z_OK) ;
    ok(134, $first eq "") ;

    $last .= "appendage" ;
    my ($T, $status) = $k->inflate($last);
    ok(135, $status == Z_STREAM_END) ;
    ok(136, $hello eq $Z . $T ) ;
    ok(137, $last eq "appendage") ;

}

# memGzip & memGunzip
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
    ok(138, length $dest) ;

    # write it to disk
    ok(139, open(FH, ">$name")) ;
    binmode(FH);
    print FH $dest ;
    close FH ;

    # uncompress with gzopen
    ok(140, my $fil = gzopen($name, "rb") ) ;
 
    ok(141, ($x = $fil->gzread($uncomp)) == $len) ;
 
    ok(142, ! $fil->gzclose ) ;

    ok(143, $uncomp eq $buffer) ;
 
    unlink $name ;

    # now check that memGunzip can deal with it.
    my $ungzip = Compress::Zlib::memGunzip($dest) ;
    ok(144, defined $ungzip) ;
    ok(145, $buffer eq $ungzip) ;
 
    # now do the same but use a reference 

    $dest = Compress::Zlib::memGzip(\$buffer) ; 
    ok(146, length $dest) ;

    # write it to disk
    ok(147, open(FH, ">$name")) ;
    binmode(FH);
    print FH $dest ;
    close FH ;

    # uncompress with gzopen
    ok(148, $fil = gzopen($name, "rb") ) ;
 
    ok(149, ($x = $fil->gzread($uncomp)) == $len) ;
 
    ok(150, ! $fil->gzclose ) ;

    ok(151, $uncomp eq $buffer) ;
 
    # now check that memGunzip can deal with it.
    $ungzip = Compress::Zlib::memGunzip(\$dest) ;
    ok(152, defined $ungzip) ;
    ok(153, $buffer eq $ungzip) ;
 
    unlink $name ;

    # check corrupt header -- too short
    $dest = "x" ;
    my $result = Compress::Zlib::memGunzip($dest) ;
    ok(154, !defined $result) ;

    # check corrupt header -- full of junk
    $dest = "x" x 200 ;
    $result = Compress::Zlib::memGunzip($dest) ;
    ok(155, !defined $result) ;
}

# memGunzip with a gzopen created file
{
    my $name = "test.gz" ;
    my $buffer = <<EOM;
some sample 
text

EOM

    ok(156, $fil = gzopen($name, "wb")) ;

    ok(157, $fil->gzwrite($buffer) == length $buffer) ;

    ok(158, ! $fil->gzclose ) ;

    my $compr = readFile($name);
    ok(159, length $compr) ;
    my $unc = Compress::Zlib::memGunzip($compr) ;
    ok(160, defined $unc) ;
    ok(161, $buffer eq $unc) ;
    unlink $name ;
}

{

    # Check - MAX_WBITS
    # =================
    
    $hello = "Test test test test test";
    @hello = split('', $hello) ;
     
    ok(162,  ($x, $err) = deflateInit( -Bufsize => 1, -WindowBits => -MAX_WBITS() ) ) ;
    ok(163, $x) ;
    ok(164, $err == Z_OK) ;
     
    $Answer = '';
    foreach (@hello)
    {
        ($X, $status) = $x->deflate($_) ;
        last unless $status == Z_OK ;
    
        $Answer .= $X ;
    }
     
    ok(165, $status == Z_OK) ;
    
    ok(166,    (($X, $status) = $x->flush())[1] == Z_OK ) ;
    $Answer .= $X ;
     
     
    @Answer = split('', $Answer) ;
    # Undocumented corner -- extra byte needed to get inflate to return 
    # Z_STREAM_END when done.  
    push @Answer, " " ; 
     
    ok(167, ($k, $err) = inflateInit(-Bufsize => 1, -WindowBits => -MAX_WBITS()) ) ;
    ok(168, $k) ;
    ok(169, $err == Z_OK) ;
     
    $GOT = '';
    foreach (@Answer)
    {
        ($Z, $status) = $k->inflate($_) ;
        $GOT .= $Z ;
        last if $status == Z_STREAM_END or $status != Z_OK ;
     
    }
     
    ok(170, $status == Z_STREAM_END) ;
    ok(171, $GOT eq $hello ) ;
    
}

{
    # inflateSync

    # create a deflate stream with flush points

    my $hello = "I am a HAL 9000 computer" x 2001 ;
    my $goodbye = "Will I dream?" x 2010;
    my ($err, $answer, $X, $status, $Answer);
     
    ok(172, ($x, $err) = deflateInit() ) ;
    ok(173, $x) ;
    ok(174, $err == Z_OK) ;
     
    ($Answer, $status) = $x->deflate($hello) ;
    ok(175, $status == Z_OK) ;
    
    # create a flush point
    ok(176, (($X, $status) = $x->flush(Z_FULL_FLUSH))[1] == Z_OK ) ;
    $Answer .= $X ;
     
    ($X, $status) = $x->deflate($goodbye) ;
    ok(177, $status == Z_OK) ;
    $Answer .= $X ;
    
    ok(178, (($X, $status) = $x->flush())[1] == Z_OK ) ;
    $Answer .= $X ;
     
    my ($first, @Answer) = split('', $Answer) ;
     
    my $k;
    ok(179, ($k, $err) = inflateInit()) ;
    ok(180, $k) ;
    ok(181, $err == Z_OK) ;
     
    ($Z, $status) = $k->inflate($first) ;
    ok(182, $status == Z_OK) ;

    # skip to the first flush point.
    while (@Answer)
    {
        my $byte = shift @Answer;
        $status = $k->inflateSync($byte) ;
        last unless $status == Z_DATA_ERROR;
     
    }

    ok(183, $status == Z_OK);
     
    my $GOT = '';
    my $Z = '';
    foreach (@Answer)
    {
        my $Z = '';
        ($Z, $status) = $k->inflate($_) ;
        $GOT .= $Z if defined $Z ;
        # print "x $status\n";
        last if $status == Z_STREAM_END or $status != Z_OK ;
     
    }
     
    # zlib 1.0.9 returns Z_STREAM_END here, all others return Z_DATA_ERROR
    ok(184, $status == Z_DATA_ERROR || $status == Z_STREAM_END) ;
    ok(185, $GOT eq $goodbye ) ;


    # Check inflateSync leaves good data in buffer
    $Answer =~ /^(.)(.*)$/ ;
    my ($initial, $rest) = ($1, $2);

    
    ok(186, ($k, $err) = inflateInit()) ;
    ok(187, $k) ;
    ok(188, $err == Z_OK) ;
     
    ($Z, $status) = $k->inflate($initial) ;
    ok(189, $status == Z_OK) ;

    $status = $k->inflateSync($rest) ;
    ok(190, $status == Z_OK);
     
    ($GOT, $status) = $k->inflate($rest) ;
     
    ok(191, $status == Z_DATA_ERROR) ;
    ok(192, $Z . $GOT eq $goodbye ) ;
}

{
    # deflateParams

    my $hello = "I am a HAL 9000 computer" x 2001 ;
    my $goodbye = "Will I dream?" x 2010;
    my ($input, $err, $answer, $X, $status, $Answer);
     
    ok(193, ($x, $err) = deflateInit(-Level    => Z_BEST_COMPRESSION,
                                     -Strategy => Z_DEFAULT_STRATEGY) ) ;
    ok(194, $x) ;
    ok(195, $err == Z_OK) ;

    ok(196, $x->get_Level()    == Z_BEST_COMPRESSION);
    ok(197, $x->get_Strategy() == Z_DEFAULT_STRATEGY);
     
    ($Answer, $status) = $x->deflate($hello) ;
    ok(198, $status == Z_OK) ;
    $input .= $hello;
    
    # error cases
    eval { $x->deflateParams() };
    ok(199, $@ =~ m#^deflateParams needs Level and/or Strategy#);

    eval { $x->deflateParams(-Joe => 3) };
    ok(200, $@ =~ /^unknown key value\(s\) Joe at/);

    ok(201, $x->get_Level()    == Z_BEST_COMPRESSION);
    ok(202, $x->get_Strategy() == Z_DEFAULT_STRATEGY);
     
    # change both Level & Strategy
    $status = $x->deflateParams(-Level => Z_BEST_SPEED, -Strategy => Z_HUFFMAN_ONLY) ;
    ok(203, $status == Z_OK) ;
    
    ok(204, $x->get_Level()    == Z_BEST_SPEED);
    ok(205, $x->get_Strategy() == Z_HUFFMAN_ONLY);
     
    ($X, $status) = $x->deflate($goodbye) ;
    ok(206, $status == Z_OK) ;
    $Answer .= $X ;
    $input .= $goodbye;
    
    # change only Level 
    $status = $x->deflateParams(-Level => Z_NO_COMPRESSION) ;
    ok(207, $status == Z_OK) ;
    
    ok(208, $x->get_Level()    == Z_NO_COMPRESSION);
    ok(209, $x->get_Strategy() == Z_HUFFMAN_ONLY);
     
    ($X, $status) = $x->deflate($goodbye) ;
    ok(210, $status == Z_OK) ;
    $Answer .= $X ;
    $input .= $goodbye;
    
    # change only Strategy
    $status = $x->deflateParams(-Strategy => Z_FILTERED) ;
    ok(211, $status == Z_OK) ;
    
    ok(212, $x->get_Level()    == Z_NO_COMPRESSION);
    ok(213, $x->get_Strategy() == Z_FILTERED);
     
    ($X, $status) = $x->deflate($goodbye) ;
    ok(214, $status == Z_OK) ;
    $Answer .= $X ;
    $input .= $goodbye;
    
    ok(215, (($X, $status) = $x->flush())[1] == Z_OK ) ;
    $Answer .= $X ;
     
    my ($first, @Answer) = split('', $Answer) ;
     
    my $k;
    ok(216, ($k, $err) = inflateInit()) ;
    ok(217, $k) ;
    ok(218, $err == Z_OK) ;
     
    ($Z, $status) = $k->inflate($Answer) ;

    ok(219, $status == Z_STREAM_END) ;
    ok(220, $Z  eq $input ) ;
}

{
    # error cases

    eval { deflateInit(-Level) };
    ok(221, $@ =~ /^Compress::Zlib::deflateInit: parameter is not a reference to a hash at/);

    eval { inflateInit(-Level) };
    ok(222, $@ =~ /^Compress::Zlib::inflateInit: parameter is not a reference to a hash at/);

    eval { deflateInit(-Joe => 1) };
    ok(223, $@ =~ /^unknown key value\(s\) Joe at/);

    eval { inflateInit(-Joe => 1) };
    ok(224, $@ =~ /^unknown key value\(s\) Joe at/);

    eval { deflateInit(-Bufsize => 0) };
    ok(225, $@ =~ /^.*?: Bufsize must be >= 1, you specified 0 at/);

    eval { inflateInit(-Bufsize => 0) };
    ok(226, $@ =~ /^.*?: Bufsize must be >= 1, you specified 0 at/);

    eval { deflateInit(-Bufsize => -1) };
    ok(227, $@ =~ /^.*?: Bufsize must be >= 1, you specified -1 at/);

    eval { inflateInit(-Bufsize => -1) };
    ok(228, $@ =~ /^.*?: Bufsize must be >= 1, you specified -1 at/);

    eval { deflateInit(-Bufsize => "xxx") };
    ok(229, $@ =~ /^.*?: Bufsize must be >= 1, you specified xxx at/);

    eval { inflateInit(-Bufsize => "xxx") };
    ok(230, $@ =~ /^.*?: Bufsize must be >= 1, you specified xxx at/);

}

