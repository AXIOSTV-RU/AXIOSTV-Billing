=head NAME

  Cams Users

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Base qw(in_array cmd _bp);
require AXbills::Misc;
use Cams::Axiostv_cams; 

our (
  %FORM,
  $html,
  %lang,
  $db,
  %conf,
  $admin,
  $Cams_service,
  $users,
  $user,
  @MODULES,
  $DATE,
  $TIME,
  $index,
  %LIST_PARAMS,
);

my $Cams = Cams->new($db, $admin, \%conf);
my $Address = Address->new($db, $admin, \%conf);
my $Users = Users->new($db, $admin, \%conf);

#**********************************************************
=head2 cams_user($attr) - Users info

=cut
#**********************************************************
sub cams_user {

  $Cams->{db}{db}->{AutoCommit} = 0;
  $Cams->{db}->{TRANSACTION} = 1;
  $Cams->{ACTION} = 'add';
  $Cams->{LNG_ACTION} = $lang{ADD};
  my $uid = $FORM{UID} || " ";
  my $user_groups = '';

  if ($FORM{add}) {
    $Cams->users_list({ UID => $uid, TP_ID => $FORM{TP_ID} || 0 });

    if ($Cams->{TOTAL}) {
      $html->message('err', $lang{ERROR}, "This tariff already used");
      return 1;
    }

    $Cams->user_add({
      UID    => $FORM{UID} || "",
      TP_ID  => $FORM{TP_ID} || 0,
      STATUS => $FORM{STATUS} || 0,
      ACTIVATE => $FORM{ACTIVATE} || "",
      EXPIRE   => $FORM{EXPIRE} || ""
    });

    show_result($Cams, $lang{ADDED}) if !$Cams->{errno};

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

    _cams_autofill_groups() if ($conf{CAMS_CHECK_USER_GROUPS} && $Cams->{ID});
  }
  elsif ($FORM{change}) {
    $Cams->user_change(\%FORM);

    if ($Cams->{OLD_STATUS} && !$Cams->{STATUS}) {
      if (cams_user_activate($Cams, { USER => $users, REACTIVATE => (!$Cams->{STATUS}) ? 1 : 0, })) {
        $Cams->user_change(\%FORM);
      }
    }
    $FORM{chg} = $FORM{ID};
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    my $result = $Cams->_list({
      SERVICE_ID => '_SHOW',
      ID         => $FORM{del},
      COLS_NAME  => 1,
      COLS_UPPER => 1,
    });

    if ($Cams->{TOTAL}) {
      $FORM{SERVICE_ID} = $result->[0]{SERVICE_ID};
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
  elsif (!$FORM{add_form}) {
    my $list = $Cams->users_list({ UID => $FORM{UID}, ID => '_SHOW', COLS_NAME => 1 });
    $FORM{chg} = $list->[0]->{id} if $Cams->{TOTAL} == 1;
  }

  if ($FORM{chg} || ($FORM{ID} && !$FORM{del})) {
    $Cams->{ACTION} = 'change';
    $Cams->{LNG_ACTION} = $lang{CHANGE};

    my $result = $Cams->_info($FORM{chg});

    if ($Cams->{TOTAL} > 0) {
      $Cams->{SERVICE_ID} = $result->{SERVICE_ID};
      $Cams->{TP_ID} = $result->{TP_ID};
      $Cams->{STATUS} = $result->{STATUS};
      $Cams->{ACTIVATE} = $result->{ACTIVATE} || '';
      ($Cams->{ACTIVATE}, undef) = split(' ', $Cams->{ACTIVATE}, 2) if $Cams->{ACTIVATE};
      $Cams->{EXPIRE} = $result->{EXPIRE};
    }

    if ($FORM{UID}) {
      $user_groups .= cams_user_groups({ SERVICE_INFO => $Cams, UID => $FORM{UID}, SERVICE_ID => $Cams->{SERVICE_ID} });

      $user_groups .= "<br>";

    }
  }

  $Cams_service = cams_user_services(\%FORM);

  $FORM{SUBSCRIBE_FORM} = cams_services_sel({ %FORM, %$Cams, FORM_ROW => 1, UNKNOWN => 1 });

  if (!$Cams->{ID} || $FORM{ID}) {
    $Cams->{TP_ADD} = $html->form_select('TP_ID', {
      SELECTED  => $FORM{TP_ID} || $Cams->{TP_ID} || '',
      SEL_LIST  => $Cams->tp_list({ TP_ID => '_SHOW', NAME => '_SHOW', SERVICE_ID => ($FORM{SERVICE_ID} || $Cams->{SERVICE_ID} || "_SHOW") }),
      SEL_KEY   => 'tp_id',
      SEL_VALUE => 'tp_id,name',
    });

    $Cams->{TP_DISPLAY_NONE} = "style='display:none'";
  }

  $Cams->{STATUS_SEL} = sel_status({ STATUS => $FORM{STATUS} || $Cams->{STATUS} });

  if (($Cams->{ACTION} || '') eq 'add') {
    $Cams->{ACTIVATE} = $FORM{ACTIVATE} || $DATE;
  }

  $html->tpl_show(_include('cams_user', 'Cams'), { %FORM, %$Cams, });

# Перед выводом таблички
  if ($FORM{add_user_rights}) {
    my $service_id = $FORM{SERVICE_ID} || $Cams->{SERVICE_ID};
    my $cams_object = Cams::Axiostv_cams->new($db, $admin, \%conf);
    my $auth_data = $Cams->services_info($service_id);


    my $user_rights_array = $cams_object->dph_keys_get_devices_list({ UID => $FORM{UID}, URL=> $auth_data->{URL}, PASSWORD => $auth_data->{PASSWORD}, LOGIN => $auth_data->{LOGIN} });
    my $user_rights_array_items = $user_rights_array->{devices};  

    my $html_txt = "<table class='table table-striped table-hover ' id='add_user_rights'>"; 
    #for (my $i = 0; $i <= $#user_rights_array_items; $i++) {
    foreach my $el (@$user_rights_array_items) {

      my $checkbox = $html->form_input('ADD_IDS', $el->{device_id}, {
        TYPE          => 'checkbox',
        STATE         => undef,
        OUTPUT2RETURN => 1,
      });

      $html_txt .= '<tr><td>'.$checkbox.'</td><td>'.$el->{device_id}.'</td><td>'.$el->{device_type}.'</td><td>'.$el->{title}.'</td></tr>';
    }  
    $html_txt .= '</table>';
    $FORM{html} = $html_txt;

    $html->tpl_show(_include('cams_user_add_user_rights', 'Cams'), { %FORM, %$Cams, });  

  } else {

    print $user_groups  if ($user_groups);
    print cams_user_rights({ SERVICE_INFO => $Cams, UID => $FORM{UID}, SERVICE_ID => $Cams->{SERVICE_ID} })  if ($user_groups);
    print $html->br();print $html->br();
    if ($FORM{UID}) {
      my $user_keys = cams_user_keys({ SERVICE_INFO => $Cams, UID => $FORM{UID}, SERVICE_ID => $Cams->{SERVICE_ID} });
      print $user_keys;
      print $html->br();
      print $html->br();

    }

  }

  $LIST_PARAMS{SERVICE_NAME} = "_SHOW";
  result_former({
    INPUT_DATA      => $Cams,
    FUNCTION        => 'users_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,TP_NAME,SERVICE_STATUS,SERVICE_NAME,ACTIVATE,EXPIRE',
    FUNCTION_FIELDS => 'change, del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id             => "#",
      tp_name        => $lang{TARIF_PLAN},
      service_status => $lang{STATUS},
      service_name   => $lang{SERVICE},
      activate       => $lang{ACTIVATE},
      expire         => $lang{EXPIRE}
    },
    STATUS_VALS     => sel_status({ HASH_RESULT => 1 }),
    TABLE           => {
      width   => '100%',
      caption => $lang{TARIF_PLANS},
      qs      => $pages_qs,
      ID      => 'CAMS_MAIN',
      header  => '',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&UID=$uid&add_form=1" . ':add',
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 0;
}

#**********************************************************
=head2 cams_user_services($form_) - Service add

  Arguments:
    $form_ - INPUT FORM arguments

  Results:
    $Tv_service [obj]

=cut
#**********************************************************
sub cams_user_services {
  my ($form_) = @_;

  $Cams->{SERVICE_ID} = $form_->{SERVICE_ID} if $form_->{SERVICE_ID};
  $Cams_service = undef;
  my DBI $db_ = $Cams->{db}{db};

  if ($Cams->{SERVICE_ID}) {
    $Cams_service = cams_load_service($Cams->{MODULE}, { SERVICE_ID => $Cams->{SERVICE_ID} });
  }
  else {
    delete($Cams->{db}->{TRANSACTION});
    if (! $db_->{AutoCommit}) {
      $db_->commit();
      $db_->{AutoCommit} = 1;
    }
    return $Cams_service;
  }

  if (!_error_show($Cams) && $Cams_service) {

    my $action_result = cams_account_action({
      %$form_,
      ID           => $Cams->{ID} || $form_->{ID},
      SUBSCRIBE_ID => $form_->{SUBSCRIBE_ID} || $Cams->{SUBSCRIBE_ID} || '',
    });

    if ($action_result) {
      _error_show($Cams, {
        ID          => 4035,
        MODULE_NAME => $Cams_service->{SERVICE_NAME}
      });

      $db_->rollback();
      delete $Cams->{ID};
    }
    else {
      $html->message('info', $lang{INFO}, $Cams->{MESSAGE}) if ($Cams->{MESSAGE});
    }
    delete($Cams->{db}->{TRANSACTION});
    if (! $db_->{AutoCommit}) {
      $db_->commit();
      $db_->{AutoCommit} = 1;
    }
  }
  else {
    delete($Cams->{db}->{TRANSACTION});
    if (! $db_->{AutoCommit}) {
      $db_->commit();
      $db_->{AutoCommit} = 1;
    }
  }

  return $Cams_service;
}

#**********************************************************
=head2 cams_account_action($attr) - Control external services

  Arguments:
    $attr
      add
      change
      del

  Returns:

    True or False

=cut
#**********************************************************
sub cams_account_action {
  my ($attr) = @_;

  my $result = 0;

  if (($Cams->{SERVICE_ID} || ($attr->{SERVICE_ID} && $attr->{MODULE})) && !$Cams_service) {
    $Cams->{SERVICE_ID} = $Cams->{SERVICE_ID} || $attr->{SERVICE_ID};
    $Cams->{MODULE} = $Cams->{MODULE} && $Cams->{MODULE} ne "Cams" ? $Cams->{MODULE} : $attr->{MODULE};
    $Cams_service = cams_load_service($Cams->{MODULE}, { SERVICE_ID => $Cams->{SERVICE_ID} });
    if ($Cams_service && $Cams_service->{SUBSCRIBE_COUNT}) {
      $attr->{SUBSCRIBE_COUNT} = $Cams_service->{SUBSCRIBE_COUNT};
    }
  }

  $Cams->{TP_ID} = $attr->{TP_ID} if ($attr->{TP_ID} && !$Cams->{TP_ID});
  my $uid = $attr->{UID} || $Cams->{UID} || $FORM{UID};
  if ($attr->{USER_INFO}) {
    $users = $attr->{USER_INFO};
  }

  if ($attr->{NEGDEPOSIT}) {
    if ($Cams_service && $Cams_service->can('user_negdeposit')) {
      $Cams_service->user_negdeposit($attr);
      if ($Cams_service->{errno}) {
        print "$Cams_service->{SERVICE_NAME} Error: [$Cams_service->{errno}]  $Cams_service->{errstr} UID: $uid $attr->{ID}\n";
      }
    }
  }
  elsif ($attr->{add}) {
    if ($Cams_service && $Cams_service->can('user_add')) {
      $users->pi({ UID => $uid });
      $Cams->{PHONE} = $users->{PHONE};
      $users->info($uid, { SHOW_PASSWORD => 1 });
      $Cams->_info($attr->{ID});
      $Cams->{EMAIL} ||= $users->{EMAIL};
      $Cams->{LOGIN} = $users->{LOGIN};

      $Cams_service->user_add({
        %{$users},
        %{$Cams},
        %{$attr},
        ID => $Cams->{ID}
      });

      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
      else {
        if ($conf{CAMS_CHECK_USER_GROUPS} && !$attr->{SERVICE_ACTIVATED}) {
          $attr->{change_now} = 1;
          $attr->{chg} = $Cams->{ID};
        }

        if ($Cams_service->{SUBSCRIBE_ID}) {
          $Cams->user_change({ ID => $Cams->{ID}, SUBSCRIBE_ID => $Cams_service->{SUBSCRIBE_ID} });
        }
        $result = 0;
      }
    }
  }
  elsif ($attr->{change}) {
    if ($Cams_service && $Cams_service->can('user_change')) {
      $users->info($uid, { SHOW_PASSWORD => 1 });
      $users->pi({ UID => $uid });
      $Cams_service->user_change({
        %$attr,
        %$users,
        %$Cams,
        %FORM
      });

      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
      else {
        if ($Cams_service->{SUBSCRIBE_ID}) {
          $Cams->user_change({
            ID           => $Cams->{ID},
            SUBSCRIBE_ID => $Cams_service->{SUBSCRIBE_ID}
          });
        };
      }
    }
  }
  elsif ($attr->{chg}) {
    if ($Cams_service && $Cams_service->can('user_info')) {
      my $user_info = $Cams->_info($attr->{chg});
      $users->info($uid, { SHOW_PASSWORD => 1 });
      $Cams_service->user_info({ %$attr, %$users, %{$Cams}, %{$user_info} });
    }
  }
  elsif ($attr->{del}) {
    if ($Cams_service && $Cams_service->can('user_del')) {
      $users->info($uid, { SHOW_PASSWORD => 1 });
      $Cams_service->user_del({ %$attr, %{$Cams}, %$users, ID => $attr->{del}, NAME => $attr->{CAM_NAME} });
    }
  }
  elsif ($attr->{change_group}) {
    if ($Cams_service && $Cams_service->can('group_change')) {
      $Cams->group_info($FORM{ID});
      $Cams_service->group_change({ %$attr, %$Cams, %FORM });

      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
    }
  }
  elsif ($attr->{add_group}) {
    if ($Cams_service && $Cams_service->can('group_add')) {
      $Cams_service->group_add({
        %{$Cams},
        %{$attr},
        ID => $Cams->{ID}
      });

      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
      else {
        if ($Cams_service->{SUBGROUP_ID}) {
          $Cams->group_change({
            ID          => $attr->{GROUP_ID},
            SUBGROUP_ID => $Cams_service->{SUBGROUP_ID}
          });
        };
      }
    }
  }
  elsif ($attr->{chg_group}) {
    if ($Cams_service && $Cams_service->can('group_info')) {
      $Cams->group_info($attr->{chg_group});
      $Cams_service->group_info({ %$attr, %$users, %{$Cams} });
      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
    }
  }
  elsif ($attr->{del_group}) {
    if ($Cams_service && $Cams_service->can('group_del')) {
      $Cams->group_info($attr->{del_group});
      $Cams_service->group_del({ %$attr, %{$Cams}, ID => $attr->{del_cam} });
      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
    }
  }

  if ($attr->{change_now} && $attr->{chg}) {
    if ($Cams_service && $Cams_service->can('change_user_groups')) {
      $attr->{IDS} = $attr->{GROUP_IDS} if $attr->{GROUP_IDS};
      $users->info($uid);
      my $tp_params = $Cams->tp_list({
        TP_ID => $attr->{TP_ID} || $Cams->{TP_ID},
        DVR   => '_SHOW',
        PTZ   => '_SHOW',
      });

      if ($Cams->{TOTAL}) {
        $attr->{DVR} = $tp_params->[0]{dvr};
        $attr->{PTZ} = $tp_params->[0]{ptz};
      }

      $Cams_service->change_user_groups({ %$attr, %{$Cams}, %$users });
      if ($Cams_service->{errno}) {
        $Cams->{errno} = $Cams_service->{errno};
        $Cams->{errstr} = $Cams_service->{errstr};
        $result = 1;
      }
    }
  }

  return $result;
}

#**********************************************************
=head2 _cams_autofill_groups($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _cams_autofill_groups {
  my ($attr) = @_;

  $Cams->{ID} ||= $Cams->{INSERT_ID} || $attr->{ID} || $attr->{INSERT_ID};
  return 0 if !$Cams->{ID};

  $user = $Users->pi({ UID => $FORM{UID} });
  return 0 if $Users->{TOTAL} < 1;

  my $user_address = $Address->address_info($user->{LOCATION_ID});
  my $user_access_groups = $Cams->access_group_list({
    NAME        => '_SHOW',
    STREET_ID   => $user_address->{STREET_ID} || 0,
    DISTRICT_ID => $user_address->{DISTRICT_ID} || 0,
    LOCATION_ID => $user->{LOCATION_ID} || 0,
    SERVICE_ID  => $FORM{SERVICE_ID} || $Cams->{SERVICE_ID},
    COMMENT     => '_SHOW',
    COLS_NAME   => 1,
  });

  $FORM{GROUP_IDS} = join(', ', map $_->{id}, @{$user_access_groups});
  $FORM{ID} = $Cams->{ID};

  $Cams->user_groups({
    IDS   => $FORM{GROUP_IDS},
    TP_ID => $FORM{TP_ID} || $Cams->{TP_ID},
    ID    => $Cams->{ID},
  });

  return 0;
}
1;
