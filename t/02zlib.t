

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


print "1..237\n" ;

# Check zlib_version and ZLIB_VERSION are the same.
ok(1, Compress::Zlib::zlib_version eq ZLIB_VERSION) ;

# gzip tests
#===========

my $name = "test.gz" ;
my ($x, $uncomp) ;

ok(2, my $fil = gzopen($name, "wb")) ;

ok(3, $gzerrno == 0);

ok(4, $fil->gzwrite($hello) == $len) ;

ok(5, ! $fil->gzclose ) ;

ok(6, $fil = gzopen($name, "rb") ) ;

ok(7, $gzerrno == 0);

ok(8, ($x = $fil->gzread($uncomp)) == $len) ;

ok(9, ! $fil->gzclose ) ;

unlink $name ;

ok(10, $hello eq $uncomp) ;

# check that a number can be gzipped
my $number = 7603 ;
my $num_len = 4 ;

ok(11, $fil = gzopen($name, "wb")) ;

ok(12, $gzerrno == 0);

ok(13, $fil->gzwrite($number) == $num_len) ;

ok(14, $gzerrno == 0);

ok(15, ! $fil->gzclose ) ;

ok(16, $gzerrno == 0);

ok(17, $fil = gzopen($name, "rb") ) ;

ok(18, ($x = $fil->gzread($uncomp)) == $num_len) ;

ok(19, $gzerrno == 0 || $gzerrno == Z_STREAM_END);

ok(20, ! $fil->gzclose ) ;

ok(21, $gzerrno == 0);

unlink $name ;

ok(22, $number == $uncomp) ;
ok(23, $number eq $uncomp) ;


# now a bigger gzip test

my $text = 'text' ;
my $file = "$text.gz" ;

ok(24, my $f = gzopen($file, "wb")) ;

# generate a long random string
my $contents = '' ;
foreach (1 .. 5000)
  { $contents .= chr int rand 256 }

$len = length $contents ;

ok(25, $f->gzwrite($contents) == $len ) ;

ok(26, ! $f->gzclose );

ok(27, $f = gzopen($file, "rb")) ;
 
my $uncompressed ;
ok(28, $f->gzread($uncompressed, $len) == $len) ;

ok(29, $contents eq $uncompressed) ;

ok(30, ! $f->gzclose ) ;

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

ok(31, $fil = gzopen($name, "wb")) ;
ok(32, $fil->gzwrite($text) == length $text) ;
ok(33, ! $fil->gzclose ) ;

# now try to read it back in
ok(34, $fil = gzopen($name, "rb")) ;
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
ok(35, $aok) ;
ok(36, $remember eq $text) ;
ok(37, $lines == @text) ;
ok(38, ! $fil->gzclose ) ;
unlink($name) ;

# a text file with a very long line (bigger than the internal buffer)
my $line1 = ("abcdefghijklmnopq" x 2000) . "\n" ;
my $line2 = "second line\n" ;
$text = $line1 . $line2 ;
ok(39, $fil = gzopen($name, "wb")) ;
ok(40, $fil->gzwrite($text) == length $text) ;
ok(41, ! $fil->gzclose ) ;

# now try to read it back in
ok(42, $fil = gzopen($name, "rb")) ;
my $i = 0 ;
my @got = ();
while ($fil->gzreadline($line) > 0) {
    $got[$i] = $line ;    
    ++ $i ;
}
ok(43, $i == 2) ;
ok(44, $got[0] eq $line1 ) ;
ok(45, $got[1] eq $line2) ;

ok(46, ! $fil->gzclose ) ;

unlink $name ;

# a text file which is not termined by an EOL

$line1 = "hello hello, I'm back again\n" ;
$line2 = "there is no end in sight" ;

$text = $line1 . $line2 ;
ok(47, $fil = gzopen($name, "wb")) ;
ok(48, $fil->gzwrite($text) == length $text) ;
ok(49, ! $fil->gzclose ) ;

# now try to read it back in
ok(50, $fil = gzopen($name, "rb")) ;
@got = () ; $i = 0 ;
while ($fil->gzreadline($line) > 0) {
    $got[$i] = $line ;    
    ++ $i ;
}
ok(51, $i == 2) ;
ok(52, $got[0] eq $line1 ) ;
ok(53, $got[1] eq $line2) ;

ok(54, ! $fil->gzclose ) ;

unlink $name ;


# mix gzread and gzreadline <

# case 1: read a line, then a block. The block is
#         smaller than the internal block used by
#	  gzreadline
$line1 = "hello hello, I'm back again\n" ;
$line2 = "abc" x 200 ; 
my $line3 = "def" x 200 ;

$text = $line1 . $line2 . $line3 ;
ok(55, $fil = gzopen($name, "wb")) ;
ok(56, $fil->gzwrite($text) == length $text) ;
ok(57, ! $fil->gzclose ) ;

# now try to read it back in
ok(58, $fil = gzopen($name, "rb")) ;
ok(59, $fil->gzreadline($line) > 0) ;
ok(60, $line eq $line1) ;
ok(61, $fil->gzread($line, length $line2) > 0) ;
ok(62, $line eq $line2) ;
ok(63, $fil->gzread($line, length $line3) > 0) ;
ok(64, $line eq $line3) ;
ok(65, ! $fil->gzclose ) ;
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

  ok(66, $f) ;

  my $line_one =  "first line\n" ;
  print $f $line_one;
  
  ok(67, $fil = gzopen($f, "wb")) ;
 
  ok(68, $fil->gzwrite($hello) == $len) ;
 
  ok(69, ! $fil->gzclose ) ;

 
  ok(70, my $g = new IO::File "<$filename") ;
  binmode $g ; # for OS/2
 
  my $first ;
  my $ret = read($g, $first, length($line_one));
  ok(71, $ret == length($line_one));

  ok(72, $first eq $line_one) ;

  ok(73, $fil = gzopen($g, "rb") ) ;
  my $uncomp;
  ok(74, ($x = $fil->gzread($uncomp)) == $len) ;
 
  ok(75, ! $fil->gzclose ) ;
 
  unlink $filename ;
 
  ok(76, $hello eq $uncomp) ;

}

{
  my $filename = "fh.gz" ;
  my $hello = "hello, hello, I'm back again" ;
  my $len = length $hello ;
  my $uncomp;
  local (*FH1) ;
  local (*FH2) ;
 
  ok(77, open FH1, ">$filename") ;
  binmode FH1; # for OS/2
 
  my $line_one =  "first line\n" ;
  print FH1 $line_one;
 
  ok(78, $fil = gzopen(\*FH1, "wb")) ;
 
  ok(79, $fil->gzwrite($hello) == $len) ;
 
  ok(80, ! $fil->gzclose ) ;
 
 
  ok(81, my $g = open FH2, "<$filename") ;
  binmode FH2; # for OS/2
 
  my $first ;
  my $ret = read(FH2, $first, length($line_one));
  ok(82, $ret == length($line_one));
 
  ok(83, $first eq $line_one) ;
 
  ok(84, $fil = gzopen(*FH2, "rb") ) ;
  ok(85, ($x = $fil->gzread($uncomp)) == $len) ;
 
  ok(86, ! $fil->gzclose ) ;
 
  unlink $filename ;
 
  ok(87, $hello eq $uncomp) ;
 
}


# compress/uncompress tests
# =========================

$hello = "hello mum" ;
my $keep_hello = $hello ;

my $compr = compress($hello) ;
ok(88, $compr ne "") ;

my $keep_compr = $compr ;

my $uncompr = uncompress ($compr) ;

ok(89, $hello eq $uncompr) ;

ok(90, $hello eq $keep_hello) ;
ok(91, $compr eq $keep_compr) ;

# compress a number
$hello = 7890 ;
$keep_hello = $hello ;

$compr = compress($hello) ;
ok(92, $compr ne "") ;

$keep_compr = $compr ;

$uncompr = uncompress ($compr) ;

ok(93, $hello eq $uncompr) ;

ok(94, $hello eq $keep_hello) ;
ok(95, $compr eq $keep_compr) ;

# bigger compress

$compr = compress ($contents) ;
ok(96, $compr ne "") ;

$uncompr = uncompress ($compr) ;

ok(97, $contents eq $uncompr) ;

# buffer reference

$compr = compress(\$hello) ;
ok(98, $compr ne "") ;


$uncompr = uncompress (\$compr) ;
ok(99, $hello eq $uncompr) ;

# bad level
$compr = compress($hello, 1000) ;
ok(100, ! defined $compr);

# change level
$compr = compress($hello, Z_BEST_COMPRESSION) ;
ok(101, defined $compr);
$uncompr = uncompress (\$compr) ;
ok(102, $hello eq $uncompr) ;

# deflate/inflate - small buffer
# ==============================

$hello = "I am a HAL 9000 computer" ;
my @hello = split('', $hello) ;
my ($err, $X, $status);
 
ok(103,  ($x, $err) = deflateInit( {-Bufsize => 1} ) ) ;
ok(104, $x) ;
ok(105, $err == Z_OK) ;
 
my $Answer = '';
foreach (@hello)
{
    ($X, $status) = $x->deflate($_) ;
    last unless $status == Z_OK ;

    $Answer .= $X ;
}
 
ok(106, $status == Z_OK) ;

ok(107,    (($X, $status) = $x->flush())[1] == Z_OK ) ;
$Answer .= $X ;
 
 
my @Answer = split('', $Answer) ;
 
my $k;
ok(108, ($k, $err) = inflateInit( {-Bufsize => 1}) ) ;
ok(109, $k) ;
ok(110, $err == Z_OK) ;
 
my $GOT = '';
my $Z;
foreach (@Answer)
{
    ($Z, $status) = $k->inflate($_) ;
    $GOT .= $Z ;
    last if $status == Z_STREAM_END or $status != Z_OK ;
 
}
 
ok(111, $status == Z_STREAM_END) ;
ok(112, $GOT eq $hello ) ;


# deflate/inflate - small buffer with a number
# ==============================

$hello = 6529 ;
 
ok(113,  ($x, $err) = deflateInit( {-Bufsize => 1} ) ) ;
ok(114, $x) ;
ok(115, $err == Z_OK) ;
 
$Answer = '';
{
    ($X, $status) = $x->deflate($hello) ;

    $Answer .= $X ;
}
 
ok(116, $status == Z_OK) ;

ok(117,    (($X, $status) = $x->flush())[1] == Z_OK ) ;
$Answer .= $X ;
 
 
@Answer = split('', $Answer) ;
 
ok(118, ($k, $err) = inflateInit( {-Bufsize => 1}) ) ;
ok(119, $k) ;
ok(120, $err == Z_OK) ;
 
$GOT = '';
foreach (@Answer)
{
    ($Z, $status) = $k->inflate($_) ;
    $GOT .= $Z ;
    last if $status == Z_STREAM_END or $status != Z_OK ;
 
}
 
ok(121, $status == Z_STREAM_END) ;
ok(122, $GOT eq $hello ) ;


 
# deflate/inflate - larger buffer
# ==============================


ok(123, $x = deflateInit() ) ;
 
ok(124, (($X, $status) = $x->deflate($contents))[1] == Z_OK) ;

my $Y = $X ;
 
 
ok(125, (($X, $status) = $x->flush() )[1] == Z_OK ) ;
$Y .= $X ;
 
 
 
ok(126, $k = inflateInit() ) ;
 
($Z, $status) = $k->inflate($Y) ;
 
ok(127, $status == Z_STREAM_END) ;
ok(128, $contents eq $Z ) ;

# deflate/inflate - preset dictionary
# ===================================

my $dictionary = "hello" ;
ok(129, $x = deflateInit({-Level => Z_BEST_COMPRESSION,
			 -Dictionary => $dictionary})) ;
 
my $dictID = $x->dict_adler() ;

($X, $status) = $x->deflate($hello) ;
ok(130, $status == Z_OK) ;
($Y, $status) = $x->flush() ;
ok(131, $status == Z_OK) ;
$X .= $Y ;
$x = 0 ;
 
ok(132, $k = inflateInit(-Dictionary => $dictionary) ) ;
 
($Z, $status) = $k->inflate($X);
ok(133, $status == Z_STREAM_END) ;
ok(134, $k->dict_adler() == $dictID);
ok(135, $hello eq $Z ) ;

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
    ok(136, $x = deflateInit(-Level => Z_BEST_COMPRESSION )) ;
 
    ($X, $status) = $x->deflate($hello) ;
    ok(137, $status == Z_OK) ;
    ($Y, $status) = $x->flush() ;
    ok(138, $status == Z_OK) ;
    $X .= $Y ;
    $x = 0 ;
 
    ok(139, $k = inflateInit() ) ;
 
    my $first = substr($X, 0, 2) ;
    my $last  = substr($X, 2) ;
    ($Z, $status) = $k->inflate($first);
    ok(140, $status == Z_OK) ;
    ok(141, $first eq "") ;

    $last .= "appendage" ;
    my ($T, $status) = $k->inflate($last);
    ok(142, $status == Z_STREAM_END) ;
    ok(143, $hello eq $Z . $T ) ;
    ok(144, $last eq "appendage") ;

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
    ok(145, length $dest) ;

    # write it to disk
    ok(146, open(FH, ">$name")) ;
    #binmode(FH);
    print FH $dest ;
    close FH ;

    # uncompress with gzopen
    ok(147, my $fil = gzopen($name, "rb") ) ;
 
    ok(148, ($x = $fil->gzread($uncomp)) == $len) ;
 
    ok(149, ! $fil->gzclose ) ;

    ok(150, $uncomp eq $buffer) ;
 
    unlink $name ;

    # now check that memGunzip can deal with it.
    my $ungzip = Compress::Zlib::memGunzip($dest) ;
    ok(151, defined $ungzip) ;
    ok(152, $buffer eq $ungzip) ;
 
    # now do the same but use a reference 

    $dest = Compress::Zlib::memGzip(\$buffer) ; 
    ok(153, length $dest) ;

    # write it to disk
    ok(154, open(FH, ">$name")) ;
    binmode(FH);
    print FH $dest ;
    close FH ;

    # uncompress with gzopen
    ok(155, $fil = gzopen($name, "rb") ) ;
 
    ok(156, ($x = $fil->gzread($uncomp)) == $len) ;
 
    ok(157, ! $fil->gzclose ) ;

    ok(158, $uncomp eq $buffer) ;
 
    # now check that memGunzip can deal with it.
    $ungzip = Compress::Zlib::memGunzip(\$dest) ;
    ok(159, defined $ungzip) ;
    ok(160, $buffer eq $ungzip) ;
 
    unlink $name ;

    # check corrupt header -- too short
    $dest = "x" ;
    my $result = Compress::Zlib::memGunzip($dest) ;
    ok(161, !defined $result) ;

    # check corrupt header -- full of junk
    $dest = "x" x 200 ;
    $result = Compress::Zlib::memGunzip($dest) ;
    ok(162, !defined $result) ;
}

# memGunzip with a gzopen created file
{
    my $name = "test.gz" ;
    my $buffer = <<EOM;
some sample 
text

EOM

    ok(163, $fil = gzopen($name, "wb")) ;

    ok(164, $fil->gzwrite($buffer) == length $buffer) ;

    ok(165, ! $fil->gzclose ) ;

    my $compr = readFile($name);
    ok(166, length $compr) ;
    my $unc = Compress::Zlib::memGunzip($compr) ;
    ok(167, defined $unc) ;
    ok(168, $buffer eq $unc) ;
    unlink $name ;
}

{

    # Check - MAX_WBITS
    # =================
    
    $hello = "Test test test test test";
    @hello = split('', $hello) ;
     
    ok(169,  ($x, $err) = deflateInit( -Bufsize => 1, -WindowBits => -MAX_WBITS() ) ) ;
    ok(170, $x) ;
    ok(171, $err == Z_OK) ;
     
    $Answer = '';
    foreach (@hello)
    {
        ($X, $status) = $x->deflate($_) ;
        last unless $status == Z_OK ;
    
        $Answer .= $X ;
    }
     
    ok(172, $status == Z_OK) ;
    
    ok(173,    (($X, $status) = $x->flush())[1] == Z_OK ) ;
    $Answer .= $X ;
     
     
    @Answer = split('', $Answer) ;
    # Undocumented corner -- extra byte needed to get inflate to return 
    # Z_STREAM_END when done.  
    push @Answer, " " ; 
     
    ok(174, ($k, $err) = inflateInit(-Bufsize => 1, -WindowBits => -MAX_WBITS()) ) ;
    ok(175, $k) ;
    ok(176, $err == Z_OK) ;
     
    $GOT = '';
    foreach (@Answer)
    {
        ($Z, $status) = $k->inflate($_) ;
        $GOT .= $Z ;
        last if $status == Z_STREAM_END or $status != Z_OK ;
     
    }
     
    ok(177, $status == Z_STREAM_END) ;
    ok(178, $GOT eq $hello ) ;
    
}

{
    # inflateSync

    # create a deflate stream with flush points

    my $hello = "I am a HAL 9000 computer" x 2001 ;
    my $goodbye = "Will I dream?" x 2010;
    my ($err, $answer, $X, $status, $Answer);
     
    ok(179, ($x, $err) = deflateInit() ) ;
    ok(180, $x) ;
    ok(181, $err == Z_OK) ;
     
    ($Answer, $status) = $x->deflate($hello) ;
    ok(182, $status == Z_OK) ;
    
    # create a flush point
    ok(183, (($X, $status) = $x->flush(Z_FULL_FLUSH))[1] == Z_OK ) ;
    $Answer .= $X ;
     
    ($X, $status) = $x->deflate($goodbye) ;
    ok(184, $status == Z_OK) ;
    $Answer .= $X ;
    
    ok(185, (($X, $status) = $x->flush())[1] == Z_OK ) ;
    $Answer .= $X ;
     
    my ($first, @Answer) = split('', $Answer) ;
     
    my $k;
    ok(186, ($k, $err) = inflateInit()) ;
    ok(187, $k) ;
    ok(188, $err == Z_OK) ;
     
    ($Z, $status) = $k->inflate($first) ;
    ok(189, $status == Z_OK) ;

    # skip to the first flush point.
    while (@Answer)
    {
        my $byte = shift @Answer;
        $status = $k->inflateSync($byte) ;
        last unless $status == Z_DATA_ERROR;
     
    }

    ok(190, $status == Z_OK);
     
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
    ok(191, $status == Z_DATA_ERROR || $status == Z_STREAM_END) ;
    ok(192, $GOT eq $goodbye ) ;


    # Check inflateSync leaves good data in buffer
    $Answer =~ /^(.)(.*)$/ ;
    my ($initial, $rest) = ($1, $2);

    
    ok(193, ($k, $err) = inflateInit()) ;
    ok(194, $k) ;
    ok(195, $err == Z_OK) ;
     
    ($Z, $status) = $k->inflate($initial) ;
    ok(196, $status == Z_OK) ;

    $status = $k->inflateSync($rest) ;
    ok(197, $status == Z_OK);
     
    ($GOT, $status) = $k->inflate($rest) ;
     
    ok(198, $status == Z_DATA_ERROR) ;
    ok(199, $Z . $GOT eq $goodbye ) ;
}

{
    # deflateParams

    my $hello = "I am a HAL 9000 computer" x 2001 ;
    my $goodbye = "Will I dream?" x 2010;
    my ($input, $err, $answer, $X, $status, $Answer);
     
    ok(200, ($x, $err) = deflateInit(-Level    => Z_BEST_COMPRESSION,
                                     -Strategy => Z_DEFAULT_STRATEGY) ) ;
    ok(201, $x) ;
    ok(202, $err == Z_OK) ;

    ok(203, $x->get_Level()    == Z_BEST_COMPRESSION);
    ok(204, $x->get_Strategy() == Z_DEFAULT_STRATEGY);
     
    ($Answer, $status) = $x->deflate($hello) ;
    ok(205, $status == Z_OK) ;
    $input .= $hello;
    
    # error cases
    eval { $x->deflateParams() };
    ok(206, $@ =~ m#^deflateParams needs Level and/or Strategy#);

    eval { $x->deflateParams(-Joe => 3) };
    ok(207, $@ =~ /^unknown key value\(s\) Joe at/);

    ok(208, $x->get_Level()    == Z_BEST_COMPRESSION);
    ok(209, $x->get_Strategy() == Z_DEFAULT_STRATEGY);
     
    # change both Level & Strategy
    $status = $x->deflateParams(-Level => Z_BEST_SPEED, -Strategy => Z_HUFFMAN_ONLY) ;
    ok(210, $status == Z_OK) ;
    
    ok(211, $x->get_Level()    == Z_BEST_SPEED);
    ok(212, $x->get_Strategy() == Z_HUFFMAN_ONLY);
     
    ($X, $status) = $x->deflate($goodbye) ;
    ok(213, $status == Z_OK) ;
    $Answer .= $X ;
    $input .= $goodbye;
    
    # change only Level 
    $status = $x->deflateParams(-Level => Z_NO_COMPRESSION) ;
    ok(214, $status == Z_OK) ;
    
    ok(215, $x->get_Level()    == Z_NO_COMPRESSION);
    ok(216, $x->get_Strategy() == Z_HUFFMAN_ONLY);
     
    ($X, $status) = $x->deflate($goodbye) ;
    ok(217, $status == Z_OK) ;
    $Answer .= $X ;
    $input .= $goodbye;
    
    # change only Strategy
    $status = $x->deflateParams(-Strategy => Z_FILTERED) ;
    ok(218, $status == Z_OK) ;
    
    ok(219, $x->get_Level()    == Z_NO_COMPRESSION);
    ok(220, $x->get_Strategy() == Z_FILTERED);
     
    ($X, $status) = $x->deflate($goodbye) ;
    ok(221, $status == Z_OK) ;
    $Answer .= $X ;
    $input .= $goodbye;
    
    ok(222, (($X, $status) = $x->flush())[1] == Z_OK ) ;
    $Answer .= $X ;
     
    my ($first, @Answer) = split('', $Answer) ;
     
    my $k;
    ok(223, ($k, $err) = inflateInit()) ;
    ok(224, $k) ;
    ok(225, $err == Z_OK) ;
     
    ($Z, $status) = $k->inflate($Answer) ;

    ok(226, $status == Z_STREAM_END) ;
    ok(227, $Z  eq $input ) ;
}

{
    # error cases

    eval { deflateInit(-Level) };
    ok(228, $@ =~ /^Compress::Zlib::deflateInit: parameter is not a reference to a hash at/);

    eval { inflateInit(-Level) };
    ok(229, $@ =~ /^Compress::Zlib::inflateInit: parameter is not a reference to a hash at/);

    eval { deflateInit(-Joe => 1) };
    ok(230, $@ =~ /^unknown key value\(s\) Joe at/);

    eval { inflateInit(-Joe => 1) };
    ok(231, $@ =~ /^unknown key value\(s\) Joe at/);

    eval { deflateInit(-Bufsize => 0) };
    ok(232, $@ =~ /^.*?: Bufsize must be >= 1, you specified 0 at/);

    eval { inflateInit(-Bufsize => 0) };
    ok(233, $@ =~ /^.*?: Bufsize must be >= 1, you specified 0 at/);

    eval { deflateInit(-Bufsize => -1) };
    ok(234, $@ =~ /^.*?: Bufsize must be >= 1, you specified -1 at/);

    eval { inflateInit(-Bufsize => -1) };
    ok(235, $@ =~ /^.*?: Bufsize must be >= 1, you specified -1 at/);

    eval { deflateInit(-Bufsize => "xxx") };
    ok(236, $@ =~ /^.*?: Bufsize must be >= 1, you specified xxx at/);

    eval { inflateInit(-Bufsize => "xxx") };
    ok(237, $@ =~ /^.*?: Bufsize must be >= 1, you specified xxx at/);

}

