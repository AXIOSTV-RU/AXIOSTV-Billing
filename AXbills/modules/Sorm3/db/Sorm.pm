package Sorm3::db::Sorm;

use strict;
use warnings 'FATAL' => 'all';
use parent 'dbcore';
use Sorm3::Vendor;

our(
  $db,
  $admin,
  %conf
);

sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = {
    db 	  => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  $self->{sorm_pfx} = Sorm3::Vendor::table_prefix($CONF);

  return $self;
}

sub users_list {
    my $self = shift;
    my ($attr) = @_;
    my @WHERE_RULES = ();

    my $WHERE = $self->search_former($attr, [
	['LOGIN', 'STR', 'LOGIN' ]	
    ], 
    { 
      WHERE => 1,
      WHERE_RULES => \@WHERE_RULES
    });

    my $str = "SELECT ABONENT_ID,LOGIN FROM " . $self->{sorm_pfx} . "_ABONENT $WHERE";
    $self->query("SELECT ABONENT_ID,LOGIN FROM " . $self->{sorm_pfx} . "_ABONENT $WHERE", undef, $attr);

    return $self;
}

sub list_gateways {
    my $self = shift;
    my ($attr) = @_;
    
    my $WHERE = $self->search_former($attr, [
      ['ID', 'INT', 'id']
    ],
    { WHERE => 1 });

    $self->query("SELECT id, 
                  DESCRIPTION, 
                  INET_NTOA(IPV4) as IPV4,
		  INET6_NTOA(IPV6) as IPV6,
                  GATE_TYPE, 
                  BEGIN_TIME,
                  CITY,
                  STREET,
                  BUILDING,
                  BUILD_SECT,
                  APARTMENT,
		  DELETED
                from " . $self->{sorm_pfx} . "_GATEWAYS
                $WHERE", 
    undef, 
    $attr );

    my $list = $self->{list};

    return $list;
}

sub gateway_add {
    my $self = shift;
    my ($attr) = @_;

    $self->query_add($self->{sorm_pfx} . "_GATEWAYS", $attr);

    return $self;
}

sub gateway_change {
    my $self = shift;
    my ($attr) = @_;

    $self->changes({
      CHANGE_PARAM => 'ID',
      TABLE => $self->{sorm_pfx} . "_GATEWAYS",
      DATA => $attr,
    });

    return !$self->{errno} ? $self->{result} : $self->{errno};
}

sub gateway_del {
    my $self = shift;
    my ($attr) = @_;

    $self->query_del($self->{sorm_pfx} . "_GATEWAYS", {  ID => $attr->{ID} });

    return !$self->{errno} ? $self : $self->{errno};
}


sub list_phone_special {
    my $self = shift;
    my ($attr) = @_;
    
    my $WHERE = $self->search_former($attr, [
      ['ID', 'INT', 'id']
    ],
    { WHERE => 1 });

    $self->query("SELECT id, 
                  DESCRIPTION,
		  PHONE_NUMBER,
                  INET_NTOA(IPV4) as IPV4,
		  INET6_NTOA(IPV6) as IPV6,
                  BEGIN_TIME,
		  DELETED
                from " . $self->{sorm_pfx} . "_PHONE_SPECIAL
                $WHERE", 
    undef, 
    $attr );

    my $list = $self->{list};

    return $list;
}

sub phone_special_add {
    my $self = shift;
    my ($attr) = @_;

    $self->query_add($self->{sorm_pfx} . "_PHONE_SPECIAL", $attr);

    return $self;
}

sub phone_special_change {
    my $self = shift;
    my ($attr) = @_;

    $self->changes({
      CHANGE_PARAM => 'ID',
      TABLE => $self->{sorm_pfx} . "_PHONE_SPECIAL",
      DATA => $attr,
    });

    return !$self->{errno} ? $self->{result} : $self->{errno};
}

sub phone_special_del {
    my $self = shift;
    my ($attr) = @_;

    $self->query_del($self->{sorm_pfx} . "_PHONE_SPECIAL", { ID => $attr->{ID} });

    return !$self->{errno} ? $self : $self->{errno};
}

sub services_abon_user_list {
    my $self = shift;
    my ($attr) = @_;
    my $q = '';
    if($attr->{USED_ABON}) {
	$q = "(select uid as ABONENT_ID,tp_id as ID,
		 ('Abon') as MODULE from abon_user_list) 
		 union";
    }

    $self->query("$q (select DISTINCT uid as ABONENT_ID,
		 if(id > 0, $attr->{SERVICES}->{Internet}, '') as ID,
		 ('Internet') as MODULE
			from internet_main)", 
    undef, { %$attr } );

    my $list = $self->{list};
    return $list;
}

sub services_sorm_user_list {
    my $self = shift;
    my ($attr) = @_;
    
    $self->query("select ABONENT_ID,ID,MODULE,BEGIN_TIME from " . $self->{sorm_pfx} . "_ABONENT_SERVICES", undef, { %$attr });

    my $list = $self->{list};
    return $list;

}

sub get_supplementary_services {
    my $self = shift;
    my ($attr) = @_;

    my $WHERE = '';
    if($attr->{ID}) {
	$WHERE = 'WHERE ID=?';
	$attr->{Bind} = [ $attr->{ID} ];
    }

    $self->query("select ID,MODULE,MNEMONIC,BEGIN_TIME,DESCRIPTION,DELETED from " . $self->{sorm_pfx} . "_SUPPLEMENTARY_SERVICES $WHERE", undef, { %$attr });
    my $list = $self->{list};

    return $list;
}

sub get_abon_module_list {
    my $self = shift;
    my ($attr) = @_;

    $self->query("select id,name from abon_tariffs", undef, { %$attr });
    my $list = $self->{list};

    return $list;
}

sub add_supplementary_service {
    my $self = shift;
    my ($attr) = @_;
    
    $self->query_add($self->{sorm_pfx} . "_SUPPLEMENTARY_SERVICES", $attr);

    return $self;
}

sub change_supplementary_service {
    my $self = shift;
    my ($attr) = @_;

    $self->changes({
      CHANGE_PARAM => 'ID',
      TABLE => $self->{sorm_pfx} . "_SUPPLEMENTARY_SERVICES",
      DATA => $attr,
    });

    return $self;
}

sub del_supplementary_service {
    my $self = shift;                                               
    my ($attr) = @_;                                                
    if($attr->{ID}) {
	$self->query_del($self->{sorm_pfx} . "_SUPPLEMENTARY_SERVICES", {  ID => $attr->{ID} });
    }

    return $self;
}

sub get_ip_plan {
    my $self = shift;                                               
    my ($attr) = @_;
    
    my $WHERE = $self->search_former($attr, [
	['ID','INT', 'ID']
    ], 
    { WHERE => 1});

    $self->query("select id,
			 DESCRIPTION,
			 INET_NTOA(IPV4) as IPV4,
			 INET6_NTOA(IPV6) as IPV6,
			 IPV4_MASK,
			 IPV6_MASK,
			 BEGIN_TIME,
			 DELETED
		  from " . $self->{sorm_pfx} . "_IP_PLAN $WHERE", undef, { %$attr });

    my $list = $self->{list};
    
    return $list;
}

sub add_ip_plan {
    my $self = shift;
    my ($attr) = @_;
    
    $self->query_add($self->{sorm_pfx} . "_IP_PLAN", $attr);

    return $self;
}


sub change_ip_plan {
    my $self = shift;
    my ($attr) = @_;

    $self->changes({
	CHANGE_PARAM => 'ID',
	TABLE => $self->{sorm_pfx} . "_IP_PLAN",
	DATA =>  $attr
    });

    return $self;
}

sub ip_plan_del {
    my $self = shift;
    my ($attr) = @_;
    
    $self->query_del($self->{sorm_pfx} . "_IP_PLAN", { ID => $attr->{ID} });

    return $self;
}



1;
