use 5.026003;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'kg::Elections',
    VERSION_FROM      => 'lib/kg/Elections.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
        'CGI'                   => 0,
        'CGI::Cookie'           => 0,
        'Class::Accessor::Lite' => 0,
        'Data::Dump'            => 0,
        'Data::UUID'            => 0,
        'DBI'                   => 0,
        'Digest::SHA1'          => 0,
        'JSON'                  => 0,
        'Template'              => 0,
        'URI::Escape'           => 0,
    },
    ABSTRACT_FROM     => 'lib/kg/Elections.pm', # retrieve abstract from module
    AUTHOR            => 'Kevin M. Goess <cpan@goess.org>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);
