package Sorm3::Settings;

use strict;
use warnings 'FATAL' => 'all';
use parent 'main';
use Sorm3::db::Sorm;
use AXbills::Base qw(in_array);

use Log;
our $SormDB;
my $Log;
my %list_services = (
    'Internet' => 1,
);


sub new {
    my $class = shift;
    my ($db, $admin, $conf, $lang, $html) = @_;
    
    my $self = {
	db => $db,
	admin => $admin,
	conf  => $conf,
	lang => $lang,
	html => $html
    };

    bless($self, $class);

    $SormDB = Sorm3::db::Sorm->new($db, $admin, $conf);
    $Log = Log->new($db, $admin, $conf);
    return $self;
}


sub get_users_services {
    my $self = shift;

    my $use_abon = '';
    if(in_array('Abon', \@main::MODULES)) {
	$use_abon = 1;
    };
    my $list = '';
    $list = $SormDB->services_abon_user_list({
	    SERVICES  => \%list_services,
	    COLS_NAME => 1,
	    USE_ABON => $use_abon
    });

    my $Services = ();
    my $Sorm_services = ();

    if($list&&!$SormDB->{errno}) {
	foreach my $user (@$list) {
	    $Services->{ $user->{ABONENT_ID} } = {} if( !$Services->{ $user->{ABONENT_ID} } );

	    $user->{ID} += ($user->{MODULE} eq 'Abon') ? 20 : 0;
	    if($list_services{ $user->{MODULE} }) {
		$user->{ID} = $list_services{ $user->{MODULE} };
	    }
	    $Services->{ $user->{ABONENT_ID} }->{ $user->{ID} } = { 
		    MODULE => $user->{MODULE},
		    ID => $user->{ID},
		    ABONENT_ID => $user->{ABONENT_ID}
	    };
	}
    }

    $list = $SormDB->services_sorm_user_list({
	COLS_NAME => 1
    });

    if($list&&!$SormDB->{errno}) {
	foreach my $user (@$list) {
	    if($list_services{ $user->{MODULE} }) {
		$user->{ID} = $list_services{ $user->{MODULE} };
	    }

	    $Sorm_services->{ $user->{ABONENT_ID} } = {} if( !$Sorm_services->{ $user->{ABONENT_ID} } );

	    $Sorm_services->{ $user->{ABONENT_ID} }->{ $user->{ID} } = $user;
	}
    }

    return ($Services, $Sorm_services);
}

sub get_supplementary_services {
    my $self = shift;
    my ($attr) = @_;

    my $Services = $SormDB->get_supplementary_services({ COLS_NAME => 1 });
    if($Services&&!$SormDB->{errno}) {
	return $Services;
    }
    return 0;
}

sub sync_supplementary_services {
    my $self = shift;
    my ($attr) = @_;

    my $sorm_srv = $SormDB->get_supplementary_services({ COLS_NAME => 1 });
    my $sv = ();
    if($sorm_srv&&!$SormDB->{errno}) {
	foreach my $service (@$sorm_srv) {
	    $sv->{ $service->{ID} } = $service;
	}
    }
    
    my %srv = ();
    if(in_array('Abon', \@main::MODULES)) {
	my $dynamic_srv = $SormDB->get_abon_module_list({ COLS_NAME => 1 });
	if($dynamic_srv&&!$SormDB->{errno}) {
	    foreach my $s (@$dynamic_srv) {
		$s->{id} += 20;
		$srv{$s->{id}} = {
		    MODULE => 'Abon',
		    ID => $s->{id},
		    MNEMONIC => $s->{name},
		    DESCRIPTION => $s->{name},
		    TYPE => 'dynamic'
		};
	    }
	}
    }

    foreach my $service (keys %list_services) {
	$srv{ $list_services{$service} } = {
	    MODULE => $service,
	    ID => $list_services{$service},
	    MNEMONIC => (($self->{lang}{uc($service)}) ? $self->{lang}{uc($service)} : $service),
	    DESCRIPTION => (($self->{lang}{uc($service)}) ? $self->{lang}{uc($service)} : $service),
	    TYPE => 'static'
	};
    }

    if($sv) {
	my $changed = 'Помечен на удаление ';
	my $ch = 0;
	foreach my $sync (values %$sv) {
	    if($sync->{ID} && exists$srv{ $sync->{ID} }) {
		if($sync->{DELETED}) {
		    $SormDB->change_supplementary_service({ ID => $sync->{ID}, DELETED => 0 });
		}
		delete $srv{ $sync->{ID} };
	    }
	    elsif($sync->{ID}&&!exists $srv{ $sync->{ID} }) {
		$SormDB->change_supplementary_service({ ID => $sync->{ID}, DELETED => 1 });
		$changed .= "ID: $sync->{ID} MODULE: $sync->{MODULE} DESC: $sync->{MNEMONIC},";
		$ch = 1;
	    }
	} 
	if(!$SormDB->{errno}&&$attr->{WEBUI}) {	
	    print $self->{html}->message('info', $self->{lang}{SUCCESS}, ($ch ? $changed: ''));
	}
    }
    my @services = values %srv;

    foreach my $new_service (@services) {
	if($new_service->{MODULE} eq 'Internet') {
	    $new_service->{BEGIN_TIME} = '2008-01-01';
	}
	$SormDB->add_supplementary_service($new_service);
    }
    
}

sub del_supplementary_service {
    my $self = shift;
    my ($attr) = @_;

    my $services = $SormDB->get_supplementary_services({ COLS_NAME => 1, ID => $attr->{del} });
    if($services&&!$SormDB->{errno}) {
	$services = $services->[0];
	    $SormDB->del_supplementary_service({ ID => $attr->{del} });
	    if(!$SormDB->{errno}&&$attr->{WEBUI}) {
		print $self->{html}->message('danger', $self->{lang}{DEL}, "ID: $services->{ID} DESC: $services->{MNEMONIC}");
	    }
	return;
    }
}

sub del_supplementary_service_for_sc {
    my $self = shift;
    my ($attr) = @_;

    $SormDB->del_supplementary_service({ ID => $attr->{del} });
    return;
}

sub gateway_del_sc {
    my $self = shift;
    my ($attr) = @_;

    $SormDB->gateway_del({ ID => $attr->{ID} });
    return $self;
}

sub phone_special_del_sc {
    my $self = shift;
    my ($attr) = @_;

    $SormDB->phone_special_del({ ID => $attr->{ID} });
    return $self;
}

sub ip_plan_del_sc {
    my $self = shift;
    my ($attr) = @_;

    $SormDB->ip_plan_del({ ID => $attr->{ID} });
    return $self;

}

1
