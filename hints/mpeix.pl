# Hints file for Compress::Zlib on MPE/iX (HP3000)
# Ken Hirsch <kenhirsch@ftml.net>
# 2005-09-27
# This hints file should not be necessary for future
# versions of Compress::Zlib that do not use gzio.c
  
my $define = $self->{DEFINE} || "";
my $ccflags = $self->{CCFLAGS} || $Config{ccflags};
unless ($ccflags =~ /vsnprintf/i || $define =~ /vsnprintf/i) {
  $ccflags .= " -DNO_vsnprintf";
}
$self->{CCFLAGS} = $ccflags;

