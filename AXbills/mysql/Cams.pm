package Cams;

=name2

  Cams

=VERSION

  VERSION = 0.04

=cut

use strict;
use warnings FATAL => 'all';
use parent qw(dbcore);

use POSIX qw(strftime mktime);
use Tariffs;
my $Tariffs;

my $MODULE = 'Cams';
my ($SORT, $DESC, $PG, $PAGE_ROWS);
my ($db, $admin, $CONF);

#**********************************************************

=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut

#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;

  my $self = {
    db     => $db,
    admin  => $admin,
    conf   => $CONF,
    MODULE => 'Cams'
  };

  $Tariffs = Tariffs->new($self->{db}, $CONF, $admin);

  bless($self, $class);

  return $self;
}

#**********************************************************
sub _list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : '';
  $DESC = ($attr->{DESC}) ? '' : 'DESC';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 1000;

  my $search_columns = [
    [ 'UID',                'INT',  'cm.uid',                                1 ],
    [ 'LOGIN',              'STR',  'u.id as login',                         1 ],
    [ 'ID',                 'INT',  'cm.id',                                 1 ],
    [ 'TARIFF_ID',          'INT',  'tp.id as tariff_id',                    1 ],
    [ 'ACTIVATE',           'DATE', 'cm.activate',                           1 ],
    [ 'EXPIRE',             'DATE', 'cm.expire',                             1 ],
    [ 'TP_ID',              'INT',  'cm.tp_id',                              1 ],
    [ 'STATUS',             'INT',  'cm.status',                             1 ],
    [ 'TP_NAME',            'STR',  'tp.name as tp_name',                    1 ],
    [ 'TP_STREAMS_COUNT',   'INT',  'ctp.streams_count as tp_streams_count', 1 ],
    [ 'SERVICE_ID',         'INT',  'ctp.service_id as service_id',          1 ],
    [ 'SERVICE_NAME',       'STR',  's.name as service_name',                1 ],
    [ 'SUBSCRIBE_ID',       'STR',  'cm.subscribe_id',                       1 ]
  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map {$attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] })} @{$search_columns};
  }

  my $WHERE = $self->search_former($attr, $search_columns, {
    WHERE             => 1,
    USE_USER_PI       => 1,
    USERS_FIELDS_PRE  => 1,
    SKIP_USERS_FIELDS => [ 'UID', 'ACTIVE', 'EXPIRE' ]
  });

  if ( ! $admin->{permissions}->{0}->{8} ) {
    $WHERE .= " AND u.deleted=0";
  }

  my $EXT_TABLE = $self->{EXT_TABLES} || '';

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} cm.uid
   FROM cams_main cm
   LEFT JOIN users u           ON (cm.uid=u.uid)
   LEFT JOIN cams_tp ctp       ON (cm.tp_id=ctp.tp_id)
   LEFT JOIN tarif_plans tp    ON (cm.tp_id=tp.tp_id)
   LEFT JOIN cams_services s   ON (ctp.service_id=s.id)
   $EXT_TABLE
   $WHERE GROUP BY cm.id;",
    undef,
    {
      COLS_NAME => 1,
      %{$attr ? $attr : {}}
    }
  );

  return [] if ($self->{errno});

  return $self->{list};
}

#**********************************************************

=head2 _info($id)

  Arguments:
    $id - id for cams_users

  Returns:
    hash_ref

=cut

#**********************************************************
sub _info {
  my $self = shift;
  my ($id, $attr) = @_;

  if (defined($attr->{LOGIN})) {
    use Users;
    my $users = Users->new($self->{db}, $admin, $CONF);
    $users->info(0, { LOGIN => $attr->{LOGIN} });
    if ($users->{errno}) {
      $self->{errno} = 2;
      $self->{errstr} = 'ERROR_NOT_EXIST';
      return $self;
    }

    $self->{DEPOSIT} = $users->{DEPOSIT};
    $self->{ACCOUNT_ACTIVATE} = $users->{ACTIVATE};
  }

  $self->query(
    "SELECT
   tp.name AS tp_name,
   tp.gid AS tp_gid,
   tp.month_fee,
   tp.month_fee AS month_abon,
   tp.abon_distribution,
   tp.day_fee,
   tp.activate_price,
   tp.postpaid_monthly_fee,
   tp.payment_type,
   tp.period_alignment,
   tp.id AS tp_num,
   tp.filter_id AS tp_filter_id,
   tp.credit AS tp_credit,
   tp.age AS tp_age,
   tp.activate_price AS tp_activate_price,
   tp.change_price AS tp_change_price,
   tp.period_alignment AS tp_period_alignment,
   cs_services.module AS service_module,
   c_tp.*,
   service.*
     FROM cams_main service
     LEFT JOIN tarif_plans tp ON (service.tp_id=tp.tp_id)
     LEFT JOIN cams_tp c_tp ON (c_tp.tp_id=tp.tp_id)
     LEFT JOIN cams_services cs_services ON (cs_services.id=tp.service_id)
   WHERE service.id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}

#**********************************************************
=head2 _del($id)

=cut
#**********************************************************
sub _del {
  my $self = shift;
  my $id = shift;
  my ($attr) = @_;

  $self->query_del('cams_main', undef, { id => $id });

  $admin->{MODULE} = $MODULE;

  my @del_descr = ();
  push @del_descr, "UID: $attr->{UID}" if $attr->{UID};
  push @del_descr, "ID: $attr->{ID}" if $attr->{ID};
  push @del_descr, "COMMENTS: $attr->{COMMENTS}" if $attr->{COMMENTS};

  $admin->action_add($self->{UID}, join(' ', @del_descr), { TYPE => 10 });

  return $self;
}

#**********************************************************

=head2 users_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub users_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  ### START AXbills
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  ### END AXbills

  if ($attr->{PORTAL}) {
    delete $attr->{SERVICE_ID};
  }

  my $search_columns = [
    [ 'UID',                'INT', 'cm.uid',                                  ],
    [ 'ID',                 'INT', 'cm.id',                                 1 ],
    [ 'TP_ID',              'INT', 'cm.tp_id',                              1 ],
    [ 'SERVICE_STATUS',     'INT', 'cm.status as service_status',           1 ],
    [ 'TP_NAME',            'STR', 'tp.name as tp_name',                    1 ],
    [ 'TP_STREAMS_COUNT',   'INT', 'ctp.streams_count as tp_streams_count', 1 ],
    [ 'SERVICE_NAME',       'STR', 's.name as service_name',                1 ],
    [ 'MODULE',             'STR', 's.module',                              1 ],
    [ 'SERVICE_ID',         'INT', 'ctp.service_id',                        1 ],
    [ 'MONTH_FEE',          'INT', 'tp.month_fee',                          1 ],
    [ 'PERIOD_ALIGNMENT',   'INT', 'tp.PERIOD_ALIGNMENT',                   1 ],
    [ 'SUBSCRIBE_ID',       'STR', 'cm.subscribe_id',                       1 ],

  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map {$attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] })} @{$search_columns};
  }

  my $EXT_TABLE = '';
  $self->{EXT_TABLES} = '';

  my $WHERE = $self->search_former($attr, $search_columns, {
    WHERE             => 1,
    USERS_FIELDS_PRE  => 1,
    USE_USER_PI       => 1,
    SKIP_USERS_FIELDS => [ 'UID' ]
  });

  $EXT_TABLE = $self->{EXT_TABLES} if ($self->{EXT_TABLES});

	### START AXbills
  $self->query(
    "SELECT $self->{SEARCH_FIELDS} cm.uid, cm.activate, cm.expire
   FROM cams_main cm
   LEFT JOIN users u           ON (cm.uid=u.uid)
   LEFT JOIN cams_tp ctp       ON (cm.tp_id=ctp.tp_id)
   LEFT JOIN tarif_plans tp    ON (cm.tp_id=tp.tp_id)
   LEFT JOIN cams_services s   ON (tp.service_id=s.id)
   $EXT_TABLE
   $WHERE GROUP BY cm.id ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS ;",
    undef,
    {
      COLS_NAME => 1,
      %{$attr ? $attr : {}}
    }
  );
  ### END AXbills

  return [] if ($self->{errno});

  my $list = $self->{list} || [];

  $self->query("SELECT count(DISTINCT cm.id) AS total
    FROM cams_main cm
    LEFT JOIN users u           ON (cm.uid=u.uid)
     LEFT JOIN cams_tp ctp       ON (cm.tp_id=ctp.tp_id)
    LEFT JOIN tarif_plans tp    ON (cm.tp_id=tp.tp_id)
    LEFT JOIN cams_services s   ON (tp.service_id=s.id)
    $EXT_TABLE
    $WHERE", undef, { INFO => 1 }
  );

  return $list;
}

#**********************************************************

=head2 user_info($id)

  Arguments:
    $id - id for cams_users

  Returns:
    hash_ref

=cut

#**********************************************************
sub user_info {
  my $self = shift;
  my ($uid) = @_;

  my $list = $self->users_list({ COLS_NAME => 1, UID => $uid, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 });

  return $list->[0] || {};
}

#**********************************************************

=head2 user_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  $attr->{ACTIVATE} = $self->_normalize_date($attr->{ACTIVATE});
  if (!$attr->{ACTIVATE} && !$attr->{STATUS}) {
    $attr->{ACTIVATE} = strftime("%Y-%m-%d", localtime(time));
  }
  $attr->{ACTIVATE} ||= '0000-00-00';

  if ($attr->{TP_ID} && $attr->{TP_ID} > 0) {
    $self->{TP_INFO} = $Tariffs->info($attr->{TP_ID});
    $self->{TP_NUM} = $Tariffs->{ID};

    if (!$attr->{STATUS} && $Tariffs->{ACTIV_PRICE} > 0) {
      my $User = Users->new($self->{db}, $self->{admin}, $self->{conf});
      $User->info($attr->{UID});

      if ($User->{DEPOSIT} + $User->{CREDIT} < $Tariffs->{ACTIV_PRICE} && $Tariffs->{PAYMENT_TYPE} == 0) {
        $self->{errno} = 15;
        $self->{errstr} = 'TOO_SMALL_DEPOSIT';
        return $self;
      }

      my $fees = Fees->new($self->{db}, $self->{admin}, $self->{conf});
      $fees->take($User, $Tariffs->{ACTIV_PRICE}, { DESCRIBE => "Cams. Active TP" });
      $Tariffs->{ACTIV_PRICE} = 0;
    }

    $self->expire_date($attr, $Tariffs);
  }

  $attr->{EXPIRE} ||= '0000-00-00';
  $self->query_add('cams_main', $attr);

  return if $self->{errno};

  $admin->{MODULE} = $MODULE;

  my @info = ('SERVICE_ID', 'ID', 'TP_ID', 'STATUS', 'EMAIL', 'ACTIVATE', 'EXPIRE');
  my @actions_history = ();

  foreach my $param (@info) {
    next if !defined $attr->{$param};

    push @actions_history, $param . ":" . $attr->{$param};
  }

  $self->{ID} = $self->{INSERT_ID};

  $admin->action_add($attr->{UID}, "ID: $self->{INSERT_ID} ".  join(', ', @actions_history), { TYPE => 1 } );

  return $self->{INSERT_ID};
}

#**********************************************************

=head2 users_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut

#**********************************************************
sub users_del {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{UID} || $attr->{del};

  $self->query_del('cams_main', $attr, { 'uid' => [ $uid ] });

  return 1;
}

#**********************************************************

=head2 user_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  my $old_info = $self->_info($attr->{ID});
  $self->{OLD_STATUS} = $old_info->{STATUS};
  $attr->{DISABLE} = $attr->{STATUS};

  $attr->{ACTIVATE} = $self->_normalize_date($attr->{ACTIVATE})
    || $self->_normalize_date($old_info->{ACTIVATE})
    || strftime("%Y-%m-%d", localtime(time));

  my $tp_id = $attr->{TP_ID} || $old_info->{TP_ID};
  if ($tp_id) {
    $Tariffs->info($tp_id);
    $self->expire_date($attr, $Tariffs);
  }

  $admin->{MODULE} = $MODULE;
  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'cams_main',
    DATA         => $attr
  });

  $self->_info($attr->{ID});

  return $self;
}

#**********************************************************

=head2 tp_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub tp_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    [ 'TP_ID',            'INT', 'ctp.tp_id',                        1 ],
    [ 'ID',               'INT', 'tp.id',                            1 ],
    [ 'SERVICE_NAME',     'STR', 's.name as service_name',           1 ],
    [ 'NAME',             'STR', 'tp.name',                          1 ],
    [ 'STREAMS_COUNT',    'INT', 'ctp.streams_count',                1 ],
    [ 'PAYMENT_TYPE',     'INT', 'tp.payment_type',                  1 ],
    [ 'SERVICE_ID',       'INT', 'tp.service_id',                    1 ],
    [ 'MODULE',           'STR', 'tp.module',                        1 ],
    [ 'DAY_FEE',          'INT', 'tp.day_fee',                       1 ],
    [ 'ACTIVE_DAY_FEE',   'INT', 'tp.active_day_fee',                1 ],
    [ 'POSTPAID_DAY_FEE', 'INT', 'tp.postpaid_daily_fee',            1 ],
    [ 'MONTH_FEE',        'INT', 'tp.month_fee',                     1 ],
    [ 'COMMENTS',         'STR', 'tp.comments',                      1 ],
    [ 'FEES_METHOD',      'INT', 'tp.fees_method',                   1 ],
    [ 'DAY_TIME_LIMIT',   'INT', 'tp.day_time_limit',                1 ],
    [ 'WEEK_TIME_LIMIT',  'INT', 'tp.week_time_limit',               1 ],
    [ 'MONTH_TIME_LIMIT', 'INT', 'tp.month_time_limit',              1 ],
    [ 'TOTAL_TIME_LIMIT', 'INT', 'tp.total_time_limit',              1 ],
    [ 'DAY_TRAF_LIMIT',   'INT', 'tp.day_traf_limit',                1 ],
    [ 'WEEK_TRAF_LIMIT',  'INT', 'tp.week_traf_limit',               1 ],
    [ 'MONTH_TRAF_LIMIT', 'INT', 'tp.month_traf_limit',              1 ],
    [ 'TOTAL_TRAF_LIMIT', 'INT', 'tp.total_traf_limit',              1 ],
    [ 'OCTETS_DIRECTION', 'INT', 'tp.octets_direction',              1 ],
    [ 'ACTIV_PRICE',      'INT', 'tp.activate_price',                1 ],
    [ 'CHANGE_PRICE',     'INT', 'tp.change_price',                  1 ],
    [ 'CREDIT_TRESSHOLD', 'INT', 'tp.credit_tresshold',              1 ],
    [ 'CREDIT',           'STR', 'tp.credit',                        1 ],
    [ 'PERIOD_ALIGNMENT', 'INT', 'tp.period_alignment',              1 ],
    [ 'DVR',              'INT', 'ctp.dvr',                          1 ],
    [ 'PTZ',              'INT', 'ctp.ptz',                          1 ],
    [ 'NEXT_TARIF_PLAN',  'INT', 'tp.next_tp_id as next_tarif_plan', 1 ],
    [ 'AGE',              'INT', 'tp.age',                           1 ],
    [ 'ARCHIVE',          'INT', 'ctp.archive',                      1 ]
  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map {$attr->{ $_->[0] } = '_SHOW' unless exists $attr->{ $_->[0] }} @$search_columns;
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS} 1
   FROM cams_tp ctp
   LEFT JOIN tarif_plans   tp ON (ctp.tp_id=tp.tp_id)
   LEFT JOIN cams_services s  ON (ctp.service_id=s.id)
    $WHERE ORDER BY $SORT $DESC;",
    undef,
    {
      COLS_NAME => 1,
      %{$attr ? $attr : {}}
    }
  );

  return [] if $self->{errno};

  return $self->{list};
}

#**********************************************************

=head2 tp_info($id)

  Arguments:
    $id - id for tp

  Returns:
    hash_ref

=cut

#**********************************************************
sub tp_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->tp_list({ COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 });

  return $list->[0] || {};
}

#**********************************************************

=head2 tp_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub tp_add {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{TP_ID}) {
    $attr->{MODULE} = 'Cams';
    $Tariffs->add({ %$attr });

    if (defined($Tariffs->{errno})) {
      $self->{errno} = $Tariffs->{errno};
      return $self;
    }

    $attr->{TP_ID} = $Tariffs->{INSERT_ID};
    $self->{TP_NUM} = $Tariffs->{TP_NUM};
  }

  $self->query("INSERT INTO cams_tp (streams_count, service_id, tp_id)
    VALUES (?, ?, ?);", 'do',
    { Bind => [ $attr->{STREAMS_COUNT}, $attr->{SERVICE_ID}, $attr->{TP_ID} ] }
  );

  $self->{TP_ID} = $attr->{TP_ID};

  return $self->{INSERT_ID};
}

#**********************************************************

=head2 tp_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut

#**********************************************************
sub tp_del {
  my $self = shift;
  my ($attr) = @_;

  $Tariffs->del($attr->{TP_ID});
  $self->query_del('cams_tp', undef, { TP_ID => $attr->{TP_ID} });

  return 1;
}

#**********************************************************

=head2 tp_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub tp_change {
  my $self = shift;
  my ($attr) = @_;

  $Tariffs->change($attr->{TP_ID}, { %$attr });
  if (defined($Tariffs->{errno})) {
    $self->{errno} = $Tariffs->{errno};
    return $self;
  }

  $self->changes(
    {
      CHANGE_PARAM => 'TP_ID',
      TABLE        => 'cams_tp',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 services_list($attr) - list of tp services

  Arguments:
    $attr

=cut
#**********************************************************
sub services_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'NAME',                'STR', 'name',                                                1 ],
      [ 'MODULE',              'STR', 'module',                                              1 ],
      [ 'STATUS',              'INT', 'status',                                              1 ],
      [ 'COMMENT',             'STR', 'comment',                                             1 ],
      [ 'PROVIDER_PORTAL_URL', 'STR', 'provider_portal_url',                                 1 ],
      [ 'USER_PORTAL',         'INT', 'user_portal',                                         1 ],
      [ 'DEBUG',               'INT', 'debug',                                               1 ],
      [ 'LOGIN',               'INT', 'login',                                               1 ],
      [ 'PASSWORD',            'INT', '', "DECODE(password, '$CONF->{secretkey}') AS password" ],
    ],
    {
      WHERE => 1,
    }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} s.id
   FROM cams_services s
    $WHERE
    GROUP BY s.id
    ORDER BY $SORT $DESC",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 screen_add($attr)

=cut
#**********************************************************
sub services_add {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{PASSWORD}) {
    $attr->{PASSWORD} = "ENCODE('$attr->{PASSWORD}', '$self->{conf}->{secretkey}')",
  }

  $self->query_add('cams_services', $attr);

  return $self;
}

#**********************************************************
=head2 screen_change($attr)

=cut
#**********************************************************
sub services_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{USER_PORTAL} //= 0;
  $attr->{DISABLE} //= 0;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'cams_services',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 screen_del($id, $attr)

=cut
#**********************************************************
sub services_del {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query_del('cams_services', $attr, { ID => $id });

  return $self;
}

#**********************************************************
=head2 services_info($id)

  Arguments:
    $id  - Service ID

=cut
#**********************************************************
sub services_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT cams_services.*, DECODE(password, '$CONF->{secretkey}') AS password
    FROM cams_services
    WHERE id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $id ]
    }
  );

  return $self;
}

#**********************************************************
=head2 group_list($attr) - list of tp group

  Arguments:
    $attr

=cut
#**********************************************************
sub group_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'NAME',         'STR', 'g.name',                 1 ],
      [ 'LOCATION_ID',  'INT', 'g.location_id',          1 ],
      [ 'DISTRICT_ID',  'INT', 'g.district_id',          1 ],
      [ 'STREET_ID',    'INT', 'g.street_id',            1 ],
      [ 'BUILD_ID',     'INT', 'g.build_id',             1 ],
      [ 'SERVICE_ID',   'INT', 'g.service_id',           1 ],
      [ 'SERVICE_NAME', 'INT', 's.name as service_name', 1 ],
      [ 'MAX_USERS',    'INT', 'g.max_users',            1 ],
      [ 'MAX_CAMERAS',  'INT', 'g.max_cameras',          1 ],
      [ 'COMMENT',      'STR', 'g.comment',              1 ],
      [ 'SUBGROUP_ID',  'STR', 'g.subgroup_id',          1 ],
    ],
    {
      WHERE       => 1,
      WHERE_RULES => $attr->{WHERE_RULES} && ref $attr->{WHERE_RULES} eq 'ARRAY' ? $attr->{WHERE_RULES} : []
    }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} g.id
   FROM cams_groups g
   LEFT JOIN cams_services s ON(g.service_id=s.id)
    $WHERE
    GROUP BY g.id
    ORDER BY $SORT $DESC",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 group_add($attr)

=cut
#**********************************************************
sub group_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('cams_groups', $attr);

  return $self;
}

#**********************************************************
=head2 group_change($attr)

=cut
#**********************************************************
sub group_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{USER_PORTAL} //= 0;
  $attr->{DISABLE} //= 0;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'cams_groups',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 group_del($id, $attr)

=cut
#**********************************************************
sub group_del {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query_del('cams_groups', $attr, { ID => $id });

  return $self;
}

#**********************************************************
=head2 group_info($id)

  Arguments:
    $id  - Group ID

=cut
#**********************************************************
sub group_info {
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT * FROM cams_groups WHERE id= ? ;", undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 access_group_list($id)

  Arguments:
    $id  - Group ID

=cut
#**********************************************************
sub access_group_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();

  push @WHERE_RULES, "(g.location_id=$attr->{LOCATION_ID})" if $attr->{LOCATION_ID};
  push @WHERE_RULES, "(g.location_id=0 AND g.street_id=$attr->{STREET_ID})" if $attr->{STREET_ID};
  push @WHERE_RULES, "(g.location_id=0 AND g.street_id=0 AND g.district_id=$attr->{DISTRICT_ID})" if $attr->{DISTRICT_ID};
  push @WHERE_RULES, "(g.location_id=0 AND g.street_id=0 AND g.district_id=0)";

  return $self->group_list({
    NAME        => $attr->{NAME} || '_SHOW',
    BUILD_ID    => '_SHOW',
    STREET_ID   => '_SHOW',
    BUILD_ID    => '_SHOW',
    DISTRICT_ID => '_SHOW',
    SERVICE_ID  => $attr->{SERVICE_ID},
    COMMENT     => '_SHOW',
    WHERE_RULES => [ "(" . join(' OR ', @WHERE_RULES) . ")" ],
    COLS_NAME   => 1,
  });
}

#**********************************************************
=head2 user_groups($attr) - Users groups

  Arguments:
    $attr
      IDS
      ID
      TP_ID

  Results:
    Objects

=cut
#**********************************************************
sub user_groups {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('cams_users_groups', $attr);

  return $self if !$attr->{IDS};

  my @ids = split(/,\s?/, $attr->{IDS});

  my @MULTI_QUERY = ();

  foreach my $id (@ids) {
    push @MULTI_QUERY, [ $attr->{ID}, $attr->{TP_ID}, $id ];
  }

  $self->query(
    "INSERT INTO cams_users_groups
     (id, tp_id, group_id, changed)
        VALUES (?, ?, ?, NOW());",
    undef,
    { MULTI_QUERY => \@MULTI_QUERY }
  );

  $admin->{MODULE} = $MODULE;
  $admin->action_add($attr->{UID}, "GROUPS: $attr->{IDS}", { TYPE => 2 } );

  return $self;
}

#**********************************************************
=head2 user_groups_list($attr)

  Arguments:
    $attr
      TP_ID  - TP_ID
      ID     - Service ID

=cut
#**********************************************************
sub user_groups_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT tp_id, group_id, changed
     FROM cams_users_groups
     WHERE tp_id= ? AND id = ?;",
    undef,
    { %{$attr}, Bind => [ $attr->{TP_ID}, $attr->{ID} ] }
  );

  $self->{USER_GROUPS} = $self->{TOTAL};

  return $self->{list};
}

#**********************************************************
=head2 users_group_count($attr)

  Arguments:
    $attr

=cut
#**********************************************************
sub users_group_count {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT COUNT(*)
     FROM cams_users_groups
     WHERE group_id = ?;",
    undef,
    { %{$attr}, Bind => [ $attr->{GROUP_ID} ] }
  );

  return $self->{list}[0][0];
}

#**********************************************************
=head2 model_list($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub model_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr,
    [
      [ 'MODEL_NAME',   'STR', 'em.model_name AS model_name',                          1 ],
      [ 'MODEL_ID',     'INT', 'em.model_id AS model_id',                              1 ],
      [ 'VENDOR_NAME',  'STR', 'ev.name AS vendor_name',                               1 ],
      [ 'VENDOR_ID',    'INT', 'ev.id AS vendor_id',                                   1 ],
      [ 'TYPE_NAME',    'STR', 'et.name AS type_name',                                 1 ],
      [ 'TYPE_ID',      'INT', 'et.id AS type_id',                                     1 ],
      [ 'VENDOR_MODEL', 'STR', 'CONCAT(ev.name, ": ", em.model_name) AS vendor_model', 1 ],
    ],
    { WHERE => 1, }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} em.id
    FROM equipment_models em
    INNER JOIN equipment_types et ON (em.type_id=et.id)
    INNER JOIN equipment_vendors ev ON (ev.id=em.vendor_id)
    $WHERE
    ORDER BY $SORT $DESC",
    undef,
    $attr
  );

  return $self->{list} || [];
}


#**********************************************************
=head2 expire_date($attr, $Tariffs) - expire = activate + TP AGE days

=cut
#**********************************************************
sub expire_date {
  my $self = shift;
  my ($attr, $Tariffs) = @_;

  if (!$Tariffs->{AGE} || $Tariffs->{AGE} <= 0) {
    $attr->{EXPIRE} = $self->_normalize_date($attr->{EXPIRE}) || '0000-00-00';
    return $self;
  }

  my $activate = $self->_normalize_date($attr->{ACTIVATE}) || strftime("%Y-%m-%d", localtime(time));

  eval { require Date::Calc };
  if (!$@) {
    Date::Calc->import(qw/Add_Delta_Days/);
    my ($year, $mon, $mday) = split(/-/, $activate, 3);
    ($year, $mon, $mday) = Date::Calc::Add_Delta_Days($year, $mon, $mday, $Tariffs->{AGE});
    $attr->{EXPIRE} = sprintf("%04d-%02d-%02d", $year, $mon, $mday);
    return $self;
  }

  my ($year, $mon, $mday) = split(/-/, $activate, 3);
  my $base = mktime(0, 0, 0, $mday, $mon - 1, $year - 1900);
  $attr->{EXPIRE} = strftime("%Y-%m-%d", localtime($base + 86400 * $Tariffs->{AGE}));

  return $self;
}

#**********************************************************
=head2 _normalize_date($date)

=cut
#**********************************************************
sub _normalize_date {
  my $self = shift;
  my ($date) = @_;

  return '' if !defined $date || $date eq '' || $date eq '0000-00-00' || $date eq 'NOW()';

  $date =~ s/\s+.*$//;
  return $date if $date =~ /^\d{4}-\d{2}-\d{2}$/;

  return '';
}

1;
