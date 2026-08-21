# mkdir /usr/axbills/var/sorm/abonents/
# mkdir /usr/axbills/var/sorm/payments/
# mkdir /usr/axbills/var/sorm/wi-fi/
# mkdir /usr/axbills/var/sorm/dictionaries/
#
# $conf{BILLD_PLUGINS} = 'sorm3';
# $conf{SORM3_TYPE} = 'spectech';  # spectech | norsi | citadel | mfisoft
# $conf{SORM3_TABLE_PREFIX} = 'SPECTECH';  # optional, default from TYPE
# $conf{SORM3_EXPORT_DIR}   = 'Spectech';  # optional, subdir under var/sorm
#
# cron: /usr/axbills/libexec/billd sorm3
# override: /usr/axbills/libexec/billd sorm3 TYPE=mfisoft
=head1 NAME

  SORM3 sync

  Unified billd plugin for SORM vendors.
  Types: spectech, norsi (Sorm3::Sorm backend), citadel, mfisoft (legacy export).

=head1 VERSION

  VERSION: 1.22
  DATETIME: 20260519

=head1 ARGUMENTS

  INIT -  Init dirs
  START - START
  DICTIONARIES
  WIFI
  SHOW_ERRORS - Get errors
  REPORT - Add only one report
  TYPE=spectech|norsi|citadel|mfisoft  - overrides $conf{SORM3_TYPE}

=cut

use strict;
use warnings FATAL => 'all';

use Net::FTP;

our (
  %conf,
  $db,
  $users,
  $var_dir,
  $base_dir,
  $argv,
  @MODULES,
);

our $Admin;

my %SORM3_TYPES = (
  spectech => {
    class_file  => 'Spectech',
    class_ns    => 'Sorm',
    conf_prefix => 'SPECTECH',
  },
  norsi => {
    class_file  => 'Norsi',
    class_ns    => 'Sorm',
    conf_prefix => 'NORSI',
  },
  citadel => {
    class_file  => 'Citadel',
    class_ns    => 'Sorm',
    conf_prefix => 'CITADEL',
    extra_prefixes => [ 'SORM' ],
  },
  mfisoft => {
    class_file  => 'Mfisoft',
    class_ns    => 'Sorm',
    conf_prefix => 'MFISOFT',
    extra_prefixes => [ 'SORM' ],
  },
);

my @SORM3_CONF_KEYS = qw(
  SERVER LOGIN PASSWORD
  ERR_LOGIN ERR_PASSWORD
  ISP_ID ISP_DESCRIPTION DEFAULT_ZIP COUNTRY REGION ZONE
  TIME_OFFSET ARCHIVE ARCHIVE_PATH BACKBON_IP_PLAN
  UPLOAD_USER_3_YEAR FTP_TIMEOUT FTP_PASSIVE_MODE FTP_BINNARY
);

my $debug = 0;
if ($argv->{DEBUG}) {
  $debug = $argv->{DEBUG};
}

my $type_key = lc($argv->{TYPE} || $conf{SORM3_TYPE} || '');
$type_key =~ s/^\s+|\s+$//g;

my $spec = $SORM3_TYPES{$type_key};
my $server_ip = $conf{SORM3_SERVER} || '127.0.0.1';
my $login     = $conf{SORM3_LOGIN}  || 'login';
my $pswd      = $conf{SORM3_PASSWORD} || 'password';

if (!$type_key) {
  print "SORM3: set \$conf{SORM3_TYPE} or pass TYPE=spectech|norsi|citadel|mfisoft\n";
}
elsif (!$spec) {
  print "SORM3: unknown type '$type_key'. Supported: " . join(', ', sort keys %SORM3_TYPES) . "\n";
}
else {
  if ($spec->{module}) {
    unshift(@INC, ($base_dir || '/usr/axbills/') . "AXbills/modules/$spec->{module}");
  }


  foreach my $key (@SORM3_CONF_KEYS) {
    my $sorm3_key = "SORM3_$key";
    my @aliases = ("$spec->{conf_prefix}_$key");
    push @aliases, map { $_ . "_$key" } @{$spec->{extra_prefixes} || []};

    if (defined $conf{$sorm3_key}) {
      $conf{$_} = $conf{$sorm3_key} for @aliases;
    }
    else {
      foreach my $alias (@aliases) {
        next if !defined $conf{$alias};
        $conf{$sorm3_key} = $conf{$alias};
        $conf{$_} = $conf{$alias} for @aliases;
        last;
      }
    }
  }

  $server_ip = $conf{SORM3_SERVER} || '127.0.0.1';
  $login     = $conf{SORM3_LOGIN}  || 'login';
  $pswd      = $conf{SORM3_PASSWORD} || 'password';

  if ($debug > 1) {
    print "SORM3 type=$type_key class=$spec->{class_ns}::$spec->{class_file} ftp=$server_ip\n";
  }

  my $class_file = $spec->{class_file};
  my $require_path = "$base_dir/AXbills/modules/Sorm3/$class_file.pm";

  if (eval {
    require $require_path;
    1;
  }) {
    my $class = $spec->{class_ns} . '::' . $class_file;
    $class->new(\%conf, $db, $Admin, $argv);
  }
  else {
    print $@;
  }
}

#**********************************************************
=head2 _ftp_upload($file, $attr) - Init base parameters

  Arguments:
    $attr
      FILE
      DIR
      ICONV - base_file:distination_file

  Returns:
    TRUE FALSE

=cut
#**********************************************************
sub _ftp_upload {
  my ($attr) = @_;

  if ($attr->{ICONV}) {
    my $cmd = "iconv -f UTF-8 -t CP1251 $attr->{ICONV}";
    if ($debug > 2) {
      print " $cmd\n";
    }
    system($cmd);
  }

  if ($debug > 1) {
    print "Connect: SERVER: $server_ip LOGIN: $login PASSWORD: $pswd\n";
  }

  my $file = $attr->{FILE} || q{};
  print "Send $file\n";

  my $ftp = Net::FTP->new($server_ip, Debug => 0, Passive => $conf{FTP_PASSIVE_MODE} || 0)
    or die "Cannot connect to $server_ip: $@";
  $ftp->login($login, $pswd) or die "Cannot login ", $ftp->message;
  if ($attr->{DIR}) {
    $ftp->cwd($attr->{DIR}) or die "Cannot change working directory ", $ftp->message;
  }
  $ftp->put($file) or die "$file put failed ", $ftp->message;
  print $ftp->message;
  $ftp->quit;

  return 1;
}

#**********************************************************
=head2 _date_format($attr)

=cut
#**********************************************************
sub _date_format {
  my ($date) = @_;

  $date =~ s/(\d{4})-(\d{2})-(\d{2})(.*)/$3.$2.$1$4/;

  return $date;
}

1
