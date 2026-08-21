package Crm::Attachments;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Crm::Attachments

=head2 SYNOPSIS

  This package is a transparent layer to work with files on disk

=cut

use Attach;
use Crm::db::Crm;

my Attach $Attach;
my $Crm;

use AXbills::Base qw(in_array);

my %ATTACH_CRM_PARAMS = (ATTACH_PATH => 'crm');

#**********************************************************
=head2 new($db,$admin,\%conf) - constructor for Portal::Misc::Attachments

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = {
    db           => $db,
    admin        => $admin,
    conf         => $CONF,
    save_to_disk => 1,
    files_dir    => 'portal'
  };

  bless($self, $class);

  $Attach //= Attach->new(@{$self}{qw/db admin conf/}, \%ATTACH_CRM_PARAMS);
  $Crm //= Crm->new(@{$self}{qw/db admin conf/});

  return $self;
}

sub attachment_path {
  return $Attach->{ATTACH2FILE};
}

#**********************************************************
=head2 attachment_add($attr) - saves attachment

  Arguments:
    $attr -

=cut
#**********************************************************
sub attachment_add {
  my $self = shift;
  my ($attr) = @_;

  my $file_name = $attr->{filename};
  return '' if (!$file_name);

  my $file_extension;
  if ($file_name =~ /\.([a-z0-9\_]+)$/i) {
    $file_extension = $1;
  }
  my $random_name = int(rand(16777215));
  $file_name = "$random_name.$file_extension";

  my $file_path = $self->_save_to_disk($file_name, { CONTENT => $attr->{Contents} });
  return $self if (!$file_path || $self->{errno});

  my $size = $attr->{Size};
  $size = (stat($file_path))[7] if (!$size);

  $Crm->crm_attachment_add({
    FILENAME     => $file_name,
    CONTENT_TYPE => $attr->{'Content-Type'},
    FILE_SIZE    => $size,
  });
  $Attach->attachment_file_del({ FILENAME => $file_name }) if ($Crm->{errno});
  $Crm->{FILENAME} = $file_name if !$Crm->{errno};

  return $Crm;
}

#**********************************************************
=head2 attachment_del($attr) - delete attachment

  Arguments:
    $attr

=cut
#**********************************************************
sub attachment_del {
  my $self = shift;
  my $id = shift;

  return '' if (!$id);

  $Crm->crm_attachment_info($id);
  return $Crm if ($Crm->{errno} || !$Crm->{FILENAME});

  $Crm->crm_attachment_del({ ID => $id });
  return $Crm if $self->{errno};

  $Attach->attachment_file_del({ FILENAME => $Crm->{FILENAME} });

  return $Crm;
}

#**********************************************************
=head2 attachment_info($attachment_id, $attr) -

  Arguments:
     $attachment_id

=cut
#**********************************************************
sub attachment_info {
  my $self = shift;
  my $attachment_id = shift;
  my ($attr) = @_;

  $Crm->crm_attachment_info($attachment_id);
  return '' if $Crm->{errno} || !$Crm->{FILENAME};

  my $directory = $self->attachment_path();
  my $filename = $Crm->{FILENAME};

  if ($directory && $filename && -f "$directory/$filename" && !$attr->{WITHOUT_CONTENT}) {
    $Crm->{CONTENT} = $self->_read_file_from_disk($directory, $filename);
  }

  return $Crm;
}

#**********************************************************
=head2 _read_file_from_disk($directory, $filename)

=cut
#**********************************************************
sub _read_file_from_disk {
  my $self = shift;
  my ($directory, $filename) = @_;

  if ( open(my $fh, '<', join('/', ($directory, $filename))) ) {
    my $content = '';
    while ( my $line = <$fh> ) {
      $content .= $line;
    }
    return $content;
  }
  else {
    $self->{errno} = 111;
    $self->{errstr} = "Can't read file : $@";
  }

  return 0;
}

#**********************************************************
=head2 _save_to_disk($msg_id, $reply_id, $filename, $attr) - writes file to disk

  Arguments:
    $msg_id,
    $reply_id,
    $filename,
    $attr

  Returns:
    full file path

=cut
#**********************************************************
sub _save_to_disk {
  my $self = shift;
  my ($filename, $attr) = @_;

  $filename //= '';
  $filename =~ s/[^a-zA-Z0-9._-]/_/g;

  # Should change filename. map will replace undefined values with 0
  my $disk_filename = join('_', map {$_ // '0'} ($filename));

  my $final_path = $Attach->save_file_to_disk({
    %{$attr},
    FILENAME          => $filename,
    DISK_FILENAME     => $disk_filename,
    DIRECTORY_TO_SAVE => ''
  });

  if ($Attach->{errno}) {
    $self->{errno} = $Attach->{errno};
    $self->{errstr} = $Attach->{errstr};
    return 0;
  }

  return $final_path;
}

1;
