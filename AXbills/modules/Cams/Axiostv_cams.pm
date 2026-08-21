package Cams::Axiostv_cams;

=head1 NAME

Cams::Axiostv_cams - A Perl module for interacting with the Axiostv_cams service

=head1 VERSION

  VERSION: 0.02

=head1 SYNOPSIS

=cut

use strict;
use warnings;
use parent qw(dbcore);
use AXbills::Base qw(load_pmodule);
use AXbills::Fetcher;

use JSON;

 use Data::Dumper;

my ($admin, $CONF);
our $VERSION = 0.02;
my $MODULE = 'Axoistv_cams';
my $json;
my $html;
my $lang;
my $Cams;

#**********************************************************
# Init
# Billing CRUD (service/tariff/user SQL) does not depend on methods below.
# External platform hooks are optional: Users.pm / Services.pm call them only via can().
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
   $admin = shift;
   $CONF = shift;
  my $attr = shift;


  $Cams = Cams->new($db, $admin, $CONF);

  $admin->{MODULE} = $MODULE;

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  if ($attr->{LANG}) {
    $lang = $attr->{LANG};
  }

  my $self = {};
  bless($self, $class);

  load_pmodule('JSON');

  $json = JSON->new->allow_nonref;
  $self->{SERVICE_NAME} = $MODULE;
  $self->{VERSION} = $VERSION;
  $self->{db} = $db;

  $self->{LOGIN} = $attr->{LOGIN};
  $self->{PASSWORD} = $attr->{PASSWORD};
  $self->{URL} = $attr->{URL} || '';
  $self->{debug} = $attr->{DEBUG} || 0;
  $self->{DEBUG_FILE} = $attr->{DEBUG_FILE};
  $self->{request_count} = 0;

  $self->{VERSION} = $VERSION;

  if ($self->{debug}) {
    print "Content-Type: text/html\n\n";
  }
  
  return $self;
}

#**********************************************************
=head2 test($attr) - Test service

=cut
#**********************************************************
sub test {
  my $self = shift;

  my $token = $self->get_api_token({
    URL      => $self->{URL},
    LOGIN    => $self->{LOGIN},
    PASSWORD => $self->{PASSWORD},
  });

  if ($token) {
    return 'Ok';
  }

  $self->{errno} = 1005;
  $self->{errstr} = 'Unknown Error';
  return 'Unknown Error';
}

################################
#### BLOCK DOORPHONE / KEYS ####
################################

#**********************************************************
=head2 get_api_token($attr)

RESULT: 
  return $token

=cut
#**********************************************************

sub get_api_token {
    my ($self,$attr) = @_;

    $self->{URL} = $attr->{URL};
    $self->{LOGIN} = $attr->{LOGIN};
    $self->{PASSWORD} = $attr->{PASSWORD};

    my @params = ('Content-Type: application/json');
    my $request_url = "$self->{URL}/bill/api/auth/";
    my $result = web_request($request_url,
        {
            HEADERS      => \@params,
            DEBUG        => '0',
            CURL         => 1,
            CURL_OPTIONS => undef,
            POST         => '[{\"username\":\"' . $self->{LOGIN} . '\",\"password\":\"' . $self->{PASSWORD} . '\"}]',
        });

    unless ($result) {
        warn "Failed to fetch API token";
        return;
    }

    my $perl_scalar = eval { $json->decode($result) };
    if ($@) {
        warn "Failed to decode JSON response: $@";
        return;
    }

    return $perl_scalar->{token};
}

#**********************************************************
=head2 dph_keys_get_devices_list($attr)

=cut
#**********************************************************

sub dph_keys_get_devices_list {
  my ($self, $attr) = @_;

  my $token = $self->get_api_token($attr);
  unless ($token) {
    warn "Failed to get API token";
    return;
  }

  my @params = (
    'Content-Type: application/json',
    'Authorization: Bearer ' . $token
  );

  my $post = {};
  $post->{uid} = $attr->{UID} if defined $attr->{UID} && $attr->{UID} ne q{};

  my $result = web_request("$self->{URL}/bill/api/devices_list/",
    {
      HEADERS      => \@params,
      DEBUG        => "0",
      CURL         => 1,
      CURL_OPTIONS => "-X POST",
      POST         => $json->encode($post),
    }
  );  
  my $user_rights_array = eval { $json->decode($result) };
  if ($@) {
    warn "Failed to decode devices list JSON response: $@";
    return;
  }

  if (ref $user_rights_array eq 'ARRAY') {
    return { devices => $user_rights_array };
  }

  return $user_rights_array;
}

#**********************************************************
=head2 dph_keys_get_right_list($attr)

=cut
#**********************************************************

sub dph_keys_get_right_list {
    my ($self, $attr) = @_;

    my $token = $self->get_api_token($attr);
    unless ($token) {
        warn "Failed to get API token";
        return;
    }

    my @params = (
        'Content-Type: application/json',
        'Authorization: Bearer ' . $token
    );


    my $result = web_request("$self->{URL}/bill/api/rights_list/",
        {
            HEADERS      => \@params,
            DEBUG        => "0",
            CURL         => 1,
            CURL_OPTIONS => "-X POST",
            POST         => '{\"uid\":\"' . $attr->{UID} . '\"}',
        }
    );


    unless ($result) {
        warn "Failed to fetch rights list";
        return;
    }

    my $user_rights_array = eval { $json->decode($result) };
    if ($@) {
        warn "Failed to decode JSON response: $@";
        return;
    }

    return $user_rights_array;
}

#**********************************************************
=head2  dph_keys_delete_right_list($attr)

=cut
#**********************************************************

sub dph_keys_delete_right_list {
  my ($self, $attr) = @_;

  my $token = $self->get_api_token($attr);
  unless ($token) {
    warn "Failed to get API token";
    return;
  }

  my @params = (
    'Content-Type: application/json',
    'Authorization: Bearer ' . $token
  );

  my $result = web_request("$self->{URL}/bill/api/rights_del/",
    {
      HEADERS      => \@params,
      DEBUG        => "0",
      CURL         => 1,
      CURL_OPTIONS => "-X POST",
      POST         => '{\"uid\":\"'.$attr->{UID}.'\",\"device_id\":\"[' . $attr->{DELETE_IDS} . ']\"}',
    }
  );

  return "TRUE";
}

#**********************************************************
=head2  dph_keys_add_right_list($attr)

=cut
#**********************************************************

sub dph_keys_add_right_list {
  my ($self, $attr) = @_;


  my $token = $self->get_api_token($attr);
  unless ($token) {
    warn "Failed to get API token";
    return;
  }
  # Получаем текущие права
  my $user_rights_array = $self->dph_keys_get_right_list({ UID => $attr->{UID}, URL => $attr->{URL}, PASSWORD => $attr->{PASSWORD}, LOGIN => $attr->{LOGIN} });

  # Проверяем есть ли уже эти айдишники       
  my @aIds = split(', ', $attr->{ADD_IDS});
  my $Element;
  while($Element=shift@{($user_rights_array->{rights})} ){   
    while (my ($key, $value) = each @aIds) {
        if ($value) {
          if ($value == $Element->{device_id}) {
            delete $aIds[$key]; 
          }
        }
    }
  }

  my $sIds = "";
  while (my ($key, $value) = each @aIds) {
    $sIds .= $value.', ';
  }
  $sIds = substr $sIds, 0, -2;
 
  my @params = (
    'Content-Type: application/json',
    'Authorization: Bearer ' . $token
  );

  my $result1 = web_request("$self->{URL}/bill/api/rights_add/",
    {
      HEADERS      => \@params,
      DEBUG        => "0",
      CURL         => 1,
      CURL_OPTIONS => "-X POST",
      POST         => '{\"uid\":\"'. $attr->{UID} .'\",\"device_id\":['.$sIds.']}',
    }
  );

  return "TRUE";
}

#**********************************************************
=head2  dph_keys_add_key($attr)

=cut
#**********************************************************

sub dph_keys_add_key {
  my ($self, $attr) = @_;

  my $token = $self->get_api_token($attr);
  unless ($token) {
    warn "Failed to get API token";
    return;
  }

  my @params = (
    'Content-Type: application/json',
    'Authorization: Bearer ' . $token
  );

  my $result1 = web_request("$self->{URL}/bill/api/keys_add/",
    {
      HEADERS      => \@params,
      DEBUG        => "0",
      CURL         => 1,
      CURL_OPTIONS => "-X POST",
      POST         => '{\"uid\":\"'.$attr->{UID}.'\",\"key\":\"'.$attr->{KEY}.'\",\"comment\":\"'.$attr->{COMMENT}.'\"}',
    }
  ); 

  return "TRUE";
}

#**********************************************************
=head2  dph_keys_delete_key($attr)

=cut
#**********************************************************

sub dph_keys_delete_key {
  my ($self, $attr) = @_;

  my $token = $self->get_api_token($attr);
  unless ($token) {
    warn "Failed to get API token";
    return;
  }

  my @params = (
    'Content-Type: application/json',
    'Authorization: Bearer ' . $token
  );

  my @aKeys = split /,/, $attr->{DELETE_KEYS_IDS};

  while (my ($key, $value) = each @aKeys) {

    my $result = web_request("$self->{URL}/bill/api/keys_del/",
      {
        HEADERS      => \@params,
        DEBUG        => "0",
        CURL         => 1,
        CURL_OPTIONS => "-X POST",
        POST         => '{\"uid\":\"'.$attr->{UID}.'\",\"key\":\"' . $value . '\"}',
      }
    );
  }

  return "TRUE";
}

#**********************************************************
=head2  dph_keys_get_keys_list($attr)

=cut
#**********************************************************

sub dph_keys_get_keys_list {
  my ($self, $attr) = @_;

  my $token = $self->get_api_token($attr);
  unless ($token) {
    warn "Failed to get API token";
    return;
  }

  my @params = (
    'Content-Type: application/json',
    'Authorization: Bearer ' . $token
  );

  my $result = web_request("$self->{URL}/bill/api/keys_list/",
    {
      HEADERS      => \@params,
      DEBUG        => "0",
      CURL         => 1,
      CURL_OPTIONS => "-X POST",
      POST         => '{\"uid\":\"'.$attr->{UID}.'\"}',
    }
  );
  my $user_keys_array = $json->decode($result);

  return $user_keys_array;
}

sub dph_keys_address_devices_list {
  my ($self, $attr) = @_;

  my $token = $self->get_api_token($attr);
  unless ($token) {
    warn "Failed to get API token";
    return;
  }

  my @params = (
    'Content-Type: application/json',
    'Authorization: Bearer ' . $token
  );

  my $result = web_request("$self->{URL}/bill/api/address_devices_list/",
    {
      HEADERS      => \@params,
      DEBUG        => "0",
      CURL         => 1,
      CURL_OPTIONS => "-X POST",
      POST         => '{\"address\":\"'.$attr->{ADDRESS}.'\"}',
    }
  );
  my $address_devices_list = $json->decode($result);
  
  return $result;
}

#**********************************************************
=head2  dph_keys_address_devices_update($attr)

=cut
#**********************************************************

sub dph_keys_address_devices_update {
  my ($self, $attr) = @_;

  my $token = $self->get_api_token($attr);
  unless ($token) {
    warn "Failed to get API token";
    return;
  }

  my @params = (
    'Content-Type: application/json',
    'Authorization: Bearer ' . $token
  );


  my $result = web_request("$self->{URL}/bill/api/address_devices_update/",
    {
      HEADERS      => \@params,
      DEBUG        => "2",
      CURL         => 1,
      CURL_OPTIONS => "-X POST",
      POST         => '{ \"data\": ['.$attr->{ARRAY}.']}',
    }
  );
  
  print Dumper("TUT3" . $attr->{ARRAY});

  my $address_devices_list = $json->decode($result);
  return $result;
}

1;
