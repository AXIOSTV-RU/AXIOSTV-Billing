#!/usr/bin/perl

#*****************************************************************************

=pod
  Parameters:
    User UID;

  Return:
    IS the user blocked or not
=cut
#*****************************************************************************

use strict;
use warnings;
use DBI;

BEGIN {
  our %conf;
  use FindBin '$Bin';
  require $Bin . '/../libexec/config.pl';
}

our %conf;
my $uid = $ARGV[0] || '';

if ($uid !~ /^\d+$/) {
  die "No user with this UID $uid\n";
}

my $host   = $conf{dbhost};
my $db     = $conf{dbname};
my $dbtype = 'mysql';
my $dbuser = $conf{dbuser};
my $dbpw   = $conf{dbpasswd};

my $dbh = DBI->connect("DBI:$dbtype:$db:$host", $dbuser, $dbpw)
  or die "DB connect failed: $DBI::errstr\n";

my $query = "SELECT internet.disable,
    IFNULL(b.deposit, 0) + IF(u.credit > 0, u.credit, IFNULL(tp.credit, 0))
    FROM internet_main internet
    INNER JOIN users u ON (u.uid=internet.uid)
    LEFT JOIN tarif_plans tp ON (tp.tp_id=internet.tp_id)
    LEFT JOIN bills b ON (u.bill_id = b.id)
    WHERE u.uid = ?
    ORDER BY internet.id DESC
    LIMIT 1";

my $sth = $dbh->prepare($query)
  or die "Prepare failed: $DBI::errstr\n";
$sth->execute($uid)
  or die "Execute failed: $DBI::errstr\n";

my @row_ary = $sth->fetchrow_array();

if (@row_ary) {
  if ($row_ary[0] > 0 || $row_ary[1] <= 0) {
    print "1:Доступ в Интернет ограничен. Воспользуйтесь кредитом";
  }
}
else {
  die "No user with this UID $uid\n";
}
