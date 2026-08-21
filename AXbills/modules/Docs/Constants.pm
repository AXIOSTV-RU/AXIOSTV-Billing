package Docs::Constants;
=head1 NAME

  Docs::Constants - values that have to be equal all over modules using Docs

=head2 SYNOPSIS

  This package aggregates global values of Docs module uses

=cut


use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

use constant {
  DOC_TYPES    => {
    INVOICE      => 1,
    ACT          => 2,
    RECEIPT      => 3,
    CONTRACT     => 4,
    EXT_CONTRACT => 5,
  },
  EDOCS_STATUS => {
    0 => 'DOCUMENT_SIGNED',
    1 => 'DOCUMENT_SIGNING',
    2 => 'DOCUMENT_ALREADY_SIGNING'
  }
};

our @EXPORT = qw/
  DOC_TYPES
  EDOCS_STATUS
/;

1;
