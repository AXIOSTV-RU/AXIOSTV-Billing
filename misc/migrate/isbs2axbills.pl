#!/usr/bin/perl -w
# Migration From 
#
#  ISBS (http://www.onlinebilling.ru/#menu) to AbillS
# 2007.08.10
#
# empty password replace with 'xxxx'
#

use DBI;
use strict;

#DB information
my $dbhost   = "127.0.0.1";
my $dbname   = "isbs";
my $dbuser   = "isbs";
my $dbpasswd = "ay17100";


my $ARGV = parse_arguments(\@ARGV);

if (defined($ARGV->{'help'})) {
	help();
	exit 0;
}


my $default_password = $ARGV->{DEFAULT_PASSWORD} || 'xxxx';
my $email_export     = $ARGV->{EMAIL_CREATE} || 1;
my $email_domain_id  = $ARGV->{EMAIL_DOMAIN} || 1;
my $debug            = $ARGV->{DEBUG}        || 0;
my $no_deposit       = $ARGV->{NO_DEPOSIT}   || 0;



my $format = (defined($ARGV[0]) && $ARGV[0] eq 'html') ? 'html' : '';


my $conn = DBI->connect("dbi:Pg:dbname=$dbname", "$dbuser", "$dbpasswd") 
 || die "Unable connect to server '$dbhost'\n" . $DBI::errstr;

#$conn->do("SET DateStyle = 'European'");

my $query = $conn->prepare("SELECT DISTINCT(p.login), 
    CASE WHEN rc.attribute='User-Password' THEN rc.value
     ELSE ''
    END,
     p.fio, 
     p.tel,
     p.email,
     o.addr, 
     o.dog,
     a.acct,
     o.passport,
     o.fax,
     o.descr,
     o.name,
     EXTRACT(EPOCH FROM o.dton),
     p.obid


     FROM person p
     LEFT JOIN object o ON (p.obid = o.obid)
     LEFT JOIN radcheck rc ON (p.login = rc.username)
     LEFT JOIN Account a ON (p.obid = a.obid)
     ORDER BY p.login;");

$query->execute();


my $output = '';
my %login_hash  = ();
my %logins_info = ();


while (my @row = $query->fetchrow_array()) {
#  if ($format eq 'html') {
#	  $output .= "<tr";
#    $output .= " bgcolor='#FF0000' " if (defined($login_hash{$row[0]}));
#	  $output .= ">".  
#	  "<td>$row[0]</td>".
#	  "<td>$row[1]</td>".
#	  "<td>$row[2]</td>".
#	  "<td>$row[3]</td>".
#	  "<td>$row[4]</td>".
#	  "<td>$row[5]</td>".
#	  "<td>$row[6]</td>".
#	  "<td>$row[7]</td>".
#	  "<td>Migration</td>".
#	  "<td>PASSPORT: $row[8] FAX: $row[9] DESC: $row[10]</d>".
#	  "<td>$row[0]\@$email_domain</td>".
#	  "<td>$row[1]</td>".
#	  "</tr>\n";
#   }
#  else {
#    $row[10] .= 'SOME DUBLICATION' if (defined($login_hash{$row[0]}));
#    $output .= "$row[0]\t$row[1]".
#       "\t3.FIO=\"$row[2]\"".
#       "\t3.PHONE=\"$row[3]\"".
#       "\t3.EMAIL=\"$row[4]\"".
#       "\t3.ADDRESS_STREET=\"$row[5]\"".
#       "\t3.CONTRACT_ID=\"$row[6]\"".
#       "\t5.SUM=\"$row[7]\"".
#       "\t5.DESCIRIBE=\"Migration\"".
#       "\t3.COMMENTS=\"PASPORT: $row[8] FAX: $row[9] DESCR: $row[10]\"".
#       "\t6.USERNAME=\"$row[0]\@ate.ru\"".
#       "\t6.PASSWORD=\"$row[1]\"".
#       "\n";
#   }

  if (defined($logins_info{$row[0]}{'UPDATED'}) && $logins_info{$row[0]}{'UPDATED'} >= $row[12]){
    #print "$logins_info{$row[0]}{'UPDATED'} / $row[12]";
  	next;
   }
  else {
  	#print " $row[12]";
   }


  $logins_info{$row[0]}{'LOGIN'}            = $row[0] || '';
  $logins_info{$row[0]}{'PASSWORD'}         = $row[1] || $default_password;
  $logins_info{$row[0]}{'3.FIO'}            = $row[2] || '';

#  $logins_info{$row[0]}{'3.PHONE'}          = $row[3] || '';
  $logins_info{$row[0]}{'3.EMAIL'}          = $row[4] || '';
  $logins_info{$row[0]}{'3.ADDRESS_STREET'} = $row[5] || '';
  $logins_info{$row[0]}{'3.ADDRESS_STREET'} =~ s/\n//g;
  $logins_info{$row[0]}{'3.ADDRESS_STREET'} =~ s/\r//g;

  $logins_info{$row[0]}{'3.CONTRACT_ID'}    = $row[6] || '';

  if ($no_deposit == 0) {
    $logins_info{$row[0]}{'5.SUM'}            = $row[7] || '';
    $logins_info{$row[0]}{'5.DESCIRIBE'}      = 'Migration';
   }

  $logins_info{$row[0]}{'3.COMMENTS'}       = "PASPORT: ". (($row[8])? $row[8] : ''). 
                                              (($row[9])? " FAX: $row[9]" : '') . 
                                              (($row[10])? " DESCR: $row[10]" : '').
                                              (($row[3]) ? " TEL: $row[3]" : '');

  $logins_info{$row[0]}{'3.COMMENTS'} =~ s/\n//g;
  $logins_info{$row[0]}{'3.COMMENTS'} =~ s/\r//g;


  if ($email_export == 1) {
    $logins_info{$row[0]}{'6.USERNAME'}       = "$row[0]";
    $logins_info{$row[0]}{'6.DOMAIN_ID'}      = $email_domain_id;
    $logins_info{$row[0]}{'6.PASSWORD'}       = $row[1]  || '';
   }

  $logins_info{$row[0]}{'99.OBID'}          = $row[13] || '';
  $logins_info{$row[0]}{'UPDATED'}          = $row[12] || 1;

  $login_hash{$row[0]}++;
}


my %exaption = ('LOGIN'    => 1,
                'PASSWORD' => 2
                );

my @titls = sort keys %logins_info;
my $login =  $titls[0];
@titls = sort keys  %{ $logins_info{$login} };


if ($format eq 'html') {
	$output = "<table border=1>\n".
	"<tr><th>LOGIN</th>
	<th>PASSWORD</th>\n";

  foreach my $column_title ( @titls ) {
  	next if($exaption{$column_title});
  	$output .= "<th>$column_title</th>\n";
   }

  $output .= "</tr>\n";
}

my $counts = 0;
#while(my ($login, $hash) = each %logins_info) {

foreach my $login (sort keys %logins_info) {
  print "$login\n" if ($debug > 0);

  if ($format eq 'html') {
    $output .= "<tr><td>$logins_info{$login}{'LOGIN'}</td><td>$logins_info{$login}{'PASSWORD'}</td>";  
    foreach my $column_title ( @titls ) { 
    	next if($exaption{$column_title});
  	  $output .= "<td>$logins_info{$login}{$column_title}</td>";  
     }
	  $output .= "</tr>\n";  
   }
  else {
  	$output .= "$logins_info{$login}{'LOGIN'}\t$logins_info{$login}{'PASSWORD'}\t";
    foreach my $column_title ( @titls ) { 
    	next if($exaption{$column_title});
  	  $output .= "$column_title=\"". $logins_info{$login}{$column_title} ."\"\t";  
     }
    $output .= "\n";
   }

  $counts++;
}

if ($format eq 'html') {
	$output .= "</table>\n";
}

print "$output\n";
print "ROWS: $counts\n";
#print $query->rows();
#print "\n";

undef($query);
$conn->disconnect();
$conn = undef;



#*******************************************************************
# Parse comand line arguments
# parse_arguments(@$argv)
#*******************************************************************
sub help {

print << "[END]";
AXbills Система миграции
(https://billing.axiostv.ru)

  Options:
    DEBUG             - debug
    DEFAULT_PASSWORD  - default  password for empty passwords
    EMAIL_CREATE      - create email accounts
    EMAIL_DOMAIN      - AXbills E-mail domain ( CHECK '/ System configuration/ E-MAIL/ Domains/' )
    DEBUG             - Enable debug
    NO_DEPOSIT        - Don't transfer deposit
    help              - This help
[END]

}

#*******************************************************************
# Parse comand line arguments
# parse_arguments(@$argv)
#*******************************************************************
sub parse_arguments {
    my ($argv) = @_;
    
    my %args = ();

    foreach my $line (@$argv) {
    	if($line =~ /=/) {
    	   my($k, $v)=split(/=/, $line, 2);
    	   $args{"$k"}=(defined($v)) ? $v : '';
    	 }
    	else {
    		$args{"$line"}=1;
    	 }
     }
  return \%args;
}
