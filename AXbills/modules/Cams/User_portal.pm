=head1 NAME

  Cams User portal

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(in_array next_month convert _bp);

our (
  %lang,
  $Cams_service,
  $db,
  $admin,
  @service_status,
  $Cams,
  $users_
);


our AXbills::HTML $html;

$Cams = Cams->new($db, $admin, \%conf);
$users_ = Users->new($db, $admin, \%conf);

#**********************************************************
=head2 cams_user_info() - Cams user interface

=cut
#**********************************************************
sub cams_user_info {

  my %PORTAL_ACTIONS = ();
  my $service_list = $Cams->services_list({ USER_PORTAL => '>0', COLS_NAME => 1 });

  return 1 if (!$Cams->{TOTAL});

  foreach my $service (@$service_list) {
    $PORTAL_ACTIONS{$service->{id}} = $service->{user_portal};
  }

  $Cams->{ACTION} = 'add';
  $Cams->{LNG_ACTION} = $lang{ADD};

  $FORM{UID} = $user->{UID} ? $user->{UID} : "";
  $FORM{USER_INFO} = $user;
  my $user_groups = '';

  if ($FORM{add}) {
    if (!$FORM{SERVICE_ID}) {
      $html->message('err', $lang{ERROR}, $lang{CHOOSE_SERVICE});
      return 1;
    }

    $Cams->{db}{db}->{AutoCommit} = 0;
    $Cams->{db}->{TRANSACTION} = 1;
    $Cams->users_list({
      UID   => $FORM{UID} || "",
      TP_ID => $FORM{TP_ID} || 0,
    });

    if ($Cams->{TOTAL}) {
      $html->message('err', $lang{ERROR}, "This tariff already used");
      return 1;
    }

    $Cams->user_add({
      UID    => $FORM{UID} || "",
      TP_ID  => $FORM{TP_ID} || 0,
      STATUS => $FORM{STATUS} || 0
    });

    show_result($Cams, $lang{ADDED});
    if (!$Cams->{errno}) {
      $Cams->{ID} = $Cams->{INSERT_ID};

      if (!$FORM{STATUS}) {
        $Cams->_info($Cams->{ID});

        if ($Cams->{ACTIVATE}) {
          ($Cams->{ACTIVATE}, undef) = split(" ", $Cams->{ACTIVATE});
        }

        ::service_get_month_fee($Cams, {
          UID                        => $FORM{UID} || $Cams->{UID} || "",
          SERVICE_NAME               => $lang{CAMERAS},
          DO_NOT_USE_GLOBAL_USER_PLS => 1
        });
      }
    }

    _cams_autofill_groups($Cams) if ($conf{CAMS_CHECK_USER_GROUPS} && $Cams->{ID});
  }
  elsif ($FORM{chg} || ($FORM{ID} && !$FORM{del})) {
    $Cams->{ACTION} = 'change';
    $Cams->{LNG_ACTION} = $lang{CHANGE};

    my $result = $Cams->_info($FORM{chg});

    if ($Cams->{TOTAL} > 0) {
      $FORM{SERVICE_ID} = $result->{SERVICE_ID};
      $Cams->{SERVICE_ID} = $result->{SERVICE_ID};
      $Cams->{TP_ID} = $result->{TP_ID};
      $Cams->{STATUS} = $result->{STATUS};
    }

    if (!$result->{SERVICE_ID} || !$PORTAL_ACTIONS{$result->{SERVICE_ID}}) {
      $html->message('info', $lang{INFO}, $lang{ERROR_VIEW_INFORMATION}, { ID => 804 });
      return 1; 
    }
  }
  elsif ($FORM{change}) {

  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    my $result = $Cams->_list({
      TP_ID      => '_SHOW',
      SERVICE_ID => '_SHOW',
      ID         => $FORM{del},
      COLS_NAME  => 1,
      COLS_UPPER => 1,
    });

    if ($Cams->{TOTAL}) {
      $FORM{SERVICE_ID} = $result->[0]{SERVICE_ID};
      $FORM{TP_ID} = $result->[0]{TP_ID};
    }

    $Cams->_info($FORM{del});
    if (!$Cams->{errno}) {
      $Cams->_del($FORM{del}, { %FORM, ID => $FORM{del} });
      if (!$Cams->{errno}) {
        $Cams->{ID} = $FORM{del};
        $html->message('info', $lang{INFO}, "$lang{DELETED} [ $Cams->{ID} ]");
        delete $Cams->{ID};
      }
    }
  }

  $Cams_service = cams_user_services(\%FORM, $user, $Cams);

  if (!$Cams->{ID}) {
    $Cams->{TP_ADD} = $html->form_select('TP_ID', {
      SELECTED  => $FORM{TP_ID} || $Cams->{TP_ID} || '',
      SEL_LIST  => !$FORM{SERVICE_ID} && !$Cams->{SERVICE_ID} ? [] : $Cams->tp_list({
        TP_ID      => '_SHOW',
        NAME       => '_SHOW',
        SERVICE_ID => $FORM{SERVICE_ID} || $Cams->{SERVICE_ID}
      }),
      SEL_KEY   => 'tp_id',
      SEL_VALUE => 'tp_id,name',
      EX_PARAMS => 'required="required"',
    });

    $Cams->{TP_DISPLAY_NONE} = "style='display:none'";
  }

  $FORM{SUBSCRIBE_FORM} = cams_services_sel({ %FORM, %$Cams, FORM_ROW => 1, UNKNOWN => 1, USER_PORTAL => '2' });

  $html->tpl_show(_include('cams_user_add_tp', 'Cams'), { %FORM, %$Cams, });

  if ($FORM{UID} && $FORM{chg}) {
    $user_groups .= cams_user_groups({ SERVICE_INFO => $Cams, UID => $FORM{UID}, SERVICE_ID => $Cams->{SERVICE_ID} });
  }

  $LIST_PARAMS{SERVICE_NAME} = "_SHOW";
  $LIST_PARAMS{PORTAL} = 1;

  result_former({
    INPUT_DATA      => $Cams,
    FUNCTION        => 'users_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,TP_NAME,SERVICE_STATUS,EXPIRE',
    HIDDEN_FIELDS   => 'LOGIN',
    FUNCTION_FIELDS => 'change',
    SKIP_USER_TITLE => 1,
    EXT_TITLES => {
      id             => "#",
      tp_name        => $lang{TARIF_PLAN},
      service_status => $lang{STATUS},
      service_name   => $lang{SERVICE},
    },
    STATUS_VALS     => sel_status({ HASH_RESULT => 1 }),
    TABLE           => {
      width   => '100%',
      caption => $lang{TARIF_PLANS},
      qs      => $pages_qs,
      ID      => 'CAMS_MAIN',
      header  => '',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&sid=$FORM{sid}&add_form=1" . ':add',
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}

1;
