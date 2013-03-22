
use strict;
use warnings;

use 5.006;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "a LWP::UserAgent suitable for simulating and testing network calls",
  "AUTHOR" => "Karen Etheridge <ether\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Class::Load" => 0,
    "File::Find" => 0,
    "File::Temp" => 0,
    "HTTP::Request::Common" => 0,
    "Path::Tiny" => 0,
    "Test::CheckDeps" => "0.002",
    "Test::Deep" => "0.110",
    "Test::Fatal" => 0,
    "Test::More" => "0.88",
    "Test::NoWarnings" => "1.04",
    "Test::Requires" => 0,
    "Test::TempDir" => 0,
    "Test::Warn" => 0,
    "overload" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Test-LWP-UserAgent",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Test::LWP::UserAgent",
  "PREREQ_PM" => {
    "Carp" => 0,
    "HTTP::Date" => 0,
    "HTTP::Request" => 0,
    "HTTP::Response" => 0,
    "HTTP::Status" => 0,
    "LWP::UserAgent" => 0,
    "Safe::Isa" => 0,
    "Scalar::Util" => 0,
    "Storable" => 0,
    "Try::Tiny" => 0,
    "URI" => 0,
    "namespace::clean" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.017",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



