#! perl -w

use strict ;
require 5.004 ;

$::VERSION = '2.014' ;

use private::MakeUtil;
use ExtUtils::MakeMaker 5.16 ;


UpDowngrade(getPerlFiles('MANIFEST')) 
    unless $ENV{PERL_CORE};

# Modules supplied by this distribution    
my @myModules = qw( Compress::Zlib);

# Direct dependencies                  
my @MainPREREQ = qw(Compress::Raw::Zlib
                    IO::Compress::Base
                    IO::Compress::Base::Constants
                    IO::Uncompress::Base
                    IO::Compress::Gzip
                    IO::Compress::Gzip::Constants
                    IO::Uncompress::Gunzip
                   );

# Get indirect dependencies that will break if we install this version
push @MainPREREQ, FindBrokenDependencies($::VERSION, @myModules)
    unless $ENV{PERL_CORE} ;                   
    
my %MainPREREQ = map { $_ => $::VERSION } @MainPREREQ; 

WriteMakefile( 
    NAME         => 'Compress::Zlib',
    VERSION_FROM => 'lib/Compress/Zlib.pm',
    'dist'       => { COMPRESS     => 'gzip', 
                      TARFLAGS     => '-chvf',
                      SUFFIX       => 'gz',
                      DIST_DEFAULT => 'MyTrebleCheck tardist',
                    },

    (
      $ENV{SKIP_FOR_CORE}
        ? (MAN3PODS    => {})
	    : (PREREQ_PM   => { %MainPREREQ,
		                    'Scalar::Util'                  => 0,
                          }
	      )
    ),
       
    (
    $] >= 5.005
        ? (ABSTRACT_FROM => 'lib/Compress/Zlib.pm',
            AUTHOR       => 'Paul Marquess <pmqs@cpan.org>')
        : ()
    ),

    INSTALLDIRS => ($] >= 5.009 ? 'perl' : 'site'),

    (
    $] >= 5.009 && ! $ENV{PERL_CORE}
        ? (INST_LIB    => 'blib/arch')
        : ()
    ),

    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
        ('LICENSE'  => 'perl')         : ()),    

) ;

# Check for Compress::Zlib version 1.
eval  "require Compress::Zlib; " ;
if ( ! $ENV{PERL_CORE} && ! $@ && $Compress::Zlib::VERSION < 2)
{
    my $ver = $Compress::Zlib::VERSION ;
    print <<EOM

I see you already have Compress::Zlib version $ver installed.
Version 1 MUST be removed for version 2 to operate correctly.

The easiest way to do that is to install Compress::Zlib like this

    make install UNINST=1

If you run the CPAN shell run this before installing Compress::Zlib

    o conf make_install_arg UNINST=1

EOM
}

# end of file Makefile.PL

