package Docs::Init;
=head1

  Docs Init module

=cut

use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

our @EXPORT = qw(
  init_esign_service
);

our @EXPORT_OK = qw(
  init_esign_service
);

#**********************************************************
=head2 init_esign_service($db, $admin, $conf)

=cut
#**********************************************************
sub init_esign_service {
  my ($db, $admin, $conf, $attr) = @_;

  if (!$conf->{DOCS_ESIGN}) {
    return {
      errno  => 1054017,
      errstr => 'ESIGN_SERVICE_NOT_CONNECTED'
    };
  }

  my %esign_services = (
    DOCS_DIIA_ACQUIRER_TOKEN => 'Diia',
  );

  my $ESignService = {};

  foreach my $config_key (sort keys %esign_services) {
    next if !$conf->{$config_key};

    $ESignService = $esign_services{$config_key};

    eval {require "Docs/Plugin/$ESignService.pm";};

    $ESignService = "Docs::Plugin::$ESignService";

    if (!$@) {
      $ESignService->import();
      $ESignService = $ESignService->new($db, $admin, $conf, $attr);

      if ($ESignService->can('init') && !$ESignService->init()) {
        $ESignService->{errno} = 1054001;
        $ESignService->{errstr} = 'ESIGN_SERVICE_BAD_CONFIGURATION';
      }
    }
    else {
      print $@ if (!$attr->{SILENT});
    }

    last;
  }

  if (!%$ESignService) {
    $ESignService = {};
    $ESignService->{errno} = 1054002;
    $ESignService->{errstr} = 'ESIGN_SERVICE_NOT_CONNECTED';
  }

  return $ESignService;
}

1;
