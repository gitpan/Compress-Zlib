

use vars qw($hello1_uue $hello2_uue) ;

sub ok
{
    my ($no, $ok) = @_ ;

    #++ $total ;
    #++ $totalBad unless $ok ;

    print "ok $no\n" if $ok ;
    print "not ok $no\n" unless $ok ;
}

sub writeFile
{
    my($filename, @strings) = @_ ;
    open (F, ">$filename") 
        or die "Cannot open $filename: $!\n" ;
    binmode(F) if $^O eq 'MSWin32';
    foreach (@strings)
      { print F }
    close F ;
}

sub readFile
{
    my ($filename) = @_ ;
    my ($string) = '' ;
 
    open (F, "<$filename") 
        or die "Cannot open $filename: $!\n" ;
    binmode(F) if $^O eq 'MSWin32';
    while (<F>)
      { $string .= $_ }
    close F ;
    $string ;
}
 

$Inc = '' ;
foreach (@INC)
 { $Inc .= "-I$_ " }
 
$Perl = '' ;
$Perl = ($ENV{'FULLPERL'} or $^X or 'perl') ;
 
$Perl = "$Perl -w" ;
$examples = "./examples";

$hello1 = <<EOM ;
hello
this is 
a test
message
x ttttt
xuuuuuu
the end
EOM

@hello1 = grep(s/$/\n/, split(/\n/, $hello1)) ;

$hello2 = <<EOM;

Howdy
this is the
second
file
x ppppp
xuuuuuu
really the end
EOM

@hello2 = grep(s/$/\n/, split(/\n/, $hello2)) ;

print "1..13\n" ;



# gzcat
# #####

$file1 = "hello1.gz" ;
$file2 = "hello2.gz" ;
unlink $file1, $file2 ;

$hello1_uue = <<'EOM';
M'XL("(W#+3$" VAE;&QO,0#+2,W)R><JR<@L5@ BKD2%DM3B$J[<U.+BQ/14
;K@J%$A#@JB@% Z"Z5(74O!0N &D:".,V    
EOM

$hello2_uue = <<'EOM';
M'XL("*[#+3$" VAE;&QO,@#C\L@O3ZGD*LG(+%8 HI*,5*[BU.3\O!2NM,R<
A5*X*A0(0X*HH!0.NHM3$G)Q*D#*%5* : #) E6<^    
EOM

# Write a test .gz file
{
    local $^W = 0 ;
    writeFile($file1, unpack("u", $hello1_uue)) ;
    writeFile($file2, unpack("u", $hello2_uue)) ;
}

 
$a = `$Perl $Inc ${examples}/gzcat $file1 $file2 2>&1` ;

ok(1, $? == 0) ;
ok(2, $a eq $hello1 . $hello2) ;
#print "? = $? [$a]\n";


# gzgrep
# ######

$a = `$Perl $Inc ${examples}/gzgrep '^x' $file1 $file2 2>&1` ;
ok(3, $? == 0) ;

ok(4, $a eq join('', grep(/^x/, @hello1, @hello2))) ;
#print "? = $? [$a]\n";


unlink $file1, $file2 ;


# filtdef/filtinf
# ##############


$stderr = "err.out" ;
unlink $stderr ;
writeFile($file1, $hello1) ;
writeFile($file2, $hello2) ;

$a = `$Perl $Inc ${examples}/filtdef $file1 $file2 2>$stderr` ;
ok(5, $? == 0) ;
ok(6, -s $stderr == 0) ;

unlink $stderr;
writeFile($file1, $a) ;
$a = `$Perl $Inc ${examples}/filtinf <$file1 2>$stderr` ;
ok(7, $? == 0) ;
ok(8, -s $stderr == 0) ;
ok(9, $a eq $hello1 . $hello2) ;

# gzstream
# ########

{
    writeFile($file1, $hello1) ;
    $a = `$Perl $Inc ${examples}/gzstream <$file1 >$file2 2>$stderr` ;
    ok(10, $? == 0) ;
    ok(11, -s $stderr == 0) ;

    my $b = `$Perl $Inc ${examples}/gzcat $file2 2>&1` ;
    ok(12, $? == 0) ;
    ok(13, $b eq $hello1 ) ;
}


unlink $file1, $file2, $stderr ;