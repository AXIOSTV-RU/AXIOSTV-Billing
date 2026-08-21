package Crm::Api;
=head NAME

  Crm::Api - Crm api functions

=head VERSION

  DATE: 20221130
  UPDATE: 20221130
  VERSION: 0.01

=cut

use strict;
use warnings FATAL => 'all';

use Crm::db::Crm;
use Crm::Attachments;

my Crm $Crm;
my Crm::Attachments $Attachments;

our %lang;
require 'AXbills/modules/Crm/lng_english.pl';

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $lang, $debug, $type, $html) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $lang,
    debug => $debug
  };

  bless($self, $class);

  my %LANG = (%{$lang}, %lang);

  $Attachments = Crm::Attachments->new($db, $admin, $conf);
  $Crm = Crm->new($db, $admin, $conf);
  $Crm->{debug} = $self->{debug};

  $self->{routes_list} = ();

  if ($type eq 'admin') {
    $self->{routes_list} = $self->admin_routes();
  }

  return $self;
}

#**********************************************************
=head2 admin_routes() - Returns available API paths

  ARGUMENTS
    admin_routes: boolean - if true return all admin routes, false - user

  Returns:
    {
      $resource_1_name => [ # $resource_1_name, $resource_2_name - names of API resources. always equals to first path segment
        {
          method  => 'GET',          # HTTP method. Path can be queried only with this method

          path    => '/users/:uid/', # API path. May contain variables like ':uid'.
                                     # these variables will be passed to handler function as argument ($path_params).
                                     # variables are always numerical.
                                     # example: if route's path is '/users/:uid/', and queried URL
                                     # is '/users/9/', $path_params will be { uid => 9 }.
                                     # if credentials is 'USER', variable :uid will be checked to contain only
                                     # authorized user's UID.

          handler => sub {           # handler function, coderef. Arguments that are passed to handler:
            my (
                $path_params,        # params from path. look at docs of path. hashref.
                $query_params,       # params from query. for details look at AXbills::Api::Router::new(). hashref.
                                     # keys will be converted from camelCase to UPPER_SNAKE_CASE
                                     # using AXbills::Base::decamelize unless no_decamelize_params is set
                        # object of needed DB module (in this example - Users). used to run it's methods.
                                     # may be empty if name of module is not set.
               ) = @_;

          ->info(       # handler should return hashref or arrayref with needed data
              $path_params->{uid}
            );                       # in this example we call Users->info, and it's result are implicitly returned
          },

          module  => 'Users',        # name of DB module. it's object will be created and passed to handler a. optional.

          type    => 'HASH',         # type of returned data. may be 'HASH' or 'ARRAY'. by default (if not set) it is 'HASH'. optional.

          credentials => [           # arrayref of roles required to use this path. if API user is authorized as at least one of
                                     # these roles access to this path will be granted. optional.
            'ADMIN'                  # may be 'ADMIN' or 'USER'
          ],

          no_decamelize_params => 0, # if set, $query_params for handler will not be converted to UPPER_SNAKE_CASE. optional.

          conf_params => [ ... ]     # variables from $conf to be returned in result. arrayref.
                                     # experimental feature, currently disabled
        },
        ...
      ],
      $resource_2_name => [
        ...
      ],
      ...
    }

=cut
#**********************************************************
sub admin_routes {
  my $self = shift;

  return [
    {
      method      => 'POST',
      path        => '/crm/leads/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        if ($query_params->{CURRENT_STEP} && $query_params->{CURRENT_STEP} =~ /\D/g) {
          my $steps = $Crm->crm_progressbar_step_list({
            ID          => '_SHOW',
            NAME        => $query_params->{CURRENT_STEP},
            STEP_NUMBER => '_SHOW',
            COLS_NAME   => 1
          });

          $query_params->{CURRENT_STEP} = $Crm->{TOTAL} > 0 ? $steps->[0]{step_number} : 1;
        }

        $Crm->crm_lead_add($query_params);
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'PUT',
      path        => '/crm/leads/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_lead_change({ ID => $path_params->{id}, %{$query_params} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'DELETE',
      path        => '/crm/leads/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_lead_info({ ID => $path_params->{id} });
        if ($Crm->{TOTAL} < 1) {
          return {
            errno  => 104003,
            errstr => "No lead with id $path_params->{id}"
          };
        }

        $Crm->crm_lead_delete({ ID => $path_params->{id} });

        if (!$Crm->{errno}) {
          return { result => 'Successfully deleted' } if ($Crm->{AFFECTED} && $Crm->{AFFECTED} =~ /^[0-9]$/);
          return {
            errno  => 104002,
            errstr => "No lead with id $path_params->{id}"
          };
        }
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'GET',
      path        => '/crm/leads/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_lead_info({ ID => $path_params->{id} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'POST',
      path        => '/crm/leads/:id/phone/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $lead = $Crm->crm_lead_info({ ID => $path_params->{id} });
        return { errno => 1230001, errstr => 'ERR_CRM_PHONE_NOT_FOUND' } if !$lead->{PHONE};
        return { errno => 1230002, errstr => 'ERR_CRM_EXTERNAL_CMD_NOT_FOUND' } if !$self->{conf}{CRM_PHONE_EXTERNAL_CMD};

        my $result = ::_external('', { EXTERNAL_CMD => 'CRM_PHONE', %{$lead}, QUITE => 1 });
        return $result if $result;

        return { errno => 1230003, errstr => 'ERR_CRM_EXTERNAL_CMD_ERROR' };
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'GET',
      path        => '/crm/leads/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ?
            $query_params->{$param} : '_SHOW';
        }

        $query_params->{COLS_NAME} = 1;
        $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25;
        $query_params->{PG} = $query_params->{PG} ? $query_params->{PG} : 0;
        $query_params->{DESC} = $query_params->{DESC} ? $query_params->{DESC} : '';
        $query_params->{SORT} = $query_params->{SORT} ? $query_params->{SORT} : 1;

        $Crm->crm_lead_list($query_params);
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'POST',
      path        => '/crm/dialogue/:id/message/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        use AXbills::Sender::Core;
        my $Sender = AXbills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

        my $ex_params = {};
        my $dialog = $Crm->crm_dialogue_info({ ID => $path_params->{id} });
        my $lead = $Crm->crm_lead_info({ ID => $dialog->{LEAD_ID} });
        my $lead_address = $lead->{"_crm_$dialog->{SOURCE}"};

        if ($dialog->{SOURCE} eq 'mail') {
          $ex_params->{MAIL_HEADER} = [ "References: <$lead_address>", "In-Reply-To: <$lead_address>" ];
          $lead_address = $lead->{EMAIL};
        }

        $query_params->{ATTACHMENT_ID} = [ $query_params->{ATTACHMENT_ID} ] if $query_params->{ATTACHMENT_ID} && ref $query_params->{ATTACHMENT_ID} ne 'ARRAY';
        if (scalar(@{$query_params->{ATTACHMENT_ID}}) > 0) {
          my $attachments = $Crm->crm_attachment_list({
            ID           => join(';', @{$query_params->{ATTACHMENT_ID}}),
            FILENAME     => '_SHOW',
            FILE_SIZE    => '_SHOW',
            CONTENT_TYPE => '_SHOW',
            COLS_NAME    => 1
          });

          my $attachment_path=  $Attachments->attachment_path();
          $ex_params->{ATTACHMENTS} = [];
          foreach my $attachment (@{$attachments}) {
            next if !$attachment->{filename};

            push @{$ex_params->{ATTACHMENTS}}, {
              content       => "FILE: $attachment_path/$attachment->{filename}",
              content_type  => $attachment->{content_type},
              filename      => $attachment->{filename},
              content_size  => $attachment->{file_size},
              file_size     => $attachment->{file_size},
              img_file_path => '/images/attach/crm/'
            };
          }
        }

        if (!$lead_address) {
          if ($query_params->{ATTACHMENT_ID}) {
            foreach my $attachment (@{$query_params->{ATTACHMENT_ID}}) {
              $Attachments->attachment_del($attachment);
            }
          }

          return {
            errno  => 101,
            errstr => 'No found address to send'
          };
        }

        my $result = $Sender->send_message({
          TO_ADDRESS  => $lead_address,
          MESSAGE     => Encode::encode_utf8($query_params->{MESSAGE}),
          SENDER_TYPE => ucfirst $dialog->{SOURCE},
          %{$ex_params}
        });

        if (!$result) {
          if ($query_params->{ATTACHMENT_ID}) {
            foreach my $attachment (@{$query_params->{ATTACHMENT_ID}}) {
              $Attachments->attachment_del($attachment);
            }
          }

          return {
            errno  => 102,
            errstr => 'The message was not sent'
          };
        }

        $Crm->crm_dialogue_messages_add({
          MESSAGE     => $query_params->{MESSAGE},
          AID         => $self->{admin}{AID},
          DIALOGUE_ID => $path_params->{id}
        });

        if ($Crm->{errno}) {
          if ($query_params->{ATTACHMENT_ID}) {
            foreach my $attachment (@{$query_params->{ATTACHMENT_ID}}) {
              $Attachments->attachment_del($attachment);
            }
          }

          return $Crm;
        }

        my $message_id = $Crm->{INSERT_ID};
        if ($query_params->{ATTACHMENT_ID}) {
          foreach my $attachment (@{$query_params->{ATTACHMENT_ID}}) {
            $Crm->crm_attachment_change({
              ID         => $attachment,
              MESSAGE_ID => $message_id
            });
          }
        }

        return $Crm;
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'GET',
      path        => '/crm/dialogue/:id/messages/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        my $messages = $Crm->crm_dialogue_messages_list({
          MESSAGE     => '_SHOW',
          DAY         => '_SHOW',
          TIME        => '_SHOW',
          AID         => '_SHOW',
          ATTACHMENTS => '_SHOW',
          PAGE_ROWS   => 99999,
          %{$query_params},
          DIALOGUE_ID => $path_params->{id},
          SORT        => 'cdm.date',
          DESC        => 'DESC',
          COLS_NAME   => 1
        });

        foreach my $message (@{$messages}) {
          next if !$message->{attachments};

          my $attachments = $Crm->crm_attachment_list({
            MESSAGE_ID   => $message->{id},
            FILENAME     => '_SHOW',
            FILE_SIZE    => '_SHOW',
            CONTENT_TYPE => '_SHOW',
            COLS_NAME    => 1
          });

          if ($Crm->{TOTAL} && $Crm->{TOTAL} > 0) {
            $message->{attachments} = [];
            foreach my $attachment (@{$attachments}) {
              push @{$message->{attachments}}, {
                id   => $attachment->{id},
                name => $attachment->{filename},
                size => $attachment->{file_size},
                type => $attachment->{content_type}
              }
            }
          }
        }

        return $messages;
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'PUT',
      path        => '/crm/dialogue/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        if ($query_params->{AID}) {
          $Crm->crm_dialogue_info({ ID => $path_params->{id} });
          return { affected => $Crm->{AID} eq $query_params->{AID} ? 1 : undef } if $Crm->{AID};
        }

        $Crm->crm_dialogues_change({ %{$query_params}, ID => $path_params->{id} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'GET',
      path        => '/crm/dialogues/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ?
            $query_params->{$param} : '_SHOW';
        }

        $query_params->{COLS_NAME} = 1;
        $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25;
        $query_params->{PG} = $query_params->{PG} ? $query_params->{PG} : 0;
        $query_params->{DESC} = $query_params->{DESC} ? $query_params->{DESC} : '';
        $query_params->{SORT} = $query_params->{SORT} ? $query_params->{SORT} : 1;

        my $admin_open_lines = $Crm->crm_open_lines_list({ AID => $self->{admin}{AID}, SOURCE => '_SHOW', COLS_NAME => 1 });
        my $enabled_open_lines = [];
        map push(@{$enabled_open_lines}, $_->{source}), @{$admin_open_lines};

        if ($query_params->{SOURCE} && $query_params->{SOURCE} ne '_SHOW') {
          my @source_arr = $query_params->{SOURCE} =~ ';' ? split(';', $query_params->{SOURCE}) : split(',', $query_params->{SOURCE});
          my $enabled_query_open_lines = [];
          foreach my $source (@source_arr) {
            next if !AXbills::Base::in_array($source, $enabled_open_lines);
            push @{$enabled_query_open_lines}, $source;
          }

          $query_params->{SOURCE} = join(';', @{$enabled_query_open_lines}) || '_SHOW';
        }
        elsif (defined $query_params->{SOURCE}) {
          $query_params->{SOURCE} = join(';', @{$enabled_open_lines});
        }

        $Crm->crm_dialogues_list($query_params);
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'POST',
      path        => '/crm/sections/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_sections_add({ %{$query_params}, AID => $self->{admin}{AID} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'PUT',
      path        => '/crm/sections/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_sections_change({ %{$query_params}, ID => $path_params->{id}, AID => $self->{admin}{AID} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'DELETE',
      path        => '/crm/sections/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_sections_info({ ID => $path_params->{id} });
        if ($Crm->{TOTAL} < 1) {
          return {
            errno  => 104008,
            errstr => 'Section not found'
          };
        }

        $Crm->crm_sections_del({ ID => $path_params->{id} });

        if (!$Crm->{errno}) {
          return { result => 'Successfully deleted' } if ($Crm->{AFFECTED} && $Crm->{AFFECTED} =~ /^[0-9]$/);
          return {
            errno  => 104009,
            errstr => 'Section not found'
          };
        }
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'PUT',
      path        => '/crm/deals/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_deals_change({ %{$query_params}, ID => $path_params->{id} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'POST',
      path        => '/crm/progressbar/messages/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->progressbar_comment_add({ %{$query_params}, DOMAIN_ID => $self->{admin}{DOMAIN_ID} || 0 });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'PUT',
      path        => '/crm/progressbar/messages/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return $Crm->progressbar_comment_change({ %{$query_params}, ID => $path_params->{id} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'DELETE',
      path        => '/crm/progressbar/messages/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->progressbar_comment_delete({ ID => $path_params->{id} });

        if (!$Crm->{errno}) {
          return { result => 'Successfully deleted' } if ($Crm->{AFFECTED} && $Crm->{AFFECTED} =~ /^[0-9]$/);
          return {
            errno  => 104001,
            errstr => "No message with id $path_params->{id}"
          };
        }
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'POST',
      path        => '/crm/action/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_actions_add($query_params);
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'PUT',
      path        => '/crm/action/:action_id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_actions_change({ ID => $path_params->{action_id}, %{$query_params} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'DELETE',
      path        => '/crm/action/:action_id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_actions_info({ ID => $path_params->{action_id} });
        if ($Crm->{TOTAL} < 1) {
          return {
            errno  => 104004,
            errstr => 'Action not found'
          };
        }

        $Crm->crm_actions_delete({ ID => $path_params->{action_id} });

        if (!$Crm->{errno}) {
          return { result => 'Successfully deleted' } if ($Crm->{AFFECTED} && $Crm->{AFFECTED} =~ /^[0-9]$/);
          return {
            errno  => 104007,
            errstr => 'Action not found'
          };
        }
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'GET',
      path        => '/crm/action/:action_id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_actions_info({ ID => $path_params->{action_id} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'GET',
      path        => '/crm/actions/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ?
            $query_params->{$param} : '_SHOW';
        }

        $query_params->{COLS_NAME} = 1;
        $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25;
        $query_params->{PG} = $query_params->{PG} ? $query_params->{PG} : 0;
        $query_params->{DESC} = $query_params->{DESC} ? $query_params->{DESC} : '';
        $query_params->{SORT} = $query_params->{SORT} ? $query_params->{SORT} : 1;

        $Crm->crm_actions_list($query_params);
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'POST',
      path        => '/crm/step/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_progressbar_step_add($query_params);
      },
      credentials => [ 'ADMIN' ]
    },
    {
      method      => 'PUT',
      path        => '/crm/step/:step_id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_progressbar_step_change({ ID => $path_params->{step_id}, %{$query_params} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'DELETE',
      path        => '/crm/step/:step_id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_progressbar_step_info({ ID => $path_params->{step_id} });
        if ($Crm->{TOTAL} < 1) {
          return {
            errno  => 104005,
            errstr => 'Step not found'
          };
        }

        $Crm->crm_progressbar_step_delete({ ID => $path_params->{step_id} });

        if (!$Crm->{errno}) {
          return { result => 'Successfully deleted' } if ($Crm->{AFFECTED} && $Crm->{AFFECTED} =~ /^[0-9]$/);
          return {
            errno  => 104006,
            errstr => 'Step not found'
          };
        }
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'GET',
      path        => '/crm/step/:step_id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_progressbar_step_info({ ID => $path_params->{step_id} });
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'GET',
      path        => '/crm/steps/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ?
            $query_params->{$param} : '_SHOW';
        }

        $query_params->{COLS_NAME} = 1;
        $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25;
        $query_params->{PG} = $query_params->{PG} ? $query_params->{PG} : 0;
        $query_params->{DESC} = $query_params->{DESC} ? $query_params->{DESC} : '';
        $query_params->{SORT} = $query_params->{SORT} ? $query_params->{SORT} : 1;

        $Crm->crm_progressbar_step_list($query_params);
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'POST',
      path        => '/crm/workflow/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_workflow_add($query_params);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/crm/workflow/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Crm->crm_workflow_change({ %{$query_params}, ID => $path_params->{id} });
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/crm/attachment/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        if ($query_params->{FILE} && ref $query_params->{FILE} eq 'HASH') {
          return $Attachments->attachment_add($query_params->{FILE});
        }
        elsif ($query_params->{filename} && $query_params->{Contents}) {
          return $Attachments->attachment_add($query_params);
        }

        return $Attachments;
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/crm/attachment/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $result = $Attachments->attachment_del($path_params->{id});
        return $result->{errno} ? $result : { result => 'Successfully deleted' };
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/crm/attachment/:id/content/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $result = $Attachments->attachment_info($path_params->{id});

        # return $result if $result->{errno};
        return $result->{CONTENT};
      },
      content_type => 'Content-type: application/octet-stream',
      credentials => [ 'ADMINSID' ]
    },
    {
      method      => 'GET',
      path        => '/crm/sources/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ?
            $query_params->{$param} : '_SHOW';
        }

        $query_params->{COLS_NAME} = 1;
        $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25;
        $query_params->{PG} = $query_params->{PG} ? $query_params->{PG} : 0;
        $query_params->{DESC} = $query_params->{DESC} ? $query_params->{DESC} : '';
        $query_params->{SORT} = $query_params->{SORT} ? $query_params->{SORT} : 1;

        $Crm->leads_source_list($query_params);
      },
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
  ];
}

1;
