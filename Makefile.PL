require 5.004 ;
use ExtUtils::MakeMaker 5.16 ;
use Config ;

# If libz is not installed in some place obvious, uncomment the next
# line and change the path to point to the directory where libz is
# installed.

#$ZLIB_LIB     = '-L/usr/local/lib' ;
#$ZLIB_LIB     = '-L./zlib-1.1.3' ;

# Change the path on the next line to point to the directory where
# zlib.h and zconf.h can be found.

#$ZLIB_INCLUDE = '-I/usr/local/include' ;
#$ZLIB_INCLUDE     = '-L./zlib-1.1.3' ;


# It shouldn't be necessary to change anything from here on.

WriteMakefile(	
                NAME   	 	=> 'Compress::Zlib',
		VERSION_FROM  	=> 'Zlib.pm',
		LIBS	 	=> [ "$ZLIB_LIB -lz " ],
	      	INC      	=> " $ZLIB_INCLUDE" ,
		'dist'	 	=> {COMPRESS=>'gzip', SUFFIX=>'gz'},
	    ) ;



