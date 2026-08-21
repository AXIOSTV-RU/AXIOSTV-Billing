use strict;
use warnings 'FATAL' => 'all';
use Sorm3::db::Sorm;
use AXbills::Base qw(ip2int int2ip in_array);
use AXbills::Misc qw(date_diff);
use Sorm3::Settings;


our(
    $db,
    $admin,
    %conf,
    %lang,
    $html,
    $DATE,
    $TIME,
);

my %TYPES = (
    0 => 'sgsn',
    1 => 'ggsn',
    2 => 'smsc',
    3 => 'gmsc',
    4 => 'hss',
    5 => 'ptsn',
    6 => 'voip-gw',
    7 => 'aaa',
    8 => 'nat'
);
our $Sorm_db = Sorm3::db::Sorm->new($db, $admin, \%conf);
our $Settings = Sorm3::Settings->new($db, $admin, \%conf, \%lang, $html);

sub gateways  {
    my ($attr) = @_;

    my %ACTION_PARAMS = ();
    my $add_button = $html->button($lang{ADD}, "index=$index&gateways=1&add_form=1", { BUTTON => 1 });
    my $table = $html->table({
        caption => "Шлюзы $add_button",
        MENU => '',
        title => ['id', $lang{NAME}, 'IPV4', 'IPV6', $lang{TYPE}, $lang{BEGIN_TIME}, $lang{TO_BE_DELETED},'' ], 
        width => '100%',
	DATA_TABLE => 1
    });

    if($FORM{add}) {
        $FORM{IPV4} = ip2int($FORM{IPV4}) if($FORM{IPV4});
        my $result = $Sorm_db->gateway_add(\%FORM);
    } 
    elsif($FORM{chg}) {
        $FORM{ID} = $FORM{chg};
        $FORM{IPV4} = ip2int($FORM{IPV4}) if($FORM{IPV4});

        my $result = $Sorm_db->gateway_change(\%FORM);
        if(!$result) {
            print $html->message('info',$lang{CHANGED});
        }
    }
    elsif($FORM{undel}) {
        my $result = $Sorm_db->gateway_change({ ID => $FORM{undel}, DELETED => 0 });
    }    
    elsif($FORM{del}) {
        my $result = $Sorm_db->gateway_change({ ID => $FORM{del}, DELETED => 1 });
    }
    elsif($FORM{FULL_DEL}) {
        my $result = $Sorm_db->gateway_del({ ID => $FORM{FULL_DEL} });
    }

    if($FORM{add_form}) {
        $ACTION_PARAMS{ACTION} = 'add';
        $ACTION_PARAMS{ACTION_VALUE} = 1;
        $ACTION_PARAMS{ACTION_BUTTON} = $lang{ADD};

	my $str = $html->form_select('GATE_TYPE', {
	    SEL_HASH => \%TYPES,
	    NO_ID => 1,
	});
        $ACTION_PARAMS{GATE_TYPE} = $str;
        $ACTION_PARAMS{BEGIN_TIME} = $html->form_datetimepicker('BEGIN_TIME', $DATE);

        $html->tpl_show(_include('sorm_gateway_add', 'Sorm3'), { %ACTION_PARAMS });
    } elsif($FORM{change}) {
        $ACTION_PARAMS{ACTION} = 'chg';
        $ACTION_PARAMS{ACTION_VALUE} = $FORM{change};
        $ACTION_PARAMS{ACTION_BUTTON} = $lang{CHANGE};
        my $l = $Sorm_db->list_gateways({ ID => $FORM{change}, COLS_NAME => 1 });
        my $gate = $l->[0] if ($l);

	my $str = $html->form_select('GATE_TYPE', {
	    SEL_HASH => \%TYPES,
	    NO_ID => 1,
	    SELECTED => $gate->{GATE_TYPE}
	});
        $gate->{GATE_TYPE} = $str;
	$gate->{BEGIN_TIME} = $html->form_datetimepicker('BEGIN_TIME', $gate->{BEGIN_TIME});


        $html->tpl_show(_include('sorm_gateway_add', 'Sorm3'), { %ACTION_PARAMS, %$gate });
    }

    my $list = $Sorm_db->list_gateways({
        COLS_NAME => 1
    });
    
        if($list) {
            foreach my $row (@$list) {
                $table->addrow($row->{id}, 
                        $row->{DESCRIPTION}, 
                        $row->{IPV4},
			$row->{IPV6},
                        $TYPES{ $row->{GATE_TYPE} }, 
                        $row->{BEGIN_TIME},
			( $row->{DELETED} ? $html->element('span', $lang{YES}, { class => 'text-danger' }) : $html->element('span', $lang{NO}, { }) ),                                                                                      
            		(!$row->{DELETED}                                                                                                                                                                                                   
            		    ? $html->button('Изменить', "index=$index&gateways=1&change=$row->{id}", { class => 'btn btn-xs btn-primary' })                                                                                                      
            		    : $html->button('Удалить полностью', "index=$index&gateways=1&FULL_DEL=$row->{id}", { class => 'btn btn-xs btn-primary', MESSAGE => 'Удалить ?' })         
            		).                                                                                                                                                                                                                  
            		((!$row->{DELETED}) 
			    ? $html->button('Удалить', "index=$index&gateways=1&del=$row->{id}", { MESSAGE => "удалить $row->{DESCRIPTION}?", class => 'btn btn-xs btn-danger text-white' }) 
			    : $html->button('Отменить', "index=$index&gateways=1&undel=$row->{id}", { MESSAGE => "Отменить удалене $row->{DESCRIPTION}?", BUTTON => 1 }))
            		);
            }
        }
        print $table->show();
}

sub phone_special {
    my ($attr) = @_;
    my %ACTION_PARAMS = ();

    if($FORM{add}) {
        $FORM{IPV4} = ip2int($FORM{IPV4}) if($FORM{IPV4});
        my $result = $Sorm_db->phone_special_add(\%FORM);
    } 
    elsif($FORM{chg}) {
        $FORM{ID} = $FORM{chg};
        $FORM{IPV4} = ip2int($FORM{IPV4}) if($FORM{IPV4});

        my $result = $Sorm_db->phone_special_change(\%FORM);
        if(!$result) {
            print $html->message('info',$lang{CHANGED});
        }
    }
    elsif($FORM{undel}) {                                                                                                                                            
        my $result = $Sorm_db->phone_special_change({ ID => $FORM{undel}, DELETED => 0 });
        if(!$result) {
            print $html->message('info',$lang{CHANGED});
        }
    }
    elsif($FORM{del}) {
	$FORM{ID} = $FORM{chg};
        my $result = $Sorm_db->phone_special_change({ ID => $FORM{del}, DELETED => 1 });
        if(!$result) {
            print $html->message('info',$lang{CHANGED});
        }
    }
    elsif($FORM{FULL_DEL}) {
        my $result = $Sorm_db->phone_special_del({ ID => $FORM{FULL_DEL} });
        if(!$result) {
            print $html->message('danger',$lang{DELETED});
        }
    }

    my $add_button = $html->button($lang{ADD}, "index=$index&phone_special=1&add_form=1", { BUTTON => 1 });           
    my $table = $html->table({                                                                                   
	caption => "$lang{PHONE_SPECIAL} $add_button",                     
	MENU => '',                                                                                              
        title_plain => ['id', $lang{NAME}, 'PHONE_NUMBER', 'IPV4','IPV6', $lang{BEGIN_TIME}, $lang{TO_BE_DELETED},'' ],
	width => '100%',
	DATA_TABLE => 1
    });

    if($FORM{add_form}) {
        $ACTION_PARAMS{ACTION} = 'add';
        $ACTION_PARAMS{ACTION_VALUE} = 1;
        $ACTION_PARAMS{ACTION_BUTTON} = $lang{ADD};
	$ACTION_PARAMS{BEGIN_TIME} = $html->form_datetimepicker('BEGIN_TIME', $DATE);

        $html->tpl_show(_include('sorm_phone_special_add', 'Sorm3'), { %ACTION_PARAMS });
    } elsif($FORM{change}) {
        $ACTION_PARAMS{ACTION} = 'chg';
        $ACTION_PARAMS{ACTION_VALUE} = $FORM{change};
        $ACTION_PARAMS{ACTION_BUTTON} = $lang{CHANGE};

	my $l = $Sorm_db->list_phone_special({ ID => $FORM{change}, COLS_NAME => 1 });
        my $phone_special = $l->[0] if ($l);
	$phone_special->{BEGIN_TIME} = $html->form_datetimepicker('BEGIN_TIME', $phone_special->{BEGIN_TIME});

        $html->tpl_show(_include('sorm_phone_special_add', 'Sorm3'), { %ACTION_PARAMS, %$phone_special });
    }

    my $list = $Sorm_db->list_phone_special({
        COLS_NAME => 1
    });
    
        if($list) {
            foreach my $row (@$list) {
                $table->addrow($row->{id}, 
                        $row->{DESCRIPTION},
			$row->{PHONE_NUMBER}, 
                        $row->{IPV4},
			$row->{IPV6},  
                        $row->{BEGIN_TIME},
			( $row->{DELETED} ? $html->element('span', $lang{YES}, { class => 'text-danger' }) : $html->element('span', $lang{NO}, { }) ),                                                                                      
            		(!$row->{DELETED}                                                                                                                                                                                                   
            		    ? $html->button('Изменить', "index=$index&phone_special=1&change=$row->{id}", { class => 'btn btn-xs btn-primary' })                                                                                                      
            		    : $html->button('Удалить полностью', "index=$index&phone_special=1&FULL_DEL=$row->{id}", { class => 'btn btn-xs btn-primary', MESSAGE => 'Удалить ?' })         
            		).                                                                                                                                                                                                                  
            		((!$row->{DELETED}) 
			    ? $html->button('Удалить', "index=$index&phone_special=1&del=$row->{id}", { MESSAGE => "удалить $row->{DESCRIPTION}?", class => 'btn btn-xs btn-danger text-white' }) 
			    : $html->button('Отменить', "index=$index&phone_special=1&undel=$row->{id}", { MESSAGE => "Отменить удалене $row->{DESCRIPTION}?", BUTTON => 1 }))
            		);
            }
        }

    print $table->show();
}

sub supplementary_services {
    my ($attr) = @_;
    my %ACTION_PARAMS = ();

    if($FORM{sync}) {
	$FORM{WEBUI} = 1;
	$Settings->sync_supplementary_services(\%FORM);
    } elsif($FORM{FULL_DEL}) {
	$FORM{WEBUI} = 1;
	$FORM{del} = $FORM{FULL_DEL};
	$Settings->del_supplementary_service(\%FORM);
    }

    my $sync_button = $html->button('Синхронизировать', "index=$index&supplementary_services=1&sync=1", { BUTTON => 1 });           
    my $table = $html->table({                                                                                   
	caption => "$lang{SORM_SERVICES} $sync_button", 
	MENU => '',                                                                                              
        title_plain => ['ID', $lang{MODULE}, $lang{NAME}, $lang{BEGIN_TIME}, $lang{TO_BE_DELETED} ],
	width => '100%',
	DATA_TABLE => 1
    });


    my $list = $Sorm_db->get_supplementary_services({
        COLS_NAME => 1
    });
    
        if($list) {
            foreach my $row (@$list) {
                $table->addrow($row->{ID},
                        $row->{MODULE},
			$row->{MNEMONIC}, 
                        $row->{BEGIN_TIME},
			$html->button('Удалить', "index=$index&supplementary_services=1&FULL_DEL=$row->{ID}", { class => 'btn btn-xs btn-danger', MESSAGE => 'Удалить ?' })
                );
            }
        }

    print $table->show();
}

sub ip_plan {
    my ($attr) = @_;
    my %ACTION_PARAMS = ();

    my $add_button = $html->button($lang{ADD}, "index=$index&ip_plan=1&add_form=1", { BUTTON => 1 });           
    my $table = $html->table({                                                                                   
	caption => "IP_PLAN $add_button",                                                                          
	MENU => '',                                                                                              
        title_plain => ['ID', $lang{NAME}, 'IPV4', 'IPV4_MASK', 'IPV6', 'IPV6_MASK', $lang{BEGIN_TIME}, $lang{TO_BE_DELETED}, '' ],
	width => '100%',
	DATA_TABLE => 1
    });


    if($FORM{add}) {                                        
	$FORM{IPV4} = ip2int($FORM{IPV4}) if($FORM{IPV4});  
	$FORM{IPV4_MASK} = '' if(!$FORM{IPV4});
	$FORM{IPV6_MASK} = '' if(!$FORM{IPV6}); 
	my $result = $Sorm_db->add_ip_plan(\%FORM);   
    }                                                       
    elsif($FORM{chg}) {
	$FORM{ID} = $FORM{chg};   
	$FORM{IPV4} = ip2int($FORM{IPV4}) if($FORM{IPV4});  
	$FORM{IPV4_MASK} = '' if(!$FORM{IPV4});
	$FORM{IPV6_MASK} = '' if(!$FORM{IPV6}); 

	my $result = $Sorm_db->change_ip_plan(\%FORM);

	if($Sorm_db->{errno}) {
	    print $Sorm_db->{errstr};
	}
    }                                                       
    elsif($FORM{del}) {
	$Sorm_db->change_ip_plan({ ID => $FORM{del}, DELETED => 1 });
    }
    elsif($FORM{FULL_DEL}) {
	$Sorm_db->ip_plan_del({ ID => $FORM{FULL_DEL} });
    }
    elsif($FORM{undel}) {
	$Sorm_db->change_ip_plan({ ID => $FORM{undel}, DELETED => 0 });
    }

    

    my $ip_plan = '';
    if($FORM{add_form}) {
        $ACTION_PARAMS{ACTION} = 'add';
        $ACTION_PARAMS{ACTION_VALUE} = 1;
        $ACTION_PARAMS{ACTION_BUTTON} = $lang{ADD};
	$ACTION_PARAMS{BEGIN_TIME} = $html->form_datetimepicker('BEGIN_TIME', $DATE.$TIME);

    } elsif($FORM{change}) {
        $ACTION_PARAMS{ACTION} = 'chg';
        $ACTION_PARAMS{ACTION_VALUE} = $FORM{change};
        $ACTION_PARAMS{ACTION_BUTTON} = $lang{CHANGE};

	my $l = $Sorm_db->get_ip_plan({ ID => $FORM{change}, COLS_NAME => 1 });
        $ip_plan = $l->[0] if ($l);
	$ip_plan->{BEGIN_TIME} = $html->form_datetimepicker('BEGIN_TIME', $ip_plan->{BEGIN_TIME}, { ICON => 1});
    }



    my %ipv4_mask = ();
    for	my $i (0..32) {
	$ipv4_mask{$i} = "/$i";
    }
    my %ipv6_mask = ();
    for my $i (0..128) {
	$ipv6_mask{$i} = "/$i";
    }


    $ACTION_PARAMS{IPV4_MASK_SELECT} = $html->form_select('IPV4_MASK', {
	SEL_HASH => \%ipv4_mask,
	NO_ID => 1,
	SORT_KEY_NUM => 1,
	SELECTED => ($ip_plan ? $ip_plan->{IPV4_MASK} : '')
    });

    $ACTION_PARAMS{IPV6_MASK_SELECT} = $html->form_select('IPV6_MASK', {
	SEL_HASH => \%ipv6_mask,
	NO_ID => 1,
	SORT_KEY_NUM => 1,
	SELECTED => ($ip_plan ? $ip_plan->{IPV6_MASK} : '')
    });


    if($FORM{add_form})  { $html->tpl_show(_include('sorm_ip_plan_add', 'Sorm3'), { %ACTION_PARAMS }) }
    elsif($FORM{change}) { $html->tpl_show(_include('sorm_ip_plan_add', 'Sorm3'), { %ACTION_PARAMS, %$ip_plan }) }

    
    my $list = $Sorm_db->get_ip_plan({ COLS_NAME => 1 });

    if($list) {
	foreach my $row (@$list) {
	    $table->addrow(
		$row->{id},
		$row->{DESCRIPTION},
		$row->{IPV4},
		$row->{IPV4_MASK},
		$row->{IPV6},
		$row->{IPV6_MASK},
		$row->{BEGIN_TIME},
		( $row->{DELETED} ? $html->element('span', $lang{YES}, { class => 'text-danger' }) : $html->element('span', $lang{NO}, { }) ),
		(!$row->{DELETED} 
		? $html->button('Изменить', "index=$index&ip_plan=1&change=$row->{id}", { class => 'btn btn-xs btn-primary' })
		: $html->button('Удалить полностью', "index=$index&ip_plan=1&FULL_DEL=$row->{id}", { class => 'btn btn-xs btn-primary', MESSAGE => 'Удалить ?' })
		).
                ((!$row->{DELETED}) ? $html->button('Удалить', "index=$index&ip_plan=1&del=$row->{id}", { MESSAGE => "удалить $row->{DESCRIPTION}?", class => 'btn btn-xs btn-danger text-white' }) : 
		$html->button('Отменить', "index=$index&ip_plan=1&undel=$row->{id}", { MESSAGE => "Отменить удалене $row->{DESCRIPTION}?", BUTTON => 1 }))
	    )
	}
    }

    print $table->show();
}

sub main_dictionaries {
    my ($attr) = @_;

    my %elems = (
        $lang{GATEWAYS}      => "index=$index&gateways=1",
        $lang{PHONE_SPECIAL} => "index=$index&phone_special=1",
        $lang{SORM_SERVICES} => "index=$index&supplementary_services=1",
        $lang{IP_PLAN}       => "index=$index&ip_plan=1"
    );

    my %TEMPLATE_PARAMS = ();
    my $item = '';
    foreach my $name (sort keys %elems) {
        $item .= $html->element('li', $html->element('a', $name, { href => "$SELF_URL?$elems{$name}", class => 'nav-link' }) , { class => 'nav-item'  });
    }

    my $menu = $html->element('ul', $item, { class => 'nav-tabs navbar-nav' });
    $TEMPLATE_PARAMS{GATEBUTTON} = $html->element('div', $menu, { class => 'axbills-navbar navbar navbar-expand navbar-light'} );

    $html->tpl_show(_include('sorm_main_dictionaries', 'Sorm3'), \%TEMPLATE_PARAMS);

    if ($FORM{gateways}) {
        gateways({ attr => $attr, TPL => \%TEMPLATE_PARAMS });
    }
    elsif ($FORM{phone_special}) {
        phone_special({ attr => $attr, TPL => \%TEMPLATE_PARAMS });
    }
    elsif ($FORM{supplementary_services}) {
        supplementary_services({ attr => $attr, TPL => \%TEMPLATE_PARAMS });
    }
    elsif ($FORM{ip_plan}) {
        ip_plan({ attr => $attr, TPL => \%TEMPLATE_PARAMS });
    }

    return 1;
}

1;


