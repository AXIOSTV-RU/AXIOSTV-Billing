package Crm::Errors;

=head1 NAME

  Crm::Errors - returns errors of module Crm

=cut


use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 errors() - errors list

=cut
#**********************************************************
sub errors {
  return {
    1230001 => 'ERR_CRM_PHONE_NOT_FOUND',
    1230002 => 'ERR_CRM_EXTERNAL_CMD_NOT_FOUND',
    1230003 => 'ERR_CRM_EXTERNAL_CMD_ERROR',
  };
}

1;
