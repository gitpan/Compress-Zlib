BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't' if -d 't';
        @INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict ;
use warnings ;

use Test::More ;


sub gotScalarUtilXS
{
    eval ' use Scalar::Util "dualvar" ';
    return $@ ? 0 : 1 ;
}


BEGIN
{
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };


    my $VERSION = '2.015';
    my @NAMES = qw(
			Compress::Raw::Zlib
			IO::Compress::Base
			IO::Compress::Gzip
			IO::Uncompress::Gunzip
			);

    my @OPT = qw(
			
			);

    plan tests => 2 + @NAMES + @OPT + $extra ;

    foreach my $name (@NAMES)
    {
        use_ok($name, $VERSION);
    }


    foreach my $name (@OPT)
    {
        eval " require $name " ;
        if ($@)
        {
            ok 1, "$name not available" 
        }
        else  
        {
            my $ver = eval("\$${name}::VERSION");
            is $ver, $VERSION, "$name version should be $VERSION" 
                or diag "$name version is $ver, need $VERSION" ;
        }         
    }
    
    use_ok('Scalar::Util') ;
}


ok gotScalarUtilXS(), "Got XS Version of Scalar::Util"
    or diag <<EOM;
You don't have the XS version of Scalar::Util
EOM

