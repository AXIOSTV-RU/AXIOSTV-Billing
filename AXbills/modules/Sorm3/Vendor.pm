package Sorm3::Vendor;

=head1 NAME

  SORM3 vendor helpers (table prefix, export dir, admin family)

=cut

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 type($conf)

=cut
#**********************************************************
sub type {
  my ($conf) = @_;
  $conf ||= {};
  my $type = lc($conf->{SORM3_TYPE} || '');
  $type =~ s/^\s+|\s+$//g;
  return $type;
}

#**********************************************************
=head2 table_prefix($conf)

=cut
#**********************************************************
sub table_prefix {
  my ($conf) = @_;
  $conf ||= {};
  if ($conf->{SORM3_TABLE_PREFIX}) {
    my $pfx = uc($conf->{SORM3_TABLE_PREFIX});
    $pfx =~ s/[^A-Z0-9_]//g;
    return $pfx if $pfx;
  }

  my $type = type($conf);
  return 'NORSI'   if $type eq 'norsi';
  return 'CITADEL' if $type eq 'citadel';
  return 'MFISOFT' if $type eq 'mfisoft';
  return 'SPECTECH';
}

#**********************************************************
=head2 export_dir($conf)

=cut
#**********************************************************
sub export_dir {
  my ($conf) = @_;
  $conf ||= {};
  return $conf->{SORM3_EXPORT_DIR} if $conf->{SORM3_EXPORT_DIR};

  my $type = type($conf);
  return 'Norsi'   if $type eq 'norsi';
  return 'Citadel' if $type eq 'citadel';
  return 'Mfisoft' if $type eq 'mfisoft';
  return 'Spectech';
}

#**********************************************************
=head2 family($conf)

  spectech - Spectech/Norsi admin (ip_pools)
  citadel  - Citadel/Mfisoft admin (main_dictionaries)

=cut
#**********************************************************
sub family {
  my ($conf) = @_;
  my $type = type($conf);
  return 'citadel' if $type eq 'citadel' || $type eq 'mfisoft';
  return 'spectech';
}

1;
