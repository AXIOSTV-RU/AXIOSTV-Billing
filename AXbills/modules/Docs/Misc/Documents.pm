package Docs::Misc::Documents;
=head1 NAME

  Docs::Misc::Documents - save docs to the server

=head2 SYNOPSIS

  This package for saving docs

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(cmd encode_base64);

my AXbills::HTML $html;

#**********************************************************
=head2 new($db,$admin,\%conf) - constructor for Portal::Misc::Attachments

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    html  => $attr->{html}
  };

  $html = $attr->{html};

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 document_info($attr) - get document info

  Arguments:
    $attr
      CONTENT: file content which need to save on the disk
      DOC_TYPE: type of document
      DOC_ID: id of document which saving
      DOC_NAME?: custom name of the document
      UID?: - user id for whom belongs this document
      COMPANY_ID?: - company id for whom belongs this document
      CHECK_IS_EXISTS?: - document

  Returns:

=cut
#**********************************************************
sub document_info {
  my $self = shift;
  my ($attr) = @_;

  my $doc_info_result = $self->_get_filepath($attr);
  return $doc_info_result if ($doc_info_result->{errno});

  return { result => 'OK' } if ($attr->{CHECK_IS_EXISTS});

  my $content = '';

  if (open(my $fh, '<', $doc_info_result->{document}->{filepath})) {
    while(<$fh>) {
      $content .= $_;
    }
    close($fh);

    return {
      result => 'OK',
      content => $content,
      %{$doc_info_result->{document}},
    };
  }
  else {
    return {
      errno  => 1054210,
      errstr => 'ERR_FAILED_OPEN_FILE',
    };
  }
}

#**********************************************************
=head2 document_print($attr) - print document

  Arguments:
    $attr
      CONTENT: file content which need to save on the disk
      DOC_TYPE: type of document
      DOC_ID: id of document which saving
      DOC_NAME?: custom name of the document
      UID?: - user id for whom belongs this document
      COMPANY_ID?: - company id for whom belongs this document
      PRINT_HEADERS:? - print headers
      PDF:? - print as pdf file

  Returns:

=cut
#**********************************************************
sub document_print {
  my $self = shift;
  my ($attr) = @_;

  my $doc_info = $self->document_info($attr);

  return $doc_info if ($doc_info->{errno});

  # if ($self->{conf}->{DOCS_PDF_PRINT}) {
  if ($attr->{PDF}) {
    require AXbills::PDF;
    my $pdf = AXbills::PDF->new({
      CONF     => $self->{conf},
      CHARSET  => $self->{conf}->{default_charset},
      NO_PRINT => 1,
    });

    print $pdf->pdf_header({ NAME => $doc_info->{filename} }) if ($attr->{PRINT_HEADERS});
    print $doc_info->{content};
  }
  else {
    $html .= $doc_info->{content};
  }

  return {
    result => 'OK',
    %{$doc_info},
  };
}

#**********************************************************
=head2 document_save($attr) - saving document on server

  Arguments:
    $attr
      CONTENT: file content which need to save on the disk
      DOC_TYPE: type of document
      DOC_ID: id of document which saving
      DOC_NAME?: custom name of the document
      UID?: - user id for whom belongs this document
      COMPANY_ID?: - company id for whom belongs this document

  Returns:
    $success:
      result: str - result message if success
      file: str - document name
      filepath: str - path where stored document

    $error
      errno: int - error id
      errstr: str - error lang key
      err_message?: str - describe of error
      file?: str - document name
      filepath?: str - path where stored document, returns only if file not exists

=cut
#**********************************************************
sub document_save {
  my $self = shift;
  my ($attr) = @_;

  return {
    errno  => 1054200,
    errstr => 'ERR_NO_CONTENT',
  } if (!$attr->{CONTENT});

  # get filepath where can be stored file and check is already exists
  my $doc_info_result = $self->_get_filepath($attr);

  if ($doc_info_result->{result}) {
    return {
      errno  => 1054206,
      errstr => 'ERR_DOCUMENT_ALREADY_SAVED',
    };
  }
  elsif (!$doc_info_result->{document}) {
    return $doc_info_result;
  }

  my $doc_info = $doc_info_result->{document};

  if (!-e $doc_info->{directory}) {
    my $create_result = $self->_make_dir($doc_info->{directory});
    return $create_result if $create_result->{errno};
  }

  if (open(my $fh, '>', $doc_info->{filepath})) {
    binmode $fh;
    print $fh $attr->{CONTENT};
    close($fh);
  }
  else {
    return {
      errno  => 1054204,
      errstr => 'ERR_SAVE_FILE',
    };
  }

  return {
    result   => 'OK',
    file     => $doc_info->{file},
    filepath => $doc_info->{filepath},
  };
}

#**********************************************************
=head2 document_delete($attr) - saving document on server

  Arguments:
    $attr
      DOC_TYPE: type of document
      DOC_ID: id of document which saving
      DOC_NAME?: custom name of the document
      UID?: - user id for whom belongs this document
      COMPANY_ID?: - company id for whom belongs this document

  Returns:
    $success:
      result: str - result message if success
      file: str - document name
      filepath: str - path where stored document

    $error
      errno: int - error id
      errstr: str - error lang key
      err_message?: str - describe of error
      file?: str - document name
      filepath?: str - path where stored document, returns only if file not exists

=cut
#**********************************************************
sub document_delete {
  my $self = shift;
  my ($attr) = @_;

  # get filepath where can be stored file
  my $doc_info_result = $self->_get_filepath($attr);

  return $doc_info_result if ($doc_info_result->{errno});

  unlink $doc_info_result->{document}->{filepath} if (-f $doc_info_result->{document}->{filepath});

  return {
    result   => 'Deleted document',
    document => $doc_info_result->{document},
  };
}

#**********************************************************
=head2 _document_validation($attr) - validate document is valid

  Arguments:
    $attr
      CONTENT: file content which need to save on the disk
      DOC_TYPE: type of document
      DOC_ID: id of document which saving
      DOC_NAME?: custom name of the document
      UID?: - user id for whom belongs this document
      COMPANY_ID?: - company id for whom belongs this document

  Returns:
    $success:
      result: str - result message if success

    $error
      errno: int - error id
      errstr: str - error lang key

=cut
#**********************************************************
sub _document_validation {
  my $self = shift;
  my ($attr) = @_;

  return {
    errno  => 1054201,
    errstr => 'ERR_NO_DOC_TYPE_OR_DOC_ID',
  } if (!$attr->{DOC_TYPE} || !$attr->{DOC_ID});

  return {
    errno  => 1054202,
    errstr => 'ERR_NO_UID_OR_COMPANY_ID'
  } if (!$attr->{UID} && !$attr->{COMPANY_ID});

  return {
    result => 'OK',
  };
}

#**********************************************************
=head2 _get_filepath($attr) - get path where stored document

  Arguments:
    $attr
      DOC_TYPE: type of document
      DOC_ID: id of document which saving
      DOC_NAME?: custom name of the document
      UID?: - user id for whom belongs this document
      COMPANY_ID?: - company id for whom belongs this document

  Returns:
    $success:
      result: str - result message if success
      document?:
        file: str - document name
        filepath: str - path where stored document
        directory: str - directory where stored document
        filename: str - name of file

    $error
      errno: int - error id
      errstr: str - error lang key
      err_message: str - describe of error

=cut
#**********************************************************
sub _get_filepath {
  my $self = shift;
  my ($attr) = @_;

  #legacy document naming
  my $filename = $attr->{FILE_NAME} || $attr->{EMAIL_ATTACH_FILENAME} || $attr->{TEMPLATE};
  $filename .= '_' . ($attr->{UID} || q{});
  $filename .= '_' . ($attr->{DOC_ID} || q{});

  my $base_dir = $self->{conf}->{DOCS_STORE_DIR} || '/usr/axbills/AXbills/templates/docs/';

  my $file_ext = $self->{conf}->{DOCS_PDF_PRINT} ? '.pdf' : '.htm';
  my $filepath = $base_dir . $filename . $file_ext;

  if (-f $filepath) {
    return {
      result   => 'OK',
      document => {
        filepath  => $filepath,
        directory => $base_dir,
        file      => "$filename$file_ext",
        filename  => $filename,
        doc_id    => $attr->{DOC_ID},
        uid       => $attr->{UID},
      },
    };
  }
  elsif ($attr->{LEGACY_SAVE}) {
    return {
      errno       => 1054205,
      errstr      => 'ERR_NO_DOCUMENT',
      err_message => 'Document path not found',
      document    => {
        filepath  => $filepath,
        directory => $base_dir,
        file      => "$filename$file_ext",
        filename  => $filename
      },
    };
  }

  #validate options in new scheme save
  my $validation_result = $self->_document_validation($attr);
  return $validation_result if ($validation_result->{errno});

  my $dir_prefix = $attr->{UID} ? "user/$attr->{UID}" : "company/$attr->{COMPANY_ID}";

  my %file_prefixes = (
    1 => 'invoice',
    2 => 'act',
    3 => 'receipt',
    4 => 'contract',
    5 => 'ext_contract'
  );

  my $file_prefix = $file_prefixes{$attr->{DOC_TYPE}} || 'doc';
  $filename = $attr->{DOC_NAME} || "$file_prefix\_$attr->{DOC_ID}";

  my $directory = "$base_dir$dir_prefix/";
  $filepath = "$directory$filename$file_ext";

  if (-f $filepath) {
    return {
      result   => 'OK',
      document => {
        filepath  => $filepath,
        directory => $directory,
        file      => "$filename$file_ext",
        filename  => $filename
      },
    };
  }
  else {
    return {
      errno       => 1054207,
      errstr      => 'ERR_NO_DOCUMENT',
      err_message => 'Document path not found',
      document    => {
        filepath  => $filepath,
        directory => $directory,
        file      => "$filename$file_ext",
        filename  => $filename
      },
    };
  }
}

#**********************************************************
=head2 _make_dir($directory) - create dir for docs

  Arguments:
    $directory: directory which need to create

  Returns:

=cut
#**********************************************************
sub _make_dir {
  my $self = shift;
  my ($directory) = @_;
  require File::Path;
  File::Path->import('make_path');

  my $make_path_errors = [];
  File::Path::make_path($directory, { error => \$make_path_errors });
  if (@{$make_path_errors}) {
    my $error_string = '';
    for my $diag (@$make_path_errors) {
      my ($file, $message) = %$diag;
      if ($file eq '') {
        $error_string .= "General error: $message\n";
      }
      else {
        $error_string .= "$file: $message\n";
      }
    }

    return {
      errno       => 1054203,
      errstr      => 'ERR_CREATE_DIRECTORY',
      err_message => "Can't create directory '$directory' : $error_string",
    };
  }
  else {
    return {
      result => 'OK',
    };
  }
}

#**********************************************************
=head2 document_hash() - get md5 of file

  Arguments:
      DOC_TYPE: type of document
      DOC_ID: id of document which saving
      UID?: - user id for whom belongs this document
      COMPANY_ID?: - company id for whom belongs this document

  Returns:
    $success:
      result: str - result message if success
      hash: str - md5 checksum of file
      file: str - document name
      filepath: str - path where stored document
      directory: str - directory where stored document
      filename: str - name of file

    $error
      errno: int - error id
      errstr: str - error lang key
      err_message: str - describe of error

=cut
#**********************************************************
sub document_hash {
  my $self = shift;
  my ($attr) = @_;

  my $doc_info = $self->document_info($attr);

  return $doc_info if ($doc_info->{errno});

  my $result = cmd("md5sum $doc_info->{filepath} | awk '{print \$1}' | tr -d '\n'");

  my $base64 = encode_base64($result);
  $base64 =~ s/[\r\n]+//g;

  return {
    %$doc_info,
    result      => 'OK',
    hash        => $result,
    hash_base64 => $base64,
  };
}

1;
