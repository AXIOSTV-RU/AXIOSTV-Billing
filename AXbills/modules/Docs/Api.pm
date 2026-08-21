package Docs::Api;
=head NAME

  Docs::Api - Docs api functions

=head VERSION

  DATE: 20230703
  UPDATE: 20230703
  VERSION: 0.01

=cut

use strict;
use warnings FATAL => 'all';

use AXbills::Base qw(in_array);

use Docs::Constants qw(EDOCS_STATUS);
use Docs;

my Docs $Docs;

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
    html  => $html,
    debug => $debug
  };

  bless($self, $class);

  $self->{routes_list} = ();

  if ($type eq 'user') {
    $self->{routes_list} = $self->user_routes();
  }
  elsif ($type eq 'admin') {
    $self->{routes_list} = $self->admin_routes();
  }

  $Docs = Docs->new($self->{db}, $self->{admin}, $self->{conf});
  $Docs->{debug} = $self->{debug};

  return $self;
}

#**********************************************************
=head2 user_routes() - Returns available API paths

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
                $module_obj          # object of needed DB module (in this example - Users). used to run it's methods.
                                     # may be empty if name of module is not set.
               ) = @_;

            $module_obj->info(       # handler should return hashref or arrayref with needed data
              $path_params->{uid}
            );                       # in this example we call Users->info, and it's result are implicitly returned
          },

          module  => 'Users',        # name of DB module. it's object will be created and passed to handler as $module_obj. optional.

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
      method      => 'GET',
      path        => '/docs/edocs/branches/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $ESignService = $self->_init_esign_service();
        return $ESignService if ($ESignService->{errno});
        return {
          errno  => 1054005,
          errstr => 'Unknown operation'
        } if (!$ESignService->can('get_branches'));

        my $branches = $ESignService->get_branches();

        return $branches;
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/docs/edocs/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 1054006,
          errstr => 'No required field docType'
        } if (!$query_params->{DOC_TYPE});

        return {
          errno  => 1054007,
          errstr => 'Not valid field docType required. Allowed types is numbers: 2 - act and 4 - contractId',
        } if (!in_array($query_params->{DOC_TYPE}, [ 2, 4 ]));

        return {
          errno  => 1054008,
          errstr => 'No field branchId or orderId'
        } if (!$query_params->{BRANCH_ID} || !$query_params->{OFFER_ID});

        return {
          errno  => 1054009,
          errstr => 'No field uid or companyId'
        } if (!$query_params->{UID} && !$query_params->{COMPANY_ID});

        my $documents = $Docs->edocs_list({
          DOC_TYPE   => $query_params->{DOC_TYPE},
          DOC_ID     => $query_params->{DOC_ID},
          UID        => $query_params->{UID} || '_SHOW',
          COMPANY_ID => $query_params->{COMPANY_ID} || '_SHOW',
          STATUS     => '_SHOW',
          COLS_NAME  => 1,
        });

        return {
          result   => EDOCS_STATUS->{$documents->[0]->{status}} || 'OK',
          warning  => 1054010,
          document => $documents->[0],
          id       => $documents->[0]->{id},
        } if ($Docs->{TOTAL} && $Docs->{TOTAL} > 0);

        $Docs->edocs_add({ %$query_params, STATUS => 1, AID => $self->{admin}->{AID}, });

        return $Docs if $Docs->{errno};

        ::load_module('AXbills::Templates', { LOAD_PACKAGE => 1 }) if (!exists($INC{'AXbills/Templates.pm'}));
        ::load_module('Docs', $self->{html});

        my %info = (
          %{$query_params},
          DOC_ID        => $query_params->{DOC_ID},
          CERT          => '',
          PDF           => $self->{conf}->{DOCS_PDF_PRINT} ? 1 : 0,
          SAVE_DOCUMENT => 1
        );

        if ($query_params->{DOC_TYPE} == 4) {
          ::docs_contract(\%info);
        }
        elsif ($query_params->{DOC_TYPE} == 2) {
          require Docs::Acts;

          if ($query_params->{UID}) {
            require Users;
            my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
            $Users->info($query_params->{UID});
            $info{USER_INFO} = $Users->pi({ UID => $query_params->{UID} });
            require Customers;
            my $Customer = Customers->new($self->{db}, $self->{admin}, $self->{conf});
            $info{COMPANY} = $Customer->company_from_uid($query_params->{UID});
          }

          ::docs_acts_print(\%info);
        }

        return {
          result => 'DOCUMENT_SEND_USER_FOR_SIGN',
          id     => $Docs->{INSERT_ID},
        };
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/docs/edocs/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $ESignService = $self->_init_esign_service();
        return $ESignService if ($ESignService->{errno});
        return {
          errno  => 1054005,
          errstr => 'Unknown operation'
        } if (!$ESignService->can('get_branches'));

        my $branches = $ESignService->get_branches();

        my $documents = $Docs->edocs_list({
          %$query_params,
          STATUS    => $query_params->{STATUS} || '_SHOW',
          OFFER_ID  => $query_params->{OFFER_ID} || '_SHOW',
          BRANCH_ID => $query_params->{BRANCH_ID} || '_SHOW',
          COLS_NAME => 1,
        });

        foreach my $document (@{$documents}) {
          $document->{status_message} = EDOCS_STATUS->{$document->{status}} || 'OK';
          $document->{branch_info} = $branches->{$document->{branch_id} || ''} || '';
          $document->{offer_info} = $branches->{$document->{branch_id} || ''}->{offers}->{$document->{offer_id} || ''} || '';
        }

        return $documents;
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/docs/edocs/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $document = $Docs->edocs_list({
          ID         => $path_params->{id},
          DOC_ID     => '_SHOW',
          DOC_TYPE   => '_SHOW',
          UID        => '_SHOW',
          COMPANY_ID => '_SHOW',
          COLS_UPPER => 1
        });

        if (!$Docs->{TOTAL}) {
          return {
            errno  => 1054011,
            errstr => 'ERR_NOT_EXISTS'
          };
        }

        require Docs::Misc::Documents;
        Docs::Misc::Documents->import();
        my $Documents = Docs::Misc::Documents->new($self->{db}, $self->{admin}, $self->{conf}, { html => $self->{html} });

        $Documents->document_delete($document->[0]);
        $Docs->edocs_del($path_params->{id});

        if ($Docs->{AFFECTED}) {
          return {
            result => 'SUCCESSFULLY_DELETED',
            doc_id => $path_params->{id},
          };
        }
        else {
          return {
            errno  => 1054012,
            errstr => 'ERR_NOT_EXISTS'
          };
        }
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
  ]
}

#**********************************************************
=head2 user_routes() - Returns available API paths

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
                $module_obj          # object of needed DB module (in this example - Users). used to run it's methods.
                                     # may be empty if name of module is not set.
               ) = @_;

            $module_obj->info(       # handler should return hashref or arrayref with needed data
              $path_params->{uid}
            );                       # in this example we call Users->info, and it's result are implicitly returned
          },

          module  => 'Users',        # name of DB module. it's object will be created and passed to handler as $module_obj. optional.

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
sub user_routes {
  my $self = shift;

  return [
    {
      method      => 'POST',
      path        => '/user/docs/edocs/sign/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $ESignService = $self->_init_esign_service();
        return $ESignService if ($ESignService->{errno});
        return {
          errno  => 1054018,
          errstr => 'UNKNOWN_OPERATION'
        } if (!$ESignService->can('mk_sign'));

        my $document = $Docs->edocs_list({
          ID         => $path_params->{id},
          UID        => $path_params->{uid},
          COMPANY_ID => '_SHOW',
          DOC_ID     => '_SHOW',
          DOC_TYPE   => '_SHOW',
          OFFER_ID   => '_SHOW',
          BRANCH_ID  => '_SHOW',
          COLS_UPPER => 1
        });

        return {
          errno  => 1054019,
          errstr => 'UNKNOWN_DOCUMENT'
        } if (!$Docs->{TOTAL} || $Docs->{TOTAL} < 1);

        if ($document->[0]->{uid}) {
          return {
            errno  => 1054021,
            errstr => 'UNKNOWN_DOCUMENT',
          } if ($document->[0]->{uid} ne $path_params->{uid});
        }
        else {
          return {
            errno  => 1054022,
            errstr => 'UNKNOWN_DOCUMENT',
          };
        }

        my $sign_result = $ESignService->mk_sign($document->[0]);

        return $sign_result;
      },
      credentials => [
        'USER'
      ]
    },
  ],
}

#**********************************************************
=head2 document_add()

=cut
#**********************************************************
sub _init_esign_service {
  my $self = shift;

  require Docs::Init;
  Docs::Init->import('init_esign_service');

  my $ESignService = init_esign_service($self->{db}, $self->{admin}, $self->{conf}, {
    lang   => $self->{lang},
    html   => $self->{html},
    SILENT => 1
  });

  return {
    errno  => $ESignService->{errno} || 1054004,
    errstr => $ESignService->{errstr} || 'ESIGN_SERVICE_NOT_CONNECTED'
  } if (!%{$ESignService} || $ESignService->{errno});

  return $ESignService;
}

1;
