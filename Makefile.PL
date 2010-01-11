use ExtUtils::MakeMaker;

opendir (SCRIPTS, 'bin') or die "couldn't open 'bin': $!\n";
my @scripts = grep { /^[^\.]/ } readdir SCRIPTS;
closedir SCRIPTS;
map { s%^%bin/% } @scripts;

WriteMakefile(
    NAME              => 'Remedy::CMDB',
    DISTNAME          => 'Remedy-CMDB',
    ABSTRACT_FROM     => "lib/Remedy/CMDB.pm",
    dist              => { COMPRESS => 'gzip', SUFFIX => 'gz' },
    VERSION_FROM      => 'lib/Remedy/CMDB.pm', 
    EXE_FILES         => \@scripts,
    AUTHOR            => 'Tim Skirvin <tskirvin@stanford.edu>',
    PREREQ_PM         => { 
      'Remedy'              => '0.13.05',
      'Lingua::EN::Inflect' => '1.89',
      'Log::Log4perl'       => '1.07',
                         }, 
);
