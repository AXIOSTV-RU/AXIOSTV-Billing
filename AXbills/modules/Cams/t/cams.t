#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Test::More;

use AXbills::Base qw/_bp/;
#BEGIN {
#  use FindBin '$Bin';
#  use lib $Bin . '/../';
#}

plan tests => 8;

my $BP_ARGS = { TO_CONSOLE => 1 };

our ($db, $admin, %conf);
require_ok 'libexec/config.pl';
#use_ok('Cams');


open(my $null_fh, '>', '/dev/null') or die('Open /dev/null');
select $null_fh;
#admin interface
$ENV{'REQUEST_METHOD'} = "GET";
$ENV{'QUERY_STRING'} = "user=axbills&passwd=axbills";
require_ok( "../cgi-bin/admin/index.cgi" );
#require_ok( "../AXbills/modules/Cams/webinterface" );
select STDOUT;

do "AXbills/Misc.pm";
use Cams;

my Cams $Cams = new_ok('Cams' => [ $db, $admin, \%conf ]);

my $test_tp_id = 1;
my $test_uid = 2;

#
# DB logic tests
#

my %test_tp = (
  NAME          => 'Test TP',
  STREAMS_COUNT => 1,
);

# Check not added without Abon ID
$Cams->tp_add( \%test_tp );
ok($Cams->{errno}, 'Not adding without Abon ID');

my $check_test_tp_exists_list = $Cams->tp_list( { ID => $test_tp_id } );

SKIP :{
  if ( $check_test_tp_exists_list && scalar @{$check_test_tp_exists_list} > 0 ) {
    $test_tp_id = $check_test_tp_exists_list->[0]->{id};
    skip('Already have test TP', 1);
  }

  $test_tp{ID} = $test_tp_id;
  $test_tp{ABON_ID} = $test_tp_id;
  undef $Cams->{INSERT_ID};
  $Cams->tp_add( { %test_tp, REPLACE => 1 } );
  $test_tp_id = $Cams->{INSERT_ID};
  ok($test_tp_id, 'Inserted new TP');
}

# Change TP
my $tested_tp = $Cams->tp_info( $test_tp_id );
$Cams->tp_change( { ID => $test_tp_id, %{$tested_tp}, STREAMS_COUNT => 2 } );
my $changed_test_tp = $Cams->tp_info( $test_tp_id );

ok($changed_test_tp->{NAME} eq $tested_tp->{NAME}, 'Same name');
ok($changed_test_tp->{STREAMS_COUNT} == 2, 'Changed streams count to 2');

# Enable service for user
# Subscribe user
my $check_test_user_exists = $Cams->user_info( $test_uid );
SKIP : {
  skip ('Already added user', 1) if ($check_test_user_exists);
  my $added_id = $Cams->user_add( { UID => $test_uid, TP_ID => $test_tp_id } );
  ok(!$Cams->{errno}, 'Added user');
}

1;
