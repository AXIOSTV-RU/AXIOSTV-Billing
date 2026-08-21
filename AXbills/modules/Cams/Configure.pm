=head1 NAME

  Cams configure

=cut

use strict;
use warnings FATAL => 'all';
use Cams;
use AXbills::Filters qw(_utf8_encode);
use AXbills::Base qw(_bp);

our (
  $html,
  %lang,
  $db,
  $admin,
  %conf,
  %FORM,
  $pages_qs,
  $index
);

my $Cams = Cams->new($db, $admin, \%conf);

#**********************************************************
=head2 cams_tp()

=cut
#**********************************************************
sub cams_tp {

  require Control::Services;

  my %TEMPLATE_CAMS_TP = ();
  my $show_add_form = $FORM{add_form} || 0;
  my %payment_types = (0 => $lang{PREPAID}, 1 => $lang{POSTPAID});

  if ($FORM{add}) {
    $Cams->tp_add({ %FORM });
    $show_add_form = !show_result($Cams, $lang{ADDED});
  }
  elsif ($FORM{change}) {
    $FORM{PTZ} = 0 if !$FORM{PTZ};
    $FORM{DVR} = 0 if !$FORM{DVR};
    $FORM{TP_ID} = _cams_get_tp_id($FORM{ID});
    $Cams->tp_change({ %FORM }) if $FORM{TP_ID};
    show_result($Cams, $lang{CHANGED});
    $show_add_form = 1;
  }
  elsif ($FORM{chg}) {
    my $tp_info = $Cams->tp_info($FORM{chg});
    if (!_error_show($Cams)) {
      %TEMPLATE_CAMS_TP = %{$tp_info ? $tp_info : {}};
      $show_add_form = 1;
    }
    $TEMPLATE_CAMS_TP{PTZ} = 'checked' if $TEMPLATE_CAMS_TP{PTZ};
    $TEMPLATE_CAMS_TP{DVR} = 'checked' if $TEMPLATE_CAMS_TP{DVR};
    $TEMPLATE_CAMS_TP{PERIOD_ALIGNMENT} = 'checked' if $TEMPLATE_CAMS_TP{PERIOD_ALIGNMENT};
  }
  elsif ($FORM{del}) {
    $FORM{TP_ID} = _cams_get_tp_id($FORM{del});
    $Cams->tp_del({ TP_ID => $FORM{TP_ID} }) if $FORM{TP_ID};
    show_result($Cams, $lang{DELETED});
  }

  my $service_select = $html->form_select('SERVICE_ID', {
    SELECTED  => $TEMPLATE_CAMS_TP{SERVICE_ID} || q{},
    SEL_LIST  => $Cams->services_list({
      NAME      => '_SHOW',
      COLS_NAME => 1
    }),
    SEL_NAME  => 'name',
    SEL_KEY   => 'id',
    NO_ID     => 1,
    EX_PARAMS => 'required="required"',
  });

  if ($show_add_form) {
    $TEMPLATE_CAMS_TP{PAYMENT_TYPE_SEL} = $html->form_select('PAYMENT_TYPE', {
      SELECTED => $TEMPLATE_CAMS_TP{PAYMENT_TYPE},
      SEL_HASH => \%payment_types,
    });
    $TEMPLATE_CAMS_TP{NEXT_TARIF_PLAN_SEL} = sel_tp({
      MODULE          => 'Cams',
      SELECT          => 'NEXT_TARIF_PLAN',
      NEXT_TARIF_PLAN => $TEMPLATE_CAMS_TP{NEXT_TARIF_PLAN},
    });
    $TEMPLATE_CAMS_TP{ARCHIVE_SELECT} = _cams_archive_select({ SELECTED => $TEMPLATE_CAMS_TP{ARCHIVE} });

    $html->tpl_show(_include('cams_tp', 'Cams'), {
      %TEMPLATE_CAMS_TP,
      SERVICE_TP        => $service_select,
      SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
      SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
    });
  }

  result_former({
    INPUT_DATA      => $Cams,
    FUNCTION        => 'tp_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'NAME,SERVICE_NAME,COMMENTS,STREAMS_COUNT,MONTH_FEE,PAYMENT_TYPE,ACTIV_PRICE,CHANGE_PRICE',
    HIDDEN_FIELDS   => 'ID,TP_ID,SERVICE_ID',
    FUNCTION_FIELDS => 'change,del',
    EXT_TITLES      => {
      name           => $lang{TARIF_PLAN},
      service_name   => $lang{SERVICE},
      comments       => $lang{COMMENTS},
      streams_count  => $lang{MAX} . " " . $lang{STREAMS_COUNT},
      payment_type   => $lang{PAYMENT_TYPE},
      month_fee      => $lang{MONTH_FEE},
      month_fee      => $lang{MONTH_FEE},
      activate_price => $lang{ACTIVATE},
      change_price   => $lang{CHANGE},
    },
    FILTER_COLS     => { payment_type => '_cams_show_payment_type' },
    TABLE           => {
      width   => '100%',
      caption => "$lang{CAMERAS}: $lang{TARIF_PLANS}",
      qs      => $pages_qs,
      ID      => 'CAMS_TPS',
      MENU    => "$lang{ADD}:index=$index&add_form=1" . ':add',
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1,
    MODULE          => 'Cams'
  });

  return 0;
}

#**********************************************************
=head2 _cams_show_payment_type()

=cut
#**********************************************************
sub _cams_show_payment_type {
  my ($type) = @_;

  return $type ? $lang{POSTPAID} : $lang{PREPAID};
}

#**********************************************************
=head2 _cams_get_tp_id()

=cut
#**********************************************************
sub _cams_get_tp_id {
  my ($id) = @_;

  my $tp_info = $Cams->tp_info($id);
  return $tp_info->{TP_ID} if !_error_show($Cams);

  return 0;
}

#**********************************************************
=head2 cams_get_service_groups($attr)

  Arguments:

  Returns:

=cut
#**********************************************************
sub cams_get_service_groups {

  print _cams_groups_select({
    SELECTED     => $FORM{GROUP_ID} || 1,
    SERVICE_ID   => $FORM{SERVICE_ID},
    ONLY_SERVICE => 1
  });

  return 1;
}


1;
