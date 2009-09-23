use ExtUtils::MakeMaker;

# Touch auto-generated files so we don't see warnings.
open(CHANGES, ">>CHANGES") and close CHANGES;
open(README, ">>README")   and close README;
open(META, ">>META.yml")   and close META;

WriteMakefile(
  NAME         => 'Reflex',
  AUTHOR       => 'Rocco Caputo <rcaputo@cpan.org>',
  ABSTRACT     => 'Reactive classes for flexible programs.',
  LICENSE      => 'perl',
  VERSION_FROM => 'lib/Reflex.pm',
  PREREQ_PM    => {
    'Scalar::Util'  => 1.21,
    'POE'           => 1.268,
    'Test::More'    => 0.94,
		'Moose'         => 0.92,
  },
  META_ADD     => {
    resources  => {
      license    => 'http://dev.perl.org/licenses/',
      repository => 'http://github.com/rcaputo/reflex',
    },
  },
  dist         => {
    COMPRESS   => 'gzip -9f',
    SUFFIX     => 'gz',
    PREOP      => (
      'git-log.pl | tee ./$(DISTNAME)-$(VERSION)/CHANGES > ./CHANGES;' .
      'LANG=C perldoc lib/Reflex.pm > README'
    ),
  },
);
