package AXbills::Loader;
=head1 VERSION

Load AXbills Plugins

=cut


use strict;
use parent 'Exporter';
our (%EXPORT_TAGS);

our $VERSION = 2.00;

our @EXPORT = qw(
  load_plugin
);

our @EXPORT_OK = qw(
 load_plugin
);

#**********************************************************
=head2 load_plugin($plugin_name, $attr) - Load plugin module

  Argumnets:
    $plugin_name  - service modules name
    $attr
       HTML
       LANG
       SERVICE    - AXbills Module Obj
       SERVICE_ID
       SOFT_EXCEPTION
       RETURN_ERROR
       EXTRA_PARAMS

  Returns:
    Module object

=cut
#**********************************************************
sub load_plugin {
  my ($plugin_name, $attr) = @_;

  my $Plugin;
  my $lang = $attr->{LANG};
  my $html = $attr->{HTML};
  my $Service = $attr->{SERVICE} || {};
  $plugin_name //= $Service->{PLUGIN};

  if ($attr->{SERVICE_INFO}) {
    my $service_info = $attr->{SERVICE_INFO};
    $Service = $service_info->($attr->{SERVICE_ID});
  }

  return $Plugin if (!$plugin_name);
  #my $load_success = main::load_module($plugin_name, { LOAD_PACKAGE => 1 });

  my $load_success = 0;
  if ($plugin_name) {
    my $module_path = $plugin_name . '.pm';
    $module_path =~ s{::}{/}g;
    eval { require $module_path };
    $load_success = $@ ? 0 : 1;
  }

  if ($load_success) {
    $plugin_name->import();

    $Service->{DEBUG} = defined $attr->{DEBUG} ? $attr->{DEBUG} : $Service->{DEBUG};
    if ($plugin_name->can('new')) {
      $Plugin = $plugin_name->new($Service->{db}, $Service->{admin}, $Service->{conf}, {
        %{$Service},
        %{$attr->{EXTRA_PARAMS} || {}},
        HTML => $html,
        LANG => $lang
      });
    }
    else {
      if ($attr->{RETURN_ERROR}) {
        return {
          errno  => 119901,
          errstr => "Can't load '$plugin_name'. Purchase this module http://billing.axiostv.ru",
        };
      }
      else {
        if ($html) {
          $html->message('err', $lang->{ERROR}, "Can't load '$plugin_name'. Purchase this module http://billing.axiostv.ru");
        }
        return $Plugin;
      }
    }
  }
  else {
    if ($attr->{RETURN_ERROR}) {
      return {
        errno  => 119902,
        errstr => "Can't load '$plugin_name'. Purchase this module http://billing.axiostv.ru",
      };
    }
    else {
      print $@ if ($attr->{DEBUG});
      if ($html) {
        $html->message('err', $lang->{ERROR}, "Can't load '$plugin_name'. Purchase this module http://billing.axiostv.ru");
      }
      if (!$attr->{SOFT_EXCEPTION}) {
        # die "Can't load '$plugin_name'. Purchase this module http://billing.axiostv.ru";
      }
    }
  }

  return $Plugin;
}


1;