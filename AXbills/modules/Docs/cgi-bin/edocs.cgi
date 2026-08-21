#!/usr/bin/perl

=head1 NAME

  Docs esign processing system
  Validating of requests

=cut

use strict;
use warnings;

our (
  %conf,
  $DATE,
  $TIME,
  $base_dir,
  %lang,
  @MODULES,
  %FORM,
  %COOKIES
);

BEGIN {
  use FindBin '$Bin';
  require $Bin . '/../libexec/config.pl';
  unshift(@INC,
    $Bin . '/../',
    $Bin . '/../lib/',
    $Bin . '/../AXbills',
    $Bin . '/../AXbills/mysql',
    $Bin . '/../AXbills/modules',
  );

  foreach my $module (@MODULES) {
    unshift(@INC, $Bin . "/../AXbills/modules/$module/config");
  }
}

use AXbills::Defs;
use AXbills::JSON;
use Admins;
use AXbills::Base qw(json_former _bp check_ip);

our $db = AXbills::SQL->connect(@conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });
our $admin = Admins->new($db, \%conf);

use Docs::Init qw(init_esign_service);
our $html = AXbills::HTML->new({
  IMG_PATH   => 'img/',
  NO_PRINT   => 1,
  CONF       => \%conf,
  CHARSET    => $conf{default_charset},
  HTML_STYLE => $conf{UP_HTML_STYLE},
});

_start();

#**********************************************************
=head2 _start()

=cut
#**********************************************************
sub _start {

  my %res = (success => 'true');
  my $response_status = 200;

  # if (!$conf{DOCS_DIIA_IPS} || !$ENV{REMOTE_ADDR} || ($ENV{REMOTE_ADDR} && !check_ip($ENV{REMOTE_ADDR}, $conf{DOCS_DIIA_IPS}))) {
  #   print AXbills::JSON::header(undef, { STATUS => 403 });
  #   $res{success} = 'false';
  #   print json_former(\%res, { BOOL_VALUES => 1 });
  #   return 0;
  # }

  require Docs::Init;
  Docs::Init->import('init_esign_service');

  my $ESignService = init_esign_service($db, $admin, \%conf, {
    lang   => \%lang,
    html   => $html,
    SILENT => 1
  });

  if ($ESignService->{errno} || !$ESignService->can('verify_external_signatures')) {
    $response_status = 400;
    $res{success} = 'false';
    my $res = json_former(\%res, { BOOL_VALUES => 1 });

    print AXbills::JSON::header(undef, { STATUS => $response_status });
    print $res;
    return;
  }

  $ESignService->verify_external_signatures($FORM{encodeData}, $ENV{HTTP_X_DOCUMENT_REQUEST_TRACE_ID});

  if ($ESignService->{errno}) {
    $response_status = 400;
    $res{success} = 'false';
    my $res = json_former(\%res, { BOOL_VALUES => 1 });

    print AXbills::JSON::header(undef, { STATUS => $response_status });
    print $res;
    return;
  }

  my $res = json_former(\%res, { BOOL_VALUES => 1 });
  print AXbills::JSON::header(undef, { STATUS => $response_status });
  print $res;

  return 1;
}

1;
