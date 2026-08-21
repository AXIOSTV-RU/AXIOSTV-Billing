package Bonus::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my AXbills::HTML $html;
my $lang;
my Bonus $Bonus;

use AXbills::Base qw/days_in_month in_array/;

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  my $self = {};

  require Bonus;
  Bonus->import();
  $Bonus = Bonus->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 bonus_payments_maked($attr) - Cross module payment maked

=cut
#**********************************************************
sub bonus_payments_maked {
  my $self = shift;
  my ($attr) = @_;

  return '' if (!$CONF->{BONUS_PAYMENTS} || !$attr->{SUM});
  my $form = $attr->{FORM} || {};
  my $score = 0;
  my %RESULT = ();
  my $user;
  $user = $attr->{USER_INFO} if $attr->{USER_INFO};

  $form->{METHOD} = 2 if (!defined($form->{METHOD}));

  my $payment_method = $attr->{METHOD} || $form->{METHOD};

  my ($year, $month, $day) = split(/-/,$user->{REGISTRATION}, 3);
  my $seltime = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));
  my $registration_days = int((time() - $seltime) / 86400);

  $Bonus->user_info($user->{UID});

  return '' if (!$Bonus->{STATE} || !$Bonus->{ACCEPT_RULES});

  my $list = $Bonus->service_discount_list({
    REGISTRATION_DAYS => "<=$registration_days,>=0",
    PAGE_ROWS         => 20,
    SORT              => "registration_days DESC, 1 DESC, 2 DESC, pay_method DESC",
    COLS_NAME         => 1
  });

  if ($Bonus->{TOTAL} > 0) {
    foreach my $line (@$list) {
      if (in_array('-1', [ split(', ', $line->{pay_method}) ])
        || in_array($payment_method, [ split(', ', $line->{pay_method}) ])) {
        $RESULT{DISCOUNT} = $line->{discount};
        $RESULT{DISCOUNT_PERIOD} = $line->{discount_days};
        $RESULT{BONUS_SUM} = $line->{bonus_sum};
        $RESULT{BONUS_PERCENT} = $line->{bonus_percent};
        $RESULT{BONUS_EXT_ACCOUNT} = $line->{ext_account};

        if ($RESULT{DISCOUNT_PERIOD} > 0) {
          $RESULT{DISCOUNT_PERIOD} = POSIX::strftime('%Y-%m-%d', localtime(time + 86400 * $RESULT{DISCOUNT_PERIOD}));
        }

        if ($RESULT{BONUS_PERCENT}) {
          $score = $attr->{SUM} / 100 * $RESULT{BONUS_PERCENT};
        }
        last;
      }
    }
  }

  if (!$attr->{QUITE} && $attr->{SUM} > 0) {
    $html->message('info', $lang->{BONUS}, "$lang->{ADD} $lang->{BONUS} " . sprintf('%.2f', $score));
  }

  $Bonus->accomulation_scores_add({ UID => $user->{UID}, SCORE => $score });

  return 1;
}

#**********************************************************
=head2 bonus_pre_payment($attr)

  Arguments:
    $attr
      SUM

=cut
#**********************************************************
sub bonus_pre_payment {
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my $REPORT = '';
  my $sum = $form->{PAYMENT_SUM} || $attr->{SUM} || 0;

  if ($CONF->{BONUS_SERVICE_DISCOUNT} && $sum > 0) {
    $self->bonus_service_discount_mk({ %$attr, SUM => $sum, FORM => $form });
  }

  $self->bonus_turbo_mk({ %$attr, SUM => $sum, FORM => $form }) if $CONF->{BONUS_TURBO} && $sum > 0;

  return $REPORT;
}

#**********************************************************
=head2 bonus_turbo_mk($attr)

=cut
#**********************************************************
sub bonus_turbo_mk {
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};

  return 0 if $form->{METHOD} == 4 || $form->{METHOD} == 6;

  my $Internet;
  if (in_array('Internet', \@main::MODULES)) {
    require Internet;
    Internet->import();
    $Internet = Internet->new($db, $admin, $CONF);
    $Internet->user_info($attr->{USER_INFO}{UID});
  }

  my $periods = 0;
  my $registration_days = 0;

  if ($Internet && $Internet->{MONTH_ABON} > 0) {
    $periods = int($form->{SUM} / $Internet->{MONTH_ABON});
  }

  return 0 if $periods < 1;

  my %RESULT = ();
  my ($year, $month, $day) = split(/-/, $attr->{USER_INFO}->{REGISTRATION}, 3);
  my $seltime = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));
  $registration_days = int((time() - $seltime) / 86400);
  my $list = $Bonus->bonus_turbo_list({
    REGISTRATION_DAYS => "<=$registration_days,>=0",
    PERIODS           => "<=$periods",
    PAGE_ROWS         => 1,
    SORT              => "1 DESC, 2 DESC",
    COLS_NAME         => 1
  });

  $RESULT{TURBO_COUNT} = $list->[0]{turbo_count} if $Bonus->{TOTAL} > 0;

  #Result
  if ($RESULT{TURBO_COUNT} && $RESULT{TURBO_COUNT} > 0) {
    $Internet->user_change({ UID => $attr->{USER_INFO}->{UID}, FREE_TURBO_MODE => $RESULT{TURBO_COUNT} });
    $html->message('info', $lang->{INFO}, "$lang->{BONUS}: \n Turbo: $RESULT{TURBO_COUNT}");
  }

  return 0;
}

#**********************************************************
=head2 bonus_service_discount_mk($attr)

  Arguments:
     $attr
       METHOD
       SUM
       USER_INFO

  Results:

=cut
#**********************************************************
sub bonus_service_discount_mk {
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my @excluder_arr = ();

  my $user_info = $attr->{USER_INFO};
  if ($user_info->{GID}) {
    $user_info->group_info($main::users->{GID});

    if (!$user_info->{BONUS}) {
      $html->message('warn', $lang->{BONUS_DISABLED_FOR_GROUP}, '', { ID => 1901 });
      return 0;
    }
  }
	## START AXbills
  if (!$CONF->{BONUS_SERVICE_EXCLUDE}) {
   $CONF->{BONUS_SERVICE_EXCLUDE} = '4,5,6,7,8';
  }
	if (!$CONF->{BONUS_SERVICE_TOTAL_SUM}) {
   $CONF->{BONUS_SERVICE_TOTAL_SUM} = '0,1,2,3';
  }
  my $include = $CONF->{BONUS_SERVICE_TOTAL_SUM};
  ## END AXbills

  my $payment_sum = $attr->{SUM} || $form->{SUM};
  my $pay_method = $attr->{METHOD} || $form->{METHOD};
  my $exclude = $CONF->{BONUS_SERVICE_EXCLUDE};
  @excluder_arr = split(/,\s?/, $exclude);

  return 0 if in_array($pay_method, \@excluder_arr);

  $Bonus->{debug} = 1 if ($CONF->{BONUS_DEBUG} && $CONF->{BONUS_DEBUG} > 6);

  my %RULES = ();
  my $list = $Bonus->service_discount_list({
		PAGE_ROWS           => 1000,
		ONETIME_PAYMENT_SUM => '_SHOW',
		COLS_NAME           => 1
  });

  foreach my $line (@{$list}) {
	  ### AXbills
    if ($line->{registration_days} > 0) {
      $RULES{PERIOD} = 1;
    }
	elsif ($line->{service_period}) {
      $RULES{PERIOD} = 1;
    }
    if ($line->{total_payments_sum} > 0) {
      $RULES{TOTAL_PAYMENT} = 1;
    }
    elsif ($line->{onetime_payment_sum} >= 0) {
      $RULES{ONETIME_PAYMENT_SUM} = $line->{onetime_payment_sum};
    }
  }
	### AXbills

  require Payments;
  Payments->import();
  my $Payments = Payments->new($db, $admin, $CONF);

  my $Internet;
  if (in_array('Internet', \@main::MODULES)) {
    require Internet;
    Internet->import();

    $Internet = Internet->new($db, $admin, $CONF);
    $Internet->user_info($user_info->{UID});
  }

  my $periods = 0;
  my $registration_days = 0;
  my $month_fee = 0;

  if ($Internet->{MONTH_ABON} && $Internet->{MONTH_ABON} > 0) {
    if ($Internet->{PERSONAL_TP} && $Internet->{PERSONAL_TP} > 0) {
      $month_fee = $Internet->{PERSONAL_TP};
    }
    else {
      $month_fee = $Internet->{MONTH_ABON};
    }
  }
  if ($Internet->{DAY_ABON} && $Internet->{DAY_ABON} > 0) {
    $month_fee = $Internet->{DAY_ABON} * 30;
  }

  if ($month_fee > 0) {
    $periods = int($payment_sum / $month_fee);
  }

  my %RESULT = ();
  if ($RULES{PERIOD}) {
    my ($year, $month, $day) = split(/-/, $user_info->{REGISTRATION}, 3);
    my $seltime = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));
    $registration_days = int((time() - $seltime) / 86400);

### START AXbills
  $list = $Bonus->service_discount_list({
		REGISTRATION_DAYS   => "<=$registration_days,>=0",
		PERIODS             => "<=$periods",
		#PAGE_ROWS           => 1,
		COLS_NAME           => 100,
		SORT                => ($periods) ? 'service_period DESC, onetime_payment_sum DESC' : "registration_days DESC, onetime_payment_sum DESC",
		TP_ID               => '_SHOW',
		ONETIME_PAYMENT_SUM => '_SHOW',
		PAY_METHOD          => '_SHOW',
		TOTAL_PAYMENTS_SUM  => '_SHOW'
  });

  my $closest_index = -1;
  if ($RULES{TOTAL_PAYMENT} && $RULES{TOTAL_PAYMENT} > 0) {

    my $payments_sum = 0;
    my $list2 = $Payments->list({
          UID        => $user_info->{UID},
          TOTAL_ONLY => 1,
          METHOD     => $include
    });
    
    for (my $i = 0; $i < $Bonus->{TOTAL}; $i++) {
        $payments_sum = (($Payments->{SUM} || 0) + $payment_sum);
        if ($list->[$i]->{total_payments_sum} > 0 && $list->[$i]->{total_payments_sum} <= $payments_sum) {
          if ($closest_index == -1 || 
              abs($list->[$i]->{total_payments_sum} - $payments_sum) < abs($list->[$closest_index]->{total_payments_sum} - $payments_sum)) {
              $closest_index = $i;
          }
        }
    }
  } else{
    #   for (my $i = 0; $i < $Bonus->{TOTAL}; $i++) {
    #   if ($list->[$i]->{onetime_payment_sum} <= $payment_sum) {
    #      if ($closest_index == -1 || 
    #           abs($list->[$i]->{onetime_payment_sum} - $payment_sum) < abs($list->[$closest_index]->{onetime_payment_sum} - $payment_sum)) {
    #           $closest_index = $i;
    #       }
    #   }
    # }
    for (my $i = 0; $i < $Bonus->{TOTAL}; $i++) {
    if ($list->[$i]->{onetime_payment_sum} <= $payment_sum) {
        if ($list->[$i]->{registration_days} > 0) {
            if ($list->[$i]->{registration_days} <= $registration_days) {
                if ($closest_index == -1 || 
                    (abs($list->[$i]->{onetime_payment_sum} - $payment_sum) <= abs($list->[$closest_index]->{onetime_payment_sum} - $payment_sum) &&
                    abs($list->[$i]->{registration_days} - $registration_days) < abs($list->[$closest_index]->{registration_days} - $registration_days))) {
                    $closest_index = $i;
                }
            }
        } elsif ($list->[$i]->{registration_days} == 0) {
            if ($closest_index == -1 || 
                abs($list->[$i]->{onetime_payment_sum} - $payment_sum) < abs($list->[$closest_index]->{onetime_payment_sum} - $payment_sum)) {
                $closest_index = $i;
            }
        }
      }
    }
  }

  if ($closest_index != -1) {
    my $i = $closest_index;
    my @pay_methods = ();

    if (defined($list->[$i]->{pay_method}) && $list->[$i]->{pay_method} ne '-1') {
      @pay_methods = split(/,\s?/, $list->[$i]->{pay_method});
    }

    if ($#pay_methods > -1 && !in_array($pay_method, \@pay_methods)) {
      #Skip bonus if no other program
      return 0;
    }
    elsif (!$list->[$i]->{tp_id}
        || ($Internet->{TP_ID} && in_array($Internet->{TP_ID}, [ grep {$_ ne ''} split(',\s?', $list->[$i]->{tp_id}) ]))
    ) {
        $RESULT{DISCOUNT} = $list->[$i]->{discount};
        $RESULT{DISCOUNT_PERIOD} = $list->[$i]->{discount_days};
        $RESULT{BONUS_SUM} = $list->[$i]->{bonus_sum};
        $RESULT{BONUS_PERCENT} = $list->[$i]->{bonus_percent};
        $RESULT{BONUS_EXT_ACCOUNT} = $list->[$i]->{ext_account};
        $RESULT{ID} = $list->[$i]->{id};
        $RESULT{ONETIME_PAYMENT_SUM} = $list->[$i]->{onetime_payment_sum};

        if ($RESULT{DISCOUNT_PERIOD} > 0) {
            $RESULT{DISCOUNT_PERIOD} = POSIX::strftime('%Y-%m-%d', localtime(time + 86400 * $RESULT{DISCOUNT_PERIOD}));
			}
		}
	}
  }
  
  if ($user_info->{EXT_BILL_ID} == 0) {
        $user_info->{EXT_BILL_ID} = $Bonus->add_ext_bill_id({UID => $user_info->{UID}});

        if($user_info->{EXT_BILL_ID} == 0){
          $html->message("warn", "Ошибка", "Доп.счет не создан");
        }
}  
  ### END AXbills

  if ($RESULT{DISCOUNT} && $RESULT{DISCOUNT} > 0) {
		$main::users->change($user_info->{UID}, {
		REDUCTION      => $RESULT{DISCOUNT},
		REDUCTION_DATE => $RESULT{DISCOUNT_PERIOD},
		UID            => $user_info->{UID}
    });

    $html->message('info', $lang->{INFO},
      "$lang->{BONUS}: \n $lang->{REDUCTION}: $RESULT{DISCOUNT}\n  $lang->{DATE}: $RESULT{DISCOUNT_PERIOD}");
  }
### START AXbills
	
  if (($RESULT{BONUS_PERCENT} && $RESULT{BONUS_PERCENT} > 0) && ($RESULT{BONUS_SUM} && $RESULT{BONUS_SUM} > 0)) {
    $RESULT{BONUS_SUM} += sprintf("%.2f", $payment_sum / 100 * $RESULT{BONUS_PERCENT});
  } 
  elsif ($RESULT{BONUS_PERCENT} && $RESULT{BONUS_PERCENT} > 0) {
    $RESULT{BONUS_SUM} = sprintf("%.2f", $payment_sum / 100 * $RESULT{BONUS_PERCENT});
  }
  
  if ($RESULT{BONUS_SUM} && $RESULT{BONUS_SUM} > 0) {
    $main::users->{MAIN_BILL_ID} = $main::users->{BILL_ID};
### END AXbills

    $Payments->add($user_info,{
		SUM          => $RESULT{BONUS_SUM},
		METHOD       => 4,
		DESCRIBE     => $RESULT{BONUS_NAME} ? $RESULT{BONUS_NAME}  : $lang->{BONUS} . (($RESULT{ID}) ? " # $RESULT{ID}" : q{}),
		### START AXbills
		BILL_ID      => ($user_info->{EXT_BILL_ID}) ? $user_info->{EXT_BILL_ID} : $user_info->{BILL_ID},
		### END AXbills
		EXT_ID       => ($attr->{EXT_ID}) ? 'B_' . $attr->{EXT_ID} : undef,
		CHECK_EXT_ID => ($attr->{EXT_ID}) ? 'B_' . $attr->{EXT_ID} : undef
    });

    if ($Payments->{errno}) {
      if ($Payments->{errno} == 12) {
        $html->message('err', $lang->{ERROR}, $lang->{ERR_WRONG_SUM});
      }
      elsif ($Payments->{errno} == 14) {
        my $message = ($RESULT{BONUS_EXT_ACCOUNT}) ? "$lang->{EXTRA}" : '';
        $html->message('err', $lang->{ERROR}, "$message $lang->{BILL} $lang->{NOT_EXIST} ");
      }
      else {
        $html->message('err', $lang->{ERROR}, "[$Payments->{errno}] $main::err_strs{$Payments->{errno}}");
      }
    }
    else {
      my $message = "$lang->{BONUS} $lang->{SUM}: $RESULT{BONUS_SUM}";
      $message = "$lang->{EXTRA} $lang->{ACCOUNT}\n" . $message if $RESULT{BONUS_EXT_ACCOUNT};
      $html->message('info', $lang->{INFO}, "$message") if !$attr->{QUITE};
    }

    $main::users->{BILL_ID} = $main::users->{MAIN_BILL_ID} if $main::users->{MAIN_BILL_ID};
  }

  return 0;
}

#**********************************************************
=head2 bonus_service_discount_mk_paysys($attr)

  Arguments:
     $attr
       METHOD
       SUM
       USER_INFO

  Results:

=cut
#**********************************************************
sub bonus_service_discount_mk_paysys {
  my $self = shift;
  my ($attr) = @_;
  
  use Data::Dumper;
  
  my $conn = $attr->{DB_FROM_PS} || {};
  if($conn){
    $db = $conn->{DB};
    $admin = $conn->{ADMIN};
    $CONF = $conn->{CONF};
    $lang = $conn->{LANG};
  }
  else{
      print "No database connection\n";
      return 0;
  }

  ###START AXbills
  my Bonus $Bonus;
  require Bonus;
  Bonus->import();
  $Bonus = Bonus->new($db, $admin, $CONF);
  ###END AXbills

  my @excluder_arr = ();
  my $user_info = $attr->{USER_INFO};       
  # print Dumper($user_info);
  # print Dumper($attr->{SUM});

  if ($user_info->{GID}) {
    if(!$user_info->{BONUS}){
        print "NO BONUS FOR GID err ID => 1901\n";
        # $html->message('warn', $lang->{BONUS_DISABLED_FOR_GROUP}, '', { ID => 1901 });
        return 0;
      }
  }

	## START AXbills
  if (!$CONF->{BONUS_SERVICE_EXCLUDE}) {
   $CONF->{BONUS_SERVICE_EXCLUDE} = '4,5,6,7,8';
  }
	if (!$CONF->{BONUS_SERVICE_TOTAL_SUM}) {
   $CONF->{BONUS_SERVICE_TOTAL_SUM} = '0,1,2,3';
  }
  my $include = $CONF->{BONUS_SERVICE_TOTAL_SUM};
  ## END AXbills

  my $payment_sum = $attr->{SUM};
  my $pay_method = $attr->{METHOD};
  my $exclude = $CONF->{BONUS_SERVICE_EXCLUDE};
  @excluder_arr = split(/,\s?/, $exclude);

  return 0 if in_array($pay_method, \@excluder_arr);

  $Bonus->{debug} = 1 if ($CONF->{BONUS_DEBUG} && $CONF->{BONUS_DEBUG} > 6);

  my %RULES = ();
  my $list = $Bonus->service_discount_list({
		PAGE_ROWS           => 1000,
		ONETIME_PAYMENT_SUM => '_SHOW',
		COLS_NAME           => 1
  });

  foreach my $line (@{$list}) {
	  ### AXbills
    if ($line->{registration_days} > 0) {
      $RULES{PERIOD} = 1;
    }
	elsif ($line->{service_period}) {
      $RULES{PERIOD} = 1;
    }
    if ($line->{total_payments_sum} > 0) {
      $RULES{TOTAL_PAYMENT} = 1;
    }
    elsif ($line->{onetime_payment_sum} >= 0) {
      $RULES{ONETIME_PAYMENT_SUM} = $line->{onetime_payment_sum};
    }
  }
	### AXbills

  require Payments;
  Payments->import();
  my $Payments = Payments->new($db, $admin, $CONF);

  my $Internet;
  if (in_array('Internet', \@main::MODULES)) {
    require Internet;
    Internet->import();

    $Internet = Internet->new($db, $admin, $CONF);
    $Internet->user_info($user_info->{UID});
  }

  my $periods = 0;
  my $registration_days = 0;
  my $month_fee = 0;

  if ($Internet->{MONTH_ABON} && $Internet->{MONTH_ABON} > 0) {
    if ($Internet->{PERSONAL_TP} && $Internet->{PERSONAL_TP} > 0) {
      $month_fee = $Internet->{PERSONAL_TP};
    }
    else {
      $month_fee = $Internet->{MONTH_ABON};
    }
  }
  if ($Internet->{DAY_ABON} && $Internet->{DAY_ABON} > 0) {
    $month_fee = $Internet->{DAY_ABON} * 30;
  }

  if ($month_fee > 0) {
    $periods = int($payment_sum / $month_fee);
  }

  my %RESULT = ();
  if ($RULES{PERIOD}) {
    my ($year, $month, $day) = split(/-/, $user_info->{REGISTRATION}, 3);
    my $seltime = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));
    $registration_days = int((time() - $seltime) / 86400);

    ### START AXbills
    $list = $Bonus->service_discount_list({
		REGISTRATION_DAYS   => "<=$registration_days,>=0",
		PERIODS             => "<=$periods",
		#PAGE_ROWS           => 1,
		COLS_NAME           => 100,
		SORT                => ($periods) ? 'service_period DESC, onetime_payment_sum DESC' : "registration_days DESC, onetime_payment_sum DESC",
		TP_ID               => '_SHOW',
		ONETIME_PAYMENT_SUM => '_SHOW',
		PAY_METHOD          => '_SHOW',
		TOTAL_PAYMENTS_SUM  => '_SHOW'
  });


  my $closest_index = -1;
  if ($RULES{TOTAL_PAYMENT} && $RULES{TOTAL_PAYMENT} > 0) {

    my $payments_sum = 0;
    my $list2 = $Payments->list({
          UID        => $user_info->{UID},
          TOTAL_ONLY => 1,
          METHOD     => $include
    });
    
    for (my $i = 0; $i < $Bonus->{TOTAL}; $i++) {
        $payments_sum = (($Payments->{SUM} || 0) + $payment_sum);
        if ($list->[$i]->{total_payments_sum} > 0 && $list->[$i]->{total_payments_sum} <= $payments_sum) {
          if ($closest_index == -1 || 
              abs($list->[$i]->{total_payments_sum} - $payments_sum) < abs($list->[$closest_index]->{total_payments_sum} - $payments_sum)) {
              $closest_index = $i;
          }
        }
    }
  } else{
    for (my $i = 0; $i < $Bonus->{TOTAL}; $i++) {
    if ($list->[$i]->{onetime_payment_sum} <= $payment_sum) {
        if ($list->[$i]->{registration_days} > 0) {
            if ($list->[$i]->{registration_days} <= $registration_days) {
                if ($closest_index == -1 || 
                    (abs($list->[$i]->{onetime_payment_sum} - $payment_sum) <= abs($list->[$closest_index]->{onetime_payment_sum} - $payment_sum) &&
                    abs($list->[$i]->{registration_days} - $registration_days) < abs($list->[$closest_index]->{registration_days} - $registration_days))) {
                    $closest_index = $i;
                }
            }
        } elsif ($list->[$i]->{registration_days} == 0) {
            if ($closest_index == -1 || 
                abs($list->[$i]->{onetime_payment_sum} - $payment_sum) < abs($list->[$closest_index]->{onetime_payment_sum} - $payment_sum)) {
                $closest_index = $i;
            }
        }
      }
    }
  }

  if ($closest_index != -1) {
    #my $i = $closest_index;
    my @pay_methods = ();

    if (defined($list->[$closest_index]->{pay_method}) && $list->[$closest_index]->{pay_method} ne '-1') {
      @pay_methods = split(/,\s?/, $list->[$closest_index]->{pay_method});
    }

    if ($#pay_methods > -1 && !in_array($pay_method, \@pay_methods)) {
      #Skip bonus if no other program
      return 0;
    }
    elsif (!$list->[$closest_index]->{tp_id}
        || ($Internet->{TP_ID} && in_array($Internet->{TP_ID}, [ grep {$_ ne ''} split(',\s?', $list->[$closest_index]->{tp_id}) ]))
    ) {
        $RESULT{DISCOUNT} = $list->[$closest_index]->{discount};
        $RESULT{DISCOUNT_PERIOD} = $list->[$closest_index]->{discount_days};
        $RESULT{BONUS_SUM} = $list->[$closest_index]->{bonus_sum};
        $RESULT{BONUS_PERCENT} = $list->[$closest_index]->{bonus_percent};
        $RESULT{BONUS_EXT_ACCOUNT} = $list->[$closest_index]->{ext_account};
        $RESULT{ID} = $list->[$closest_index]->{id};
        $RESULT{ONETIME_PAYMENT_SUM} = $list->[$closest_index]->{onetime_payment_sum};

        if ($RESULT{DISCOUNT_PERIOD} > 0) {
            $RESULT{DISCOUNT_PERIOD} = POSIX::strftime('%Y-%m-%d', localtime(time + 86400 * $RESULT{DISCOUNT_PERIOD}));
			}
		}
	}
  }
  
  if (!$user_info->{EXT_BILL_ID}) {
        $user_info->{EXT_BILL_ID} = $Bonus->add_ext_bill_id({UID => $user_info->{UID}});

        if(!$user_info->{EXT_BILL_ID}){
          print "No additional account has been created\n";
          # $html->message("warn", "Ошибка", "Доп.счет не создан");
        }
  }  
  ### END AXbills

  if ($RESULT{DISCOUNT} && $RESULT{DISCOUNT} > 0) {
		$main::users->change($user_info->{UID}, {
		REDUCTION      => $RESULT{DISCOUNT},
		REDUCTION_DATE => $RESULT{DISCOUNT_PERIOD},
		UID            => $user_info->{UID}
    });

    # $html->message('info', $lang->{INFO},
    #   "$lang->{BONUS}: \n $lang->{REDUCTION}: $RESULT{DISCOUNT}\n  $lang->{DATE}: $RESULT{DISCOUNT_PERIOD}");
  }
### START AXbills
	
  if (($RESULT{BONUS_PERCENT} && $RESULT{BONUS_PERCENT} > 0) && ($RESULT{BONUS_SUM} && $RESULT{BONUS_SUM} > 0)) {
    $RESULT{BONUS_SUM} += sprintf("%.2f", $payment_sum / 100 * $RESULT{BONUS_PERCENT});
  } 
  elsif ($RESULT{BONUS_PERCENT} && $RESULT{BONUS_PERCENT} > 0) {
    $RESULT{BONUS_SUM} = sprintf("%.2f", $payment_sum / 100 * $RESULT{BONUS_PERCENT});
  }
  
  if ($RESULT{BONUS_SUM} && $RESULT{BONUS_SUM} > 0) {
    #$main::users->{MAIN_BILL_ID} = $main::users->{BILL_ID};
    ### END AXbills
    
    $Payments->add($user_info,{
		SUM          => $RESULT{BONUS_SUM},
		METHOD       => 4,
		DESCRIBE     => $RESULT{BONUS_NAME} ? $RESULT{BONUS_NAME}  : $lang->{BONUS} . (($RESULT{ID}) ? " # $RESULT{ID}" : q{}),
		### START AXbills
		BILL_ID      => ($user_info->{EXT_BILL_ID}) ? $user_info->{EXT_BILL_ID} : $user_info->{BILL_ID},
		### END AXbills
		EXT_ID       => ($attr->{EXT_ID}) ? 'B_' . $attr->{EXT_ID} : undef,
		CHECK_EXT_ID => ($attr->{EXT_ID}) ? 'B_' . $attr->{EXT_ID} : undef
    });

    # print Dumper($Payments->{errno});
    
    if ($Payments->{errno}) {
      if ($Payments->{errno} == 12) {
                print "ERR_WRONG_SUM\n";

        # $html->message('err', $lang->{ERROR}, $lang->{ERR_WRONG_SUM});
      }
      elsif ($Payments->{errno} == 14) {
        my $message = ($RESULT{BONUS_EXT_ACCOUNT}) ? "$lang->{EXTRA}" : '';
        print "$message $lang->{BILL} $lang->{NOT_EXIST}\n";
        # $html->message('err', $lang->{ERROR}, "$message $lang->{BILL} $lang->{NOT_EXIST} ");
      }
      else {
        print "[$Payments->{errno}] $main::err_strs{$Payments->{errno}}\n";
        # $html->message('err', $lang->{ERROR}, "[$Payments->{errno}] $main::err_strs{$Payments->{errno}}");
      }
    }
    else {
      my $message = "$lang->{BONUS} $lang->{SUM}: $RESULT{BONUS_SUM}";
      $message = "$lang->{EXTRA} $lang->{ACCOUNT}\n" . $message if $RESULT{BONUS_EXT_ACCOUNT};
      print "$message\n";

      # $html->message('info', $lang->{INFO}, "$message") if (!$attr->{QUITE} && !$attr->{PAYSYS_CHECK});
    }

    # $main::users->{BILL_ID} = $main::users->{MAIN_BILL_ID} if $main::users->{MAIN_BILL_ID};
  }

  return 0;
}

1;