#! perl -w
use strict ;
require 5.004 ;
use ExtUtils::MakeMaker 5.16 ;
use Config ;

my $ZLIB_LIB ;
my $ZLIB_INCLUDE ;

ParseCONFIG() ;

WriteMakefile(	
	NAME   	 	=> 'Compress::Zlib',
	VERSION_FROM  	=> 'Zlib.pm',
	LIBS	 	=> [ "-L$ZLIB_LIB -lz " ],
	INC      	=> "-I$ZLIB_INCLUDE" ,
	'dist'	 	=> {COMPRESS=>'gzip', SUFFIX=>'gz'},
	) ;

sub MY::postamble {
	'
Zlib.xs:	typemap
	@$(TOUCH) Zlib.xs

Makefile:	config.in

' ;
}


sub ParseCONFIG
{
    my ($k, $v) ;
    my @badkey = () ;
    my %Info = () ;
    my @Options = qw( INCLUDE LIB ) ;
    my %ValidOption = map {$_, 1} @Options ;
    my %Parsed = %ValidOption ;
    my $CONFIG = 'config.in' ;

    print "Parsing $CONFIG...\n" ;

    open(F, "$CONFIG") or die "Cannot open file $CONFIG: $!\n" ;
    while (<F>) {
	s/^\s*|\s*$//g ;
	next if /^\s*$/ or /^\s*#/ ;
	s/\s*#\s*$// ;

	($k, $v) = split(/\s+=\s+/, $_, 2) ;
	$k = uc $k ;
	if ($ValidOption{$k}) {
	    delete $Parsed{$k} ;
	    $Info{$k} = $v ;
	}
	else {
	    push(@badkey, $k) ;
	}
    }
    close F ;

    print "Unknown keys in $CONFIG ignored [@badkey]\n"
	if @badkey ;

    # check parsed values
    my @missing = () ;
    die "The following keys are missing from $CONFIG file: [@missing]\n" 
        if @missing = keys %Parsed ;

    $ZLIB_INCLUDE = $ENV{'ZLIB_INCLUDE'} || $Info{'INCLUDE'} ;
    $ZLIB_LIB = $ENV{'ZLIB_LIB'} || $Info{'LIB'} ;

    print <<EOM if 0 ;
    INCLUDE	[$ZLIB_INCLUDE]
    LIB		[$ZLIB_LIB]

EOM

    print "Looks Good.\n" ;

}

# end of file Makefile.PL
