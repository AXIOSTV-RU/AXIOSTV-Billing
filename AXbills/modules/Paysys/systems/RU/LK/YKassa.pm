=head1 YooKassa
  New module for YooKassa payment system

  Version:1.25

  Date: 03.07.2024
  Updated: 09.10.2024
=cut

package Paysys::systems::YKassa;
use strict;
use warnings FATAL => 'all';

use AXbills::Fetcher qw/web_request/;
use AXbills::Base qw/_bp load_pmodule urlencode/;

our $PAYSYSTEM_NAME = 'YKassa';
our $PAYSYSTEM_SHORT_NAME = 'YK';
our $PAYSYSTEM_ID = 167;
our $PAYSYSTEM_IP = '185.71.76.0/27, 185.71.77.0/27, 77.75.153.0/25, 77.75.156.11, 77.75.156.35, 77.75.154.128/25, 2a02:5180::/32';
our $PAYSYSTEM_VERSION = '1.25';

our %PAYSYSTEM_CONF = (
  PAYSYS_YKASSA_USERNAME	=> '',
  PAYSYS_YKASSA_PASSWORD	=> '',
  PAYSYS_YKASSA_URL		=> '',
  PAYSYS_YKASSA_SERVICE_NAME    => '',
  PAYSYS_YKASSA_DEFAULT_PHONE	=> '',
  PAYSYS_YKASSA_DEFAULT_EMAIL	=> ''
);

my ($html, $json);
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

  my ($db, $admin, $CONF, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
    DEBUG => $CONF->{PAYSYS_DEBUG} || 0,
  };

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  load_pmodule('JSON');
  $json = JSON->new->allow_nonref;

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 get_settings() - return hash of settings

  Arguments:


  Returns:
    HASH
=cut
#**********************************************************
sub get_settings {
  my %SETTINGS = ();

  $SETTINGS{VERSION} = $PAYSYSTEM_VERSION;
  $SETTINGS{ID} = $PAYSYSTEM_ID;
  $SETTINGS{NAME} = $PAYSYSTEM_NAME;

  $SETTINGS{CONF} = \%PAYSYSTEM_CONF;

  return %SETTINGS;
}

#**********************************************************
=head2 user_portal()

=cut
#**********************************************************
sub user_portal {
  my $self = shift;
  my ($user, $attr) = @_;

  if ($attr->{TRANSACTION_ID}) {
    main::paysys_show_result({ %$attr });
    return 1;
  }

  use Paysys;
  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});

  $Paysys->add({
    SYSTEM_ID      => $attr->{PAYMENT_SYSTEM},
    SUM            => $attr->{SUM},
    UID            => $attr->{UID} || $user->{UID},
    IP             => "$ENV{'REMOTE_ADDR'}",
    TRANSACTION_ID => "YK:$attr->{OPERATION_ID}",
    STATUS         => 1,
    DOMAIN_ID      => $user->{DOMAIN_ID}
  });

### Debug params to file
#  open(my $file, '>>', '/usr/axbills/var/log/YKassa.log') or die "Could not open file for writing: $!";
###

  my $amount = $attr->{SUM} * 100;

  my $phone = $user->{CELL_PHONE};
  if ($phone) {
      if ($phone =~ /\+?\d{11}$/ || $phone =~ /\d{11}$/) {
          $phone =~ s/\+//;
      } else {
          $phone = $self->{conf}{PAYSYS_YKASSA_DEFAULT_PHONE};
      }
  } else {
      $phone = $self->{conf}{PAYSYS_YKASSA_DEFAULT_PHONE};
  }


  my $email = $user->{EMAIL} || $self->{conf}{PAYSYS_YKASSA_DEFAULT_EMAIL};
  my $sname = $self->{conf}{PAYSYS_YKASSA_SERVICE_NAME};

  my $OB = '{"customerDetails": {"phone": "' . "$phone" . '","email": "' . "$email" . '"},"cartItems": {"items": [{"name": "' . "$sname" . '","quantity": {"value": "1","measure": "0"},"itemPrice": ' . "$amount" . ',"itemCurrency": 643,"tax": {"taxType": 0},"itemAttributes": {"attributes": [{"name": "paymentMethod","value": "3"},{"name": "paymentObject","value": "4"}]}}]}}';

### Print parameters to file
#  print $file "$phone\n$email\n$sname\n$OB\n";
###

  my $url_conf = $self->{conf}{PAYSYS_YKASSA_URL};
  $url_conf =~ s/\/$//;


  my $url = $url_conf."/payment/rest/register.do";
   my $do_register_result = web_request(
       $url,
       {
         HEADERS => ['Content-Type: application/x-www-form-urlencoded'],
         REQUEST_PARAMS => {
           amount => $amount, 
           orderNumber => $attr->{OPERATION_ID},
           password => $self->{conf}{PAYSYS_YKASSA_PASSWORD},
           userName => $self->{conf}{PAYSYS_YKASSA_USERNAME},
           returnUrl => "$ENV{PROT}://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/index.cgi?index=$attr->{index}&PAYMENT_SYSTEM=$attr->{PAYMENT_SYSTEM}&TRANSACTION_ID=YK:$attr->{OPERATION_ID}",
           orderBundle => $OB
       },
         CURL => 1,
       }
   );

  my $RESULT_HASH = $json->decode($do_register_result);

  if ($RESULT_HASH->{errorCode}) {
    $html->message("err", "Error code $RESULT_HASH->{errorCode}", "$RESULT_HASH->{errorMessage}")
  }
  else {
    return $html->tpl_show(
      main::_include('paysys_ykassa_user_portal', 'Paysys'),
      {
        URL => $RESULT_HASH->{formUrl},
      },
      { OUTPUT2RETURN => 0 }
    );
  }
}

#**********************************************************
=head2 process()

  Payment Request:
    operation => deposited
    amount => 100
    mdOrder => 3ff6962a-7dcc-4283-ab50-a6d7dd3386fe
    orderNumber => 35351086
    status => 1
    checksum => DBBE9E54D42072D8CAF32C7F660DEB82086A25C14FD813888E231A99E1220AB3


=cut
#**********************************************************
sub proccess {
  my $self = shift;
  my ($FORM) = @_;

  if ($FORM->{operation} && $FORM->{operation} ne 'deposited') {
    print qq{Status: 520 Wrong Operation
Content-type: text/html

<HTML>
<HEAD><TITLE>520 Wrong Operation</TITLE></HEAD>
<BODY>
  <H1>Error</H1>
  <P>Wrong Operation</P>
</BODY>
</HTML>
    };

    return 0;
  }

  if (defined($FORM->{status}) && $FORM->{status} != 1) {
    print qq{Status: 520 Wrong Status
Content-type: text/html

<HTML>
<HEAD><TITLE>520 Wrong Status</TITLE></HEAD>
<BODY>
  <H1>Error</H1>
  <P>Wrong Status</P>
</BODY>
</HTML>
    };

    return 0;
  }

  my $checksum = $FORM->{checksum} || '';
  my $key = $self->{conf}{PAYSYS_YK_KEY} || '';
  delete $FORM->{checksum};
  delete $FORM->{__BUFFER};

  my $checksum_raw_string = '';

  my $order = $FORM->{orderNumber};

  my ($status_code) = main::paysys_pay({
    PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
    PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
    ORDER_ID          => "YK:$order",
    EXT_ID            => $order,
    #SUM               => $sum,
    DATA              => $FORM,
    DATE              => "$main::DATE $main::TIME",
    MK_LOG            => 1,
    DEBUG             => $self->{DEBUG},
    PAYMENT_DESCRIBE  => $FORM->{description} || 'ЮКасса',
  });

  if ($status_code == 0) {
    print "Content-Type: text/html\n\n";
    print '';
    return 1;
  }

  return 1;
}

1;
