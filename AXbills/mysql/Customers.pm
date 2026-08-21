package Customers;

=head1 NAME

  Customer helpers. Company details live on users.is_company / users_pi.

=cut

use strict;
use Users;

#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 company_from_uid($uid)

  Fills a hash compatible with former Companies->info() for docs print.

=cut
#**********************************************************
sub company_from_uid {
  my $self = shift;
  my ($uid) = @_;

  return {} if (!$uid);

  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->info($uid);
  $Users->pi({ UID => $uid });

  return {
    UID              => $uid,
    BILL_ID          => $Users->{BILL_ID} || 0,
    DEPOSIT          => $Users->{DEPOSIT},
    CREDIT           => $Users->{CREDIT},
    CREDIT_DATE      => $Users->{CREDIT_DATE},
    NAME             => $Users->{COMPANY_NAME} || '',
    TAX_NUMBER       => $Users->{INN} || '',
    KPP              => $Users->{KPP} || '',
    OGRN             => $Users->{OGRN} || '',
    OKPO             => $Users->{OKPO} || '',
    BANK_BIC         => $Users->{BANK_BIC} || '',
    BANK_NAME        => $Users->{BANK_NAME} || '',
    BANK_ACCOUNT     => $Users->{BANK_ACCOUNT} || '',
    COR_BANK_ACCOUNT => $Users->{COR_BANK_ACCOUNT} || '',
    CONTRACT_ID      => $Users->{CONTRACT_ID} || '',
    CONTRACT_DATE    => $Users->{CONTRACT_DATE} || '',
    PHONE            => $Users->{PHONE} || '',
    ADDRESS          => join(' ', grep { $_ } ($Users->{ADDRESS_STREET}, $Users->{ADDRESS_BUILD}, $Users->{ADDRESS_FLAT})),
    VAT              => 0,
    IS_COMPANY       => $Users->{IS_COMPANY} || 0,
    COMPANY_ID       => 0,
  };
}

1
