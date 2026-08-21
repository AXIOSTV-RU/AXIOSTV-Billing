=head1 Paykeeper
  New module for Paykeeper payment system

  Version:1.07

  Date: 10.09.2024

=cut

use strict;
use warnings FATAL => 'all';
use AXbills::Fetcher qw/web_request/;
use AXbills::Base qw/_bp load_pmodule urlencode/;
use Digest::MD5 qw(md5_hex);

require Paysys::Paysys_Base;
package Paysys::systems::Paykeeper;

our $PAYSYSTEM_NAME = 'Paykeeper';
our $PAYSYSTEM_SHORT_NAME = 'PK';
our $PAYSYSTEM_ID = 201;
our $PAYSYSTEM_IP = '91.142.84.206';
our $PAYSYSTEM_VERSION = '1.07';

our %PAYSYSTEM_CONF = (
  PAYSYS_PAYKEEPER_URL		=> '',
  PAYSYS_PAYKEEPER_SECRET	=> '',
  PAYSYS_PAYKEEPER_DEFAULT_PHONE => '',
  PAYSYS_PAYKEEPER_DEFAULT_EMAIL => ''
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

  AXbills::Base::load_pmodule('JSON');
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
  $SETTINGS{IP} = $PAYSYSTEM_IP;
  
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
    my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf})
        or die "Ошибка создания объекта Paysys";

    my $amount = $attr->{SUM};
    my $login = $user->{LOGIN}; 
    my $url_conf = $self->{conf}{PAYSYS_PAYKEEPER_URL};

    my $phone = $user->{CELL_PHONE} || $self->{conf}{PAYSYS_PAYKEEPER_DEFAULT_PHONE};
    my $email = $user->{EMAIL} || $self->{conf}{PAYSYS_PAYKEEPER_DEFAULT_EMAIL};


    my %info = (
      PAYMENT_AMOUNT => $amount,
      LOGIN => $login,
      URL => $url_conf,
      OPERATION_ID => $attr->{OPERATION_ID},
      CELL_PHONE => $phone,
      EMAIL => $email,
    );
    
  $html->tpl_show(main::_include('paysys_paykeeper_form_pay', 'Paysys'), \%info);
}

#**********************************************************
=head2 process()

  Payment Request:

=cut
#**********************************************************
sub proccess {
	my $self = shift;
    my ($FORM) = @_;

    my $secret_word = $self->{conf}{PAYSYS_PAYKEEPER_SECRET};
	
	my $result_code = '';

    my $id  = $FORM->{id}  || '';
    my $sum = $FORM->{sum} || '';
    my $key = $FORM->{key} || '';
    my $login = $FORM->{clientid} || '';
    my $orderid  = $FORM->{orderid}  || '';

  unless (defined $id && defined $sum && defined $key && defined $login) {
    print "Content-Type: text/html\n\n";
    print "'400 Bad Request'";
    exit;
  }

  my $signature = Digest::MD5::md5_hex($id . $sum . $login . $orderid . $secret_word);
  unless ($signature eq $key) {
    print "Content-Type: text/html\n\n";
    print "Invalid key\n";
    exit;
  }
  
	$result_code = main::paysys_pay({
        PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
        PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
        CHECK_FIELD       => 'LOGIN',
        USER_ID           => $login,
        SUM               => $sum,
        EXT_ID            => $id,
        DATE              => "$main::DATE $main::TIME",
        PAYMENT_DESCRIBE  => 'Оплата через внешнюю систему Paykeeper',
        DEBUG             => $self->{DEBUG},
     });

  if($result_code == 0){
    my $response_hash = Digest::MD5::md5_hex($id . $secret_word);

    print "Content-Type: text/plain\n\n";
    print "OK $response_hash";
  } else {
	print "Content-Type: text/plain\n\n";
    print "NOT OK\n";	  
  }
 }

1;
