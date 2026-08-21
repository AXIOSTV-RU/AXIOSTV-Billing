#!/bin/perl -w
package Sorm::Mfisoft;
use strict;                                           
use warnings FATAL => 'all';

use strict;                                                                                                                                                                                                                         
use parent qw 'dbcore';                                                                                                                                                                                                  
use POSIX qw(strftime);
use AXbills::Misc qw(translate_list);
use AXbills::Base qw(in_array ip2int date_diff);
use Sorm3::Settings;
use Net::FTP;

our(
   $db,
   %conf
);

my $location_file = "$main::var_dir/sorm/Mfisoft";                                                                                                                                                                                   
my $file = strftime "%Y%m%d_%H%M", localtime;

my $global_begin = '2006-01-01 00:00:00';
my $date_ended = '2049-12-31 23:59:59';
my $current_date = POSIX::strftime('%Y-%m-%d', localtime);
my %files = (
    ABONENT            => "$location_file/ABONENT_$file.txt",
    ABONENT_IDEN       => "$location_file/ABONENT_IDENT_$file.txt",
    ABONENT_SERV       => "$location_file/ABONENT_SERVICE_$file.txt",
    ABONENT_ADDR       => "$location_file/ABONENT_ADDRESS_$file.txt",
    PAYMENTS           => "$location_file/PAYMENT_$file.txt",
    PAY_TYPE           => "$location_file/PAY_TYPE_$file.txt",
    COMMUTATORS        => "$location_file/COMMUTATORS_$file.txt",
    GATEWAYS           => "$location_file/GATEWAYS_$file.txt",
    DOC_TYPE	       => "$location_file/DOC_TYPE_$file.txt",	
    GATEWAYS_IP        => "$location_file/IP_GATEWAY_$file.txt",
    REGIONS	           => "$location_file/REGIONS_$file.txt",
    IP_PLAN	       	   => "$location_file/IP_PLAN_$file.txt",
    SUPPLEMENTARY      => "$location_file/SUPPLEMENTARY_SERVICE_$file.txt",
    PHONE_SPECIAL      => "$location_file/PHONE_SPECIAL_$file.txt"
);

our(
  $country, 
  $zone, 
  $region, 
  $region_id, 
  $city, 
  $street, 
  $build, 
  $apart, 
  $zip, 
  $sorm_ipn,
  $time_offset,
  $Payments,
  $server_ip,
  $login,
  $password,
  $isp_description,
  $Settings
);
my $debug = 0;

sub new {
  my $class = shift;
  my ($CONF, $db, $admin, $argv) = @_;
  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
    argv  => $argv,
  };

  bless($self, $class);

  $region_id = $self->{conf}->{MFISOFT_ISP_ID} || $self->{conf}->{SORM3_ISP_ID} || q{};
  $zip = $self->{conf}->{OFFICE_ZIP} || q{};
  $country = $self->{conf}->{MFISOFT_COUNTRY} || $self->{conf}->{SORM3_COUNTRY} || q{};
  $region = $self->{conf}->{MFISOFT_REGION} || $self->{conf}->{SORM3_REGION} || q{};
  $zone = $self->{conf}->{MFISOFT_ZONE} || $self->{conf}->{SORM3_ZONE} || q{};
  $city = $self->{conf}->{OFFICE_CITY} || q{};
  $street = $self->{conf}->{OFFICE_STREET} || q{};
  $build = $self->{conf}->{OFFICE_BUILD} || q{};
  $apart = $self->{conf}->{OFFICE_APART} || q{};
  $time_offset = $self->{conf}->{MFISOFT_TIME_OFFSET} || $self->{conf}->{SORM3_TIME_OFFSET} || q{};
  $debug = $self->{argv}->{DEBUG} if($self->{argv}->{DEBUG});
  $Payments = Finance->payments($self->{db}, $self->{admin}, $self->{conf});
  $server_ip = $self->{conf}->{MFISOFT_SERVER} || $self->{conf}->{SORM3_SERVER} || q{};
  $login = $self->{conf}->{MFISOFT_LOGIN} || $self->{conf}->{SORM3_LOGIN} || q{};
  $password = $self->{conf}->{MFISOFT_PASSWORD} || $self->{conf}->{SORM3_PASSWORD} || q{};
  $isp_description = $self->{conf}->{MFISOFT_ISP_DESCRIPTION} || $self->{conf}->{SORM3_ISP_DESCRIPTION} || q{};

  $Settings = Sorm3::Settings->new($db, $admin, $CONF);

  $self->init();

  return $self;
}

sub init() {
    my $self = shift;

    if($self->{argv}->{HELP}) {
	$self->help();
	return 1;
    }

    if($self->{argv}->{RELOAD}) {
	my @reload_tables = (
	    'MFISOFT_ABONENT',
	    'MFISOFT_PAYMENT',
	    'MFISOFT_ABONENT_SERVICES',
	    'MFISOFT_PAYMENT'
	);
	my $db = $self->{db}->{db};
	foreach my $q (@reload_tables) {
	    my $sth = $db->prepare(qq{
		truncate table $q
	    });
	    $sth->execute();
	}
	$self->{argv}->{FULL_PAY} = 1;

	$self->ABONENT_START();
	$self->sorm_payments() if(!$self->{argv}->{SKIP_PAYMENTS});
	$self->dictionaries();
	$self->send() if(!$self->{argv}->{SKIP_FTP});

	return 1;
    }


    if($self->{argv}->{START}) {
	mkdir($main::var_dir . '/sorm/');
	mkdir($main::var_dir . '/sorm/Mfisoft');
	mkdir($main::var_dir . '/sorm/archive');
	$self->ABONENT_START();
	$self->sorm_payments() if(!$self->{argv}->{SKIP_PAYMENTS});
	$self->dictionaries();
	$self->send() if(!$self->{argv}->{SKIP_FTP});

	return 1;
    } else {
	$self->ABONENT_START();
	$self->sorm_payments() if(!$self->{argv}->{SKIP_PAYMENTS});
	$self->dictionaries();
	$self->send() if(!$self->{argv}->{SKIP_FTP});
	return 1;
    }
}

sub ABONENT_START {
    my $self = shift;
    my $begin = time();
    my $db = $self->{db}->{db};

    my $NEW_CONTACT = '';
    my $NEW_ADDRESS = '';
    my $LEFT_JOIN   = '';
    my $OLD_CONTACT = '';
    my $OLD_ADDRESS = '';
    my $file_abonent = '';
    my $file_abonent_addr = '';
    my $file_abonent_serv = '';
    my $file_abonent_iden = '';

    $self->params_former();

my $head_abon = join(';', @{ $self->{arr}->{ABONENT} })."\n";
my $head_addr = join(';', @{ $self->{arr}->{ABONENT_ADDR} })."\n";
my $head_serv = join(';', @{ $self->{arr}->{ABONENT_SERV} })."\n";
my $head_iden = join(';', @{ $self->{arr}->{ABONENT_IDEN} })."\n";


    if($self->{conf}->{ADDRESS_REGISTER}) {
	$NEW_ADDRESS = qq{
	    d.city AS REG_CITY,
	    s.name AS REG_STREET,
	    b.number AS REG_BUILDING,
	    pi.address_flat as REG_APARTMENT,	    
	    rd.city AS CITY,
	    rs.name AS STREET,
	    rb.number AS BUILDING,
	    pi.address_flat as APARTMENT,
	};

	$LEFT_JOIN = qq{
	    LEFT JOIN builds b ON b.id=pi.location_id
	    LEFT JOIN streets s ON s.id=b.street_id                                                                                                                                                                                           
	    LEFT JOIN districts d ON d.id=s.district_id
	    LEFT JOIN builds rb ON rb.id=pi.location_id
	    LEFT JOIN streets rs ON rs.id=rb.street_id
	    LEFT JOIN districts rd ON rd.id=rs.district_id
	};
    } else {
	$OLD_ADDRESS = qq{
	    if(pi.reg_address != '', SUBSTRING_INDEX(pi.reg_address, ',', 1), pi.city) as REG_CITY,
	    if(pi.reg_address != '', SUBSTRING_INDEX(SUBSTRING_INDEX(pi.reg_address, ',', 2), ',', -1), pi.address_street) as REG_STREET,
	    if(pi.reg_address != '', SUBSTRING_INDEX(SUBSTRING_INDEX(pi.reg_address, ',', 3), ',', -1), pi.address_build) as REG_BUILDING,
	    if(pi.reg_address != '', SUBSTRING_INDEX(SUBSTRING_INDEX(pi.reg_address, ',', 4), ',', -1), pi.address_flat) as REG_APARTMENT,
	    pi.city as CITY,
	    pi.address_street as STREET,
	    pi.address_build as BUILDING,
	    pi.address_flat as APARTMENT,
	};
    }

    my $query = qq{
	SELECT 
	    u.uid as ABONENT_ID,
	    u.uid as ACCOUNT,
	    if(pi.contract_date = '0000-00-00',concat_ws(' ', '1970-01-01', '00:00:00'),pi.contract_date) as CONTRACT_DATE,
	    IF(pi.contract_id = '', u.uid, pi.contract_id) as CONTRACT,
	    if(pi.contract_date = '0000-00-00',concat_ws(' ', '1970-01-01', '00:00:00'),pi.contract_date) as ACTUAL_FROM,
	    ("$date_ended") as ACTUAL_TO,
	    if(u.is_company = true, 43, 42) as ABONENT_TYPE,
	    if(u.is_company = true, '', 1) as NAME_INFO_TYPE,
	    CONCAT_WS(' ', pi.fio, pi.fio2, pi.fio3) as UNSTRUCT_NAME,
	    if(pi.birth_date = '0000-00-00', '', pi.birth_date) as BIRTH_DATE,
	    1 as IDENT_CARD_TYPE_ID,
	    1 as IDENT_CARD_TYPE,
	    '' as IDENT_CARD_NUMBER,
	    '' AS IDENT_CARD_SERIAL,
	    '' AS IDENT_CARD_DESCRIPTION,
	    pi.pasport_num as PASPORT_NUM,
	    pi.pasport_date as PASPORT_DATE,
	    pi.pasport_grant as PASPORT_GRANT,
	    (SELECT value from users_contacts WHERE type_id=2 AND users_contacts.uid=u.uid LIMIT 1) as PHONE,
	    ("0") as ADDRESS_TYPE_ID,
	    ("0") as ADDRESS_TYPE,
	    u.id as LOGIN,
	    tp.name as PARAMETER,
	    if(i.id > 0, i.id, '0') as TP_ID,
	    CONCAT_WS(' ', pi.fio, pi.fio2, pi.fio3) as CONTACT,
	    '' as PHONE_FAX,
	    $NEW_CONTACT
	    $OLD_CONTACT
	    $NEW_ADDRESS
	    $OLD_ADDRESS
	    CASE
		WHEN i.disable > 0
		    THEN '1'
		WHEN u.disable = 1
		    THEN '1'
		WHEN u.deleted > 0
			THEN '1'
	    ELSE '0'
	    END as STATUS,
	    CURRENT_TIMESTAMP as CURRENT_TIMESTAMP_3,
	    if(u.is_company = true, pi.bank_name, '') as BANK,
	    if(u.is_company = true, pi.bank_account, '') as BANK_ACCOUNT,
	    if(u.is_company = true, pi.company_name, '') as FULL_NAME,
	    if(u.is_company = true, pi.inn, '') as INN,
	    u.is_company as IS_COMPANY,
	    ('4') as NETWORK_TYPE,
	    ('5') as IDENT_TYPE,
	    ("$country") as COUNTRY,
	    ("$region") as REGION,
	    ("$region_id") as REGION_ID,
	    if(INET_NTOA(i.ip) != '0.0.0.0', '0', '') as IP_TYPE,
	    if(INET_NTOA(i.ip) != '0.0.0.0', '0', '') as IP_MASK_TYPE,
	    i.ip as IPV4,
	    i.netmask as IPV4_MASK,
	    i.cid as MAC
	    from users u
	    left join internet_main i on(i.uid=u.uid)
	    left join users_pi pi on(pi.uid=u.uid)
	    left join tarif_plans tp on(tp.tp_id=i.tp_id)
	    $LEFT_JOIN
		ORDER BY u.uid ASC
    };

    my $prepare = $db->prepare($query);
    $prepare->execute() or DBI->errstr;

	my $sorm_query = qq{
		SELECT ABONENT_ID,
			CONTRACT_DATE,
			CONTRACT,
			ACCOUNT,
			ABONENT_TYPE,
			UNSTRUCT_NAME,
			BIRTH_DATE,
			IDENT_CARD_TYPE_ID,
			if(ABONENT_TYPE=42,1,'') as IDENT_CARD_TYPE,
			IDENT_CARD_SERIAL,
			IDENT_CARD_DESCRIPTION,
			IDENT_CARD_UNSTRUCT,
			if(ABONENT_TYPE=42, 1, '') as NAME_INFO_TYPE,
			IS_COMPANY,
			BANK,
			BANK_ACCOUNT,
			FULL_NAME,
			INN,
			CONTACT,
			PHONE_FAX,
			STATUS,
			("4") as NETWORK_TYPE,
			("5") as IDENT_TYPE,
			ACTUAL_FROM,
			ACTUAL_TO,
			ATTACH,
			DETACH,
			ZIP,
			COUNTRY,
			REGION,
			ZONE,
			CITY,
			STREET,
			BUILDING,
			APARTMENT,
			REG_ZONE,
			REG_CITY,
			REG_STREET,
			REG_BUILDING,
			REG_APARTMENT,
			ABONENT_ADDR_BEGIN_TIME,
			ABONENT_ADDR_END_TIME,
			PHONE,
			if(MAC != '', EQUIPMENT_TYPE, '') as EQUIPMENT_TYPE,
			MAC,
			LOGIN,
			E_MAIL,
			if(INET_NTOA(IPV4) != '0.0.0.0', '0', '') as IP_TYPE,
			if(INET_NTOA(IPV4) != '0.0.0.0', '0', '') as IP_MASK_TYPE,
			IPV4,
			IPV4_MASK,
			ABONENT_IDENT_BEGIN_TIME,
			ABONENT_IDENT_END_TIME,
			TP_ID,
			ABONENT_SRV_BEGIN_TIME,
			ABONENT_SRV_END_TIME,
			PARAMETER,
			CURRENT_TIMESTAMP as CURRENT_TIMESTAMP_3,
			('0') as ADDRESS_TYPE_ID,
			('0') as ADDRESS_TYPE,
			("$region_id") as REGION_ID,
			ABONENT_ID as INTERNAL_ID1,
			ABONENT_ID as INTERNAL_ID2
			FROM MFISOFT_ABONENT
			ORDER BY ABONENT_ID ASC
	};

	my $sorm = $db->prepare($sorm_query);
	$sorm->execute() or die DBI->errstr;

    
	my %abonent = ();
	my ($users_srv, $sorm_srv) = $Settings->get_users_services();
	while( my $row = $prepare->fetchrow_hashref()) {
		$row->{INTERNAL_ID1} = $row->{INTERNAL_ID2} = $row->{ID} = $row->{ABONENT_ID};
		$row->{BEGIN_TIME} = $row->{ATTACH} = $row->{ACTUAL_FROM};
		$row->{END_TIME} = $row->{DETACH} = $row->{ACTUAL_TO};

		unless($self->{CURRENT_TIMESTAMP_3}) { $self->{CURRENT_TIMESTAMP_3} = $row->{CURRENT_TIMESTAMP_3}  }; 

		if($row->{MAC}&&$row->{MAC}=~ /any/ig||!$row->{MAC}) {
		    $row->{EQUIPMENT_TYPE} = '';
		    $row->{MAC} = '';
		} else {
		    $row->{EQUIPMENT_TYPE} = '0';
		}

		if(!$row->{TP_ID}) {
			$row->{TP_ID} = 0;
			$row->{IPV4}  = 0;
			$row->{IPV4_MASK} = '4294967295';
		}

		map {  
			$row->{$_} = $self->validate($row->{$_}); 
		} keys %$row;

		if($row->{PASPORT_NUM}&&$row->{PASPORT_DATE}&&$row->{PASPORT_GRANT}) {
		    $row->{IDENT_CARD_UNSTRUCT} = ($row->{PASPORT_DATE} !~ /0000-00-00/) ? "$row->{PASPORT_NUM} $row->{PASPORT_DATE} $row->{PASPORT_GRANT}" : "$row->{PASPORT_NUM} $row->{PASPORT_GRANT}";
		} else {
		    $row->{IDENT_CARD_UNSTRUCT} = 'нет данных';
		}

		if($abonent{ $row->{ABONENT_ID} }) {
			next;
		}
		$abonent{ $row->{ABONENT_ID} } = $row;
		if( $users_srv->{ $row->{ABONENT_ID} } ) {
		    $abonent{ $row->{ABONENT_ID} }->{SERVICES} = $users_srv->{ $row->{ABONENT_ID} };
		}
	}

	
	my @sorm_data = ();
	while(my $s = $sorm->fetchrow_hashref()) {
		if( $sorm_srv->{ $s->{ABONENT_ID} } ) {
		    $s->{SERVICES} = $sorm_srv->{ $s->{ABONENT_ID} };
		}
		push @sorm_data, { ABONENT_ID => $s->{ABONENT_ID}, DATA => $s };
	}


	foreach my $s (@sorm_data) {
	    if($s->{ABONENT_ID} && exists $abonent{ $s->{ABONENT_ID} }) {
		if( $abonent{ $s->{ABONENT_ID} }->{ABONENT_ID} eq $s->{DATA}->{ABONENT_ID} ) {
			unless($file_abonent) { open(ABONENT, ">$files{ABONENT}"); print ABONENT $head_abon; $file_abonent = 1 };
			$self->check_abonent( $abonent{ $s->{ABONENT_ID} }, $s->{DATA} );

			unless($file_abonent_addr) { open(ABONENT_ADDR, ">$files{ABONENT_ADDR}"); print ABONENT_ADDR $head_addr; $file_abonent_addr = 1 };
			$self->check_abonent_addr( $abonent{ $s->{ABONENT_ID} }, $s->{DATA});

			unless($file_abonent_iden) { open(ABONENT_IDEN, ">$files{ABONENT_IDEN}"); print ABONENT_IDEN $head_iden; $file_abonent_iden = 1 };
			$self->check_abonent_iden( $abonent{ $s->{ABONENT_ID} }, $s->{DATA} );			
		
			unless($file_abonent_serv) { open(ABONENT_SERV, ">$files{ABONENT_SERV}"); print ABONENT_SERV $head_serv; $file_abonent_serv = 1 };
			$self->check_abonent_serv( $abonent{ $s->{ABONENT_ID} }, $s->{DATA} );

		    delete $abonent{ $s->{ABONENT_ID} };
		}
	    }
	    elsif($s->{ABONENT_ID} && !exists $abonent{ $s->{ABONENT_ID} }) {
		if($s->{DATA}->{ACTUAL_TO} =~ /0000-00-00/) {
			my $sth = $db->prepare(qq{
			    UPDATE MFISOFT_ABONENT SET
				ACTUAL_TO = '$s->{DATA}->{CURRENT_TIMESTAMP_3}',
				DETACH = '$s->{DATA}->{CURRENT_TIMESTAMP_3}',
				ABONENT_ADDR_END_TIME = '$s->{DATA}->{CURRENT_TIMESTAMP_3}',
				ABONENT_SRV_END_TIME = '$s->{DATA}->{CURRENT_TIMESTAMP_3}',
				ABONENT_IDENT_END_TIME = '$s->{DATA}->{CURRENT_TIMESTAMP_3}',
				IPV4 = '0'
				WHERE ABONENT_ID = '$s->{DATA}->{ABONENT_ID}'
			});
			$sth->execute() or die DBI->errstr;

			$sth = $db->prepare(qq{
			    DELETE FROM MFISOFT_ABONENT_SERVICES WHERE ABONENT_ID='$s->{DATA}->{ABONENT_ID}';
			});

			$s->{DATA}->{ACTUAL_TO} = $s->{DATA}->{END_TIME} = $s->{DATA}->{DETACH} = $s->{DATA}->{CURRENT_TIMESTAMP_3}; 
		} 
		$s->{DATA}->{ID} = $s->{DATA}->{ABONENT_ID};
		$s->{DATA}->{END_TIME} = $s->{DATA}->{DETACH} = $s->{DATA}->{ACTUAL_TO}; 
		
		#ABONENT
		unless($file_abonent) { open(ABONENT, ">$files{ABONENT}"); print ABONENT $head_abon; $file_abonent = 1 };
		print ABONENT $self->mapper($s->{DATA}, 'ABONENT');
		    
		#ADDR
		$s->{DATA}->{BEGIN_TIME} = $s->{DATA}->{ABONENT_ADDR_BEGIN_TIME};
		unless($file_abonent_addr) { open(ABONENT_ADDR, ">$files{ABONENT_ADDR}"); print ABONENT_ADDR $head_addr; $file_abonent_addr = 1 };

		$self->reverse_address($s->{DATA});
		print ABONENT_ADDR $self->mapper($s->{DATA}, 'ABONENT_ADDR');

		#IDENT
		$s->{DATA}->{BEGIN_TIME} = $s->{DATA}->{ABONENT_IDENT_BEGIN_TIME};
		unless($file_abonent_iden) { open(ABONENT_IDEN, ">$files{ABONENT_IDEN}"); print ABONENT_IDEN $head_iden; $file_abonent_iden = 1 };
		print ABONENT_IDEN $self->mapper($s->{DATA}, 'ABONENT_IDEN');
		    
		#IF > 3 YEAR --- DELETE ABONENT
		my($end, undef) = split(/ /, $s->{DATA}->{ACTUAL_TO});

    		if((date_diff($end, $current_date) > 1100) && $self->{conf}->{MFISOFT_UPLOAD_USER_3_YEAR}) {
		        print date_diff($current_date, $end);
			my $sth = $db->prepare(qq{ DELETE FROM MFISOFT_ABONENT WHERE ABONENT_ID = '$s->{DATA}->{ABONENT_ID}' });
			$sth->execute() or die DBI->errstr;
		}
		elsif(!$self->{conf}->{MFISOFT_UPLOAD_USER_3_YEAR}) {
		    my $sth = $db->prepare(qq{ DELETE FROM MFISOFT_ABONENT WHERE ABONENT_ID = '$s->{DATA}->{ABONENT_ID}' });
	    	    $sth->execute() or die DBI->errstr;
		}
	    }
	}

	my @new_abonent = values %abonent;

	my $add_query = join(',', @{ $self->{query_arr}->{NEW_ABONENT_ADD} });
	foreach my $new_abonent (@new_abonent) {
		if($new_abonent) {
		    my $key_arr = '';
		    my @val_arr = ();
		    $new_abonent->{ATTACH} = $new_abonent->{ABONENT_ADDR_BEGIN_TIME} = $new_abonent->{ABONENT_IDENT_BEGIN_TIME} = $new_abonent->{ACTUAL_FROM};
		    map { $key_arr .= '?,'; push @val_arr, $new_abonent->{$_} } @{ $self->{query_arr}->{NEW_ABONENT_ADD} };
		    $key_arr =~ s/,$//;
		    my $query = qq{
			INSERT INTO MFISOFT_ABONENT
			    ($add_query) VALUES($key_arr);
			};
		    my $sth = $db->prepare($query);
		    $sth->execute(@val_arr) or die DBI->errstr;
		    
		    if($new_abonent->{SERVICES}) {
		
			my $query_serv = qq{
			    INSERT INTO MFISOFT_ABONENT_SERVICES(ABONENT_ID,ID,MODULE,BEGIN_TIME) VALUES(?,?,?,?)
			};
			$sth = $db->prepare($query_serv);
			unless($file_abonent_serv) { open(ABONENT_SERV, ">$files{ABONENT_SERV}"); print ABONENT_SERV $head_serv; $file_abonent_serv = 1 };		
		
			foreach my $service (values %{ $new_abonent->{SERVICES} }) {
			    $sth->execute($new_abonent->{ABONENT_ID}, $service->{ID}, $service->{MODULE}, $new_abonent->{ACTUAL_FROM});
			    $service->{BEGIN_TIME} = $new_abonent->{ACTUAL_FROM};
			    $service->{END_TIME} = $date_ended;
			    $service->{REGION_ID} = $region_id;
			    $service->{INTERNAL_ID1} = $service->{INTERNAL_ID2}	= $service->{ABONENT_ID};
    			    print ABONENT_SERV $self->mapper($service, 'ABONENT_SERV');
		
			}
		    }

		    unless($file_abonent) { open(ABONENT, ">$files{ABONENT}"); print ABONENT $head_abon; $file_abonent = 1 };
		    print ABONENT $self->mapper($new_abonent, 'ABONENT');
			
		    unless($file_abonent_addr) { open(ABONENT_ADDR, ">$files{ABONENT_ADDR}"); print ABONENT_ADDR $head_addr; $file_abonent_addr = 1 };
		    print ABONENT_ADDR $self->mapper($new_abonent, 'ABONENT_ADDR');

		    $self->reverse_address($new_abonent);
		    print ABONENT_ADDR $self->mapper($new_abonent, 'ABONENT_ADDR');

		    unless($file_abonent_iden) { open(ABONENT_IDEN, ">$files{ABONENT_IDEN}"); print ABONENT_IDEN $head_iden; $file_abonent_iden = 1 };
		    print ABONENT_IDEN $self->mapper($new_abonent, 'ABONENT_IDEN');
		}
	}
	if ($file_abonent)      { close(ABONENT)      or die; }
	if ($file_abonent_addr) { close(ABONENT_ADDR) or die; }
	if ($file_abonent_iden) { close(ABONENT_IDEN) or die; }
	if ($file_abonent_serv) { close(ABONENT_SERV) or die; }
}


sub check_abonent {
	my $self = shift;
	my ($a, $s) = @_;
	my $db = $self->{db}->{db};

  if (defined($a->{BANK}) && defined($s->{BANK}) && $a->{BANK} ne $s->{BANK} ||
	defined($a->{UNSTRUCT_NAME}) && defined($s->{UNSTRUCT_NAME}) && $a->{UNSTRUCT_NAME} ne $s->{UNSTRUCT_NAME} ||
	defined($a->{CONTRACT_DATE}) && defined($s->{CONTRACT_DATE}) && $a->{CONTRACT_DATE} ne $s->{CONTRACT_DATE} ||
	defined($a->{BANK_ACCOUNT}) && defined($s->{BANK_ACCOUNT}) && $a->{BANK_ACCOUNT} ne $s->{BANK_ACCOUNT} ||
	defined($a->{IDENT_CARD_DESCRIPTION}) && defined($s->{IDENT_CARD_DESCRIPTION}) && $a->{IDENT_CARD_DESCRIPTION} ne $s->{IDENT_CARD_DESCRIPTION} ||
	defined($a->{IDENT_CARD_UNSTRUCT}) && defined($s->{IDENT_CARD_UNSTRUCT}) && $a->{IDENT_CARD_UNSTRUCT} ne $s->{IDENT_CARD_UNSTRUCT} ||
	defined($a->{STATUS}) && defined($s->{STATUS}) && $a->{STATUS} ne $s->{STATUS} ||
	defined($a->{IDENT_CARD_SERIAL}) && defined($s->{IDENT_CARD_SERIAL}) && $a->{IDENT_CARD_SERIAL} ne $s->{IDENT_CARD_SERIAL} ||
	defined($a->{BIRTH_DATE}) && defined($s->{BIRTH_DATE}) && $a->{BIRTH_DATE} ne $s->{BIRTH_DATE} ||
	defined($a->{INN}) && defined($s->{INN}) && $a->{INN} ne $s->{INN} ||
	defined($a->{IS_COMPANY}) && defined($s->{IS_COMPANY}) && $a->{IS_COMPANY} ne $s->{IS_COMPANY} ||
	defined($a->{CONTACT}) && defined($s->{CONTACT}) && $a->{CONTACT} ne $s->{CONTACT} ||
	defined($a->{FULL_NAME}) && defined($s->{FULL_NAME}) && $a->{FULL_NAME} ne $s->{FULL_NAME} ||
	defined($a->{ABONENT_TYPE}) && defined($s->{ABONENT_TYPE}) && $a->{ABONENT_TYPE} ne $s->{ABONENT_TYPE} ||
	defined($a->{CONTRACT}) && defined($s->{CONTRACT}) && $a->{CONTRACT} ne $s->{CONTRACT} ||
	defined($a->{PHONE_FAX}) && defined($s->{PHONE_FAX}) && $a->{PHONE_FAX} ne $s->{PHONE_FAX}
	) {
		my $sth = $db->prepare(qq{
			UPDATE MFISOFT_ABONENT SET
				BANK = '$a->{BANK}',
				UNSTRUCT_NAME = '$a->{UNSTRUCT_NAME}',
				CONTRACT_DATE = '$a->{CONTRACT_DATE}',
				BANK_ACCOUNT  = '$a->{BANK_ACCOUNT}',
				IDENT_CARD_DESCRIPTION = '$a->{IDENT_CARD_DESCRIPTION}',
				IDENT_CARD_UNSTRUCT = '$a->{IDENT_CARD_UNSTRUCT}',
				STATUS = '$a->{STATUS}',
				IDENT_CARD_SERIAL = '$a->{IDENT_CARD_SERIAL}',
				BIRTH_DATE = '$a->{BIRTH_DATE}',
				INN = '$a->{INN}',
				IS_COMPANY = '$a->{IS_COMPANY}',
				CONTACT = '$a->{CONTACT}',
				FULL_NAME = '$a->{FULL_NAME}',
				ABONENT_TYPE = '$a->{ABONENT_TYPE}',
				CONTRACT = '$a->{CONTRACT}',
				PHONE_FAX = '$a->{PHONE_FAX}'
				WHERE ABONENT_ID = '$s->{ABONENT_ID}'
		});
		$sth->execute() or die DBI->errstr;
	} 
	print ABONENT $self->mapper($a, 'ABONENT');
}


sub check_abonent_addr {
	my $self = shift;
	my ($a, $s, $attr) = @_;
	my $db = $self->{db}->{db};

	if (defined($a->{CITY}) && defined($s->{CITY}) && $a->{CITY} ne $s->{CITY} ||
    	defined($a->{STREET}) && defined($s->{STREET}) && $a->{STREET} ne $s->{STREET} ||
        defined($a->{BUILDING}) && defined($s->{BUILDING}) && $a->{BUILDING} ne $s->{BUILDING} ||  
        defined($a->{APARTMENT}) && defined($s->{APARTMENT}) && $a->{APARTMENT} ne $s->{APARTMENT} ||
	defined($a->{REG_CITY}) && defined($s->{REG_CITY}) && $a->{REG_CITY} ne $s->{REG_CITY} ||
    	defined($a->{REG_STREET}) && defined($s->{REG_STREET}) && $a->{REG_STREET} ne $s->{REG_STREET} ||
        defined($a->{REG_BUILDING}) && defined($s->{REG_BUILDING}) && $a->{REG_BUILDING} ne $s->{REG_BUILDING} ||  
        defined($a->{REG_APARTMENT}) && defined($s->{REG_APARTMENT}) && $a->{REG_APARTMENT} ne $s->{REG_APARTMENT}
	) {

	    my $sth = $db->prepare(qq{
		UPDATE MFISOFT_ABONENT SET 
			CITY = '$a->{CITY}',
			STREET = '$a->{STREET}',
			BUILDING = '$a->{BUILDING}',
			APARTMENT = '$a->{APARTMENT}',
			REG_CITY = '$a->{REG_CITY}',
			REG_STREET = '$a->{REG_STREET}',
			REG_BUILDING = '$a->{REG_BUILDING}',
			REG_APARTMENT = '$a->{REG_APARTMENT}',
			ABONENT_ADDR_BEGIN_TIME = '$s->{CURRENT_TIMESTAMP_3}'
			WHERE ABONENT_ID = '$s->{ABONENT_ID}'
	    });
	    $sth->execute or die DBI->errstr;

	    $s->{END_TIME} = $s->{CURRENT_TIMESTAMP_3};
	    $s->{BEGIN_TIME} = $s->{ABONENT_ADDR_BEGIN_TIME};
	    $a->{BEGIN_TIME} = $s->{CURRENT_TIMESTAMP_3};
	    print ABONENT_ADDR $self->mapper($s, 'ABONENT_ADDR');
	    print ABONENT_ADDR $self->mapper($a, 'ABONENT_ADDR');

	    #REG_ADDRESS
	    $self->reverse_address($s);
	    $self->reverse_address($a);
	    print ABONENT_ADDR $self->mapper($s, 'ABONENT_ADDR');
	    print ABONENT_ADDR $self->mapper($a, 'ABONENT_ADDR');
	} else {
		$a->{BEGIN_TIME} = ($s->{ABONENT_ADDR_BEGIN_TIME} !~ /0000-00-00/) ? $s->{ABONENT_ADDR_BEGIN_TIME} : $a->{ACTUAL_FROM};
		print ABONENT_ADDR $self->mapper($a, 'ABONENT_ADDR');
		
		#REG_ADDRESS
		$a->{ADDRESS_TYPE_ID} = 3;
		$self->reverse_address($a);
		print ABONENT_ADDR $self->mapper($a, 'ABONENT_ADDR');
	}
	
}

sub check_abonent_serv {
	my $self = shift;
	my ($a, $s) = @_;
	my $db = $self->{db}->{db};
	

	if($s->{SERVICES}&& exists $a->{SERVICES}) {
	    foreach my $sorm_service (values %{ $s->{SERVICES} }) {
		if($sorm_service->{ID} && exists $a->{SERVICES}->{ $sorm_service->{ID} }) {
		    $sorm_service->{END_TIME} = $date_ended;
		    $sorm_service->{REGION_ID} = $region_id;
		    $sorm_service->{INTERNAL_ID1} = $sorm_service->{INTERNAL_ID2} = $sorm_service->{ABONENT_ID};

		    print ABONENT_SERV $self->mapper($sorm_service, 'ABONENT_SERV');
		    delete $a->{SERVICES}->{ $sorm_service->{ID} };
		}
		elsif($sorm_service->{ID} && !exists $a->{SERVICES}->{ $sorm_service->{ID} }) {
		    $sorm_service->{END_TIME} = $s->{CURRENT_TIMESTAMP_3};
		    $sorm_service->{REGION_ID} = $region_id;
		    $sorm_service->{INTERNAL_ID1} = $sorm_service->{INTERNAL_ID2} = $sorm_service->{ABONENT_ID};

		    print ABONENT_SERV $self->mapper($sorm_service, 'ABONENT_SERV');
		    my $sth = $db->prepare(qq{ DELETE FROM MFISOFT_ABONENT_SERVICES WHERE ID='$sorm_service->{ID}' AND ABONENT_ID='$sorm_service->{ABONENT_ID}' });
		    $sth->execute() or die DBI->errstr;
		}
	    }
	}

	my $query_serv = qq{
	    INSERT INTO MFISOFT_ABONENT_SERVICES(ABONENT_ID,ID,MODULE,BEGIN_TIME) VALUES(?,?,?,?)
	};
	my $sth = $db->prepare($query_serv);
	foreach my $new_service (values %{ $a->{SERVICES} }) {
	    print "$new_service->{ID}\n";
	    $sth->execute($new_service->{ABONENT_ID}, $new_service->{ID}, $new_service->{MODULE}, $a->{CURRENT_TIMESTAMP_3});
	    $new_service->{END_TIME} = $date_ended;
	    $new_service->{BEGIN_TIME} = $a->{CURRENT_TIMESTAMP_3};
	    $new_service->{REGION_ID} = $region_id;
	    $new_service->{INTERNAL_ID1} = $new_service->{INTERNAL_ID2} = $new_service->{ABONENT_ID};

	    print ABONENT_SERV $self->mapper($new_service, 'ABONENT_SERV');
	}
}

sub check_abonent_iden {
	my $self = shift;
	my ($a, $s) = @_;
	my $db = $self->{db}->{db};

	if(
	  defined($a->{IPV4_MASK}) && defined($s->{IPV4_MASK}) && $a->{IPV4_MASK} ne $s->{IPV4_MASK} ||
	  defined($a->{IPV4}) && defined($s->{IPV4}) && $a->{IPV4} ne $s->{IPV4} ||
	  defined($a->{LOGIN}) && defined($s->{LOGIN}) && $a->{LOGIN} ne $s->{LOGIN} ||
	  defined($a->{PHONE}) && defined($s->{PHONE}) && $a->{PHONE} ne $s->{PHONE}
	) {
		$s->{END_TIME}   = $s->{CURRENT_TIMESTAMP_3};
		$s->{BEGIN_TIME} = $s->{ABONENT_IDENT_BEGIN_TIME};
		$a->{BEGIN_TIME} = $s->{CURRENT_TIMESTAMP_3};
		print ABONENT_IDEN $self->mapper($s, 'ABONENT_IDEN');
		print ABONENT_IDEN $self->mapper($a, 'ABONENT_IDEN');

		my $sth = $db->prepare(qq{
			UPDATE MFISOFT_ABONENT SET 
				IPV4 = '$a->{IPV4}',
				IPV4_MASK = '$a->{IPV4_MASK}',
				LOGIN = '$a->{LOGIN}',
				MAC = '$a->{MAC}',
				PHONE = '$a->{PHONE}',
				ABONENT_IDENT_BEGIN_TIME = '$s->{CURRENT_TIMESTAMP_3}'
				WHERE ABONENT_ID = '$s->{ABONENT_ID}'
		});
		$sth->execute or die DBI->errstr;
	} else {
		$a->{BEGIN_TIME} = ($s->{ABONENT_IDENT_BEGIN_TIME} !~ /0000-00-00/) ? $s->{ABONENT_IDENT_BEGIN_TIME} : $a->{ACTUAL_FROM};
		print ABONENT_IDEN $self->mapper($a, 'ABONENT_IDEN');
	}
}

sub dictionaries {
    my $self = shift;
    my ($attr) = @_;

    $self->doc_type();
    $self->regions();    
    $self->gateway();
    $self->ipplan_report();
    $self->pay_types();
    $self->supplementary_service();
    $self->commutators();
    $self->phone_special();
}

sub commutators {
    my $self = shift;
    my $db = $self->{db}->{db};

    my $q = '';
    my $LEFT_JOIN = '';
    if($self->{conf}->{ADDRESS_REGISTER}) {
	$q = qq{ d.zip AS ZIP, 
		 d.city AS CITY, 
		 s.name AS STREET, 
		 b.number AS BUILDING,
	};
	$LEFT_JOIN = qq{
	    LEFT JOIN builds b ON b.id=n.location_id
	    LEFT JOIN streets s ON s.id=b.street_id                                                                                 
	    LEFT JOIN districts d ON d.id=s.district_id 
	};
    } else {
       $q = qq{
	    n.city as CITY,
	    n.address_street as STREET,
	    n.address_build as BUILDING,
	};
    }


    my $query = qq{ 
		SELECT 
			n.id as SWITCH_ID,
			n.name as DESCRIPTION,
			("4") as NETWORK_TYPE,
			("0") as SWITCH_TYPE,
			("$country") as COUNTRY,
			("$region") as REGION,
			("3") as ADDRESS_TYPE_ID,
			("0") as ADDRESS_TYPE,
			("$region_id") as REGION_ID,
			("$zone") as ZONE,
			$q
			n.address_flat as APARTMENT,
			n.disable as DISABLE,
			("$global_begin") as BEGIN_TIME,
			("$date_ended") as END_TIME
			from nas n
			$LEFT_JOIN
			WHERE n.nas_type='other'
		};
    my $switch = $db->prepare($query);
    $switch->execute() or DBI->errstr;

    my @rows = ();
    while( my $row = $switch->fetchrow_hashref()) {
	push @rows, $self->mapper($row, 'COMMUTATORS');
    }
    
    if($#rows > -1) {
	my $head_comm = join(';', @{ $self->{arr}->{COMMUTATORS} })."\n";
	open(COMMUTATORS, ">$files{COMMUTATORS}");
	print COMMUTATORS $head_comm;
	print COMMUTATORS @rows;
        close(COMMUTATORS) or die;
    }
    return 1;
}



sub pay_types {
    my $self = shift;
    my @types = split(/;/, $self->{conf}->{PAYSYS_PAYMENTS_METHODS}) if ($self->{conf}->{PAYSYS_PAYMENTS_METHODS});    

    do ("/usr/axbills/language/russian.pl");
    my $types = translate_list($Payments->payment_type_list({ COLS_NAME => 1 }));
    my @keys = ('ID', 'BEGIN_TIME', 'END_TIME', 'DESCRIPTION', 'REGION_ID');

    my @arr = ();
    push @arr, join(';', @keys)."\n";
    foreach my $type (@$types) {          
	$type->{id} =~ s/^\s+|\s+$//g;
	$type->{id} //= 0;
	push @arr, "$type->{id};$global_begin;$date_ended;$type->{name};$self->{conf}->{MFISOFT_ISP_ID}\n";
    }
    open(PAY_TYPE, ">$files{PAY_TYPE}");
    print PAY_TYPE @arr;
    close(PAY_TYPE) or die;

    return 1;
}

sub ipplan_report { 
	 my $self = shift;
         my DBI $dbh = $self->{db}->{db}; 
 
         my $sth = $dbh->prepare(qq{
	    SELECT id,
		DESCRIPTION,
		IPV4,
		INET6_NTOA(IPV6) as IPV6,
		IPV4_MASK,
		IPV6_MASK,
		BEGIN_TIME,
		DELETED,
		("$region_id") as REGION_ID
	    FROM MFISOFT_IP_PLAN
	 });
         $sth->execute or die DBI->errstr;

         if (($sth->rows) > 0) {
                 open(IP_PLAN, ">$files{IP_PLAN}") || die;
                 print IP_PLAN "DESCRIPTION;IP_TYPE;IPV4;IPV6;IP_MASK_TYPE;IPV4_MASK;IPV6_MASK;BEGIN_TIME;END_TIME;REGION_ID\n";
         } else { return; }

	 while(my $row = $sth->fetchrow_hashref()) {
	    $row->{END_TIME} = $date_ended;
	    if($row->{DELETED}) {
		$row->{END_TIME} = $self->{CURRENT_TIMESTAMP_3};
		$Settings->ip_plan_del_sc({ ID => $row->{id} });
	    }
	    print IP_PLAN $self->mapper($row, 'IP_PLAN');
	 }
	close(IP_PLAN) or die;
	return 1;
}

sub supplementary_service {
    my $self = shift;
    my $db = $self->{db}->{db};

    $Settings->sync_supplementary_services();
    my $list = $Settings->get_supplementary_services();

    if($list) {
	my $head_supplementary = join(';', @{ $self->{arr}->{SUPPLEMENTARY} })."\n";
	open(SUPPLEMENTARY, ">$files{SUPPLEMENTARY}");
	print SUPPLEMENTARY $head_supplementary;
	foreach my $service (@$list) {
	    $service->{REGION_ID} = $region_id;
	    $service->{END_TIME} = $date_ended;
	    if($service->{DELETED}) {
		$service->{END_TIME} = $self->{CURRENT_TIMESTAMP_3};
		print SUPPLEMENTARY  $self->mapper($service, 'SUPPLEMENTARY');

		$Settings->del_supplementary_service_for_sc({ del => $service->{ID}  });
		next;
	    }
	    print SUPPLEMENTARY $self->mapper($service, 'SUPPLEMENTARY');
	}
	close(SUPPLEMENTARY) or die;
    }
}

sub doc_type {
    my $self = shift;
    
    my @keys = (
		'DOC_TYPE_ID',
		'BEGIN_TIME',
		'END_TIME',
		'DESCRIPTION',
		'REGION_ID'
    );

    open(my $fh, ">$files{DOC_TYPE}");
	print $fh join(';', @keys)."\n";
	print $fh "1;$global_begin;$date_ended;Паспорт;$region_id\n";
    close($fh) or die;
    return;
}



=head2 sorm_payments()

=cut


sub sorm_payments {
	my $self = shift;
	
        my %pay_arr;
	my @sorm_pay;
	my @pay_arr;
        my $count_updates = 0;
        my $file_created = 0;

        my DBI $dbh = $self->{db}->{db};

        my $sth = $dbh->prepare(
	    qq{SELECT 
		    PAYMENT_TYPE,
	    	    PAY_TYPE_ID,
		    PAYMENT_DATE,
		    AMOUNT,
		    AMOUNT_CURRENCY,
		    PHONE AS PHONE_NUMBER,
		    ABONENT_ID AS ACCOUNT,
		    ABONENT_ID AS ABONENT_ID,
		    PAY_PARAMS,
		    COUNTRY,
		    REGION,
		    ZONE,
		    STREET,
		    BUILDING,
		    APARTMENT,
		    axbills_id
		FROM MFISOFT_PAYMENT
		ORDER BY axbills_id ASC
	});
        $sth->execute or die DBI->errstr;

        while(my $row = $sth->fetchrow_hashref()) { push(@sorm_pay, $row); }
	my $interval = 'INTERVAL -6 MONTH';
	
	if($self->{argv}->{FULL_PAY}) {
	     $interval = 'INTERVAL -3 YEAR';
	}
        $sth = $dbh->prepare(qq{SELECT ('86') AS PAYMENT_TYPE,
                payments.date AS PAYMENT_DATE,
                payments.sum AS AMOUNT,
                payments.uid AS ACCOUNT,
		payments.uid AS ABONENT_ID,
                payments.id AS axbills_id,
                payments.method AS PAY_TYPE_ID,
		payments.ext_id AS PAY_PARAMS,
		("$region_id") as REGION_ID,
		users.uid as UID,
		users_contacts.value AS PHONE_NUMBER
                FROM payments
                INNER JOIN users_pi ON users_pi.uid = payments.uid
		LEFT JOIN users on(users.uid = payments.uid)
		LEFT JOIN users_contacts on(users_contacts.id = (select id from users_contacts where uid = payments.uid AND type_id=2 limit 1))
		WHERE date > DATE_ADD("$current_date", $interval)
                ORDER BY payments.id ASC
        }); 
        $sth->execute or die DBI->errstr;

        while(my $row = $sth->fetchrow_hashref())  { $pay_arr{$row->{axbills_id}} = $row; }

    my $head_pay = join(';', @{ $self->{arr}->{PAYMENTS} })."\n";
    foreach my $entry (@sorm_pay) { 
	    #Поиск совпадений
	    if($entry->{axbills_id} && exists $pay_arr{$entry->{axbills_id}}) { 	
		delete $pay_arr{$entry->{axbills_id}};  
	    }
	    #Есть в буфере но нет в абилсе
	    elsif ($entry->{axbills_id} && !exists $pay_arr{$entry->{axbills_id}}) {
		my $sth = $dbh->prepare(qq{DELETE FROM MFISOFT_PAYMENT WHERE axbills_id = '$entry->{axbills_id}' });
		$sth->execute() if ($debug == '0');
	    }
	}
	#Новые платежи
	my @new_pay = values %pay_arr;

	my @print_arr = ();
	my $add_query = join(',', @{ $self->{query_arr}->{NEW_PAYMENTS_ADD} });	

	foreach my $new_entry (@new_pay) {
    	if (defined($new_entry->{axbills_id}) && $new_entry->{AMOUNT} > '0'&&$new_entry->{UID}) {
	    $new_entry->{INTERNAL_ID1} = $new_entry->{INTERNAL_ID2} = $new_entry->{ABONENT_ID};
	    if (not (defined($new_entry->{PHONE_NUMBER}))) {
		$new_entry->{PHONE_NUMBER} = 'нет данных';
	    }

	    if (not (defined($new_entry->{PAY_PARAMS})) or $new_entry->{PAY_PARAMS} eq '') {
		$new_entry->{PAY_PARAMS} = '';
	    } else {
		$new_entry->{PAYMENT_TYPE} = 82;
		my $Banc = ',  ООО "ПЭЙБЭРРИ"';
		my ($str1, $str2, $str3) = split(/:/, $new_entry->{PAY_PARAMS}, 3);
		if ($str1 eq 'VTB') {
			$Banc = ', РНКБ Банк (ПАО)';
		}
		if ($str3 && $str3 ne '') {
		    $new_entry->{PAY_PARAMS} = '№ платежа в ЕСПП: ' . $new_entry->{axbills_id} . ' № внешнего платежа: ' . $str2 . ' № терминала: ' . $str3 . ' № Договора: ' . $new_entry->{ACCOUNT} . $Banc;
		} else {
		    $new_entry->{PAY_PARAMS} = '№ платежа в ЕСПП: ' . $new_entry->{axbills_id} . ' № внешнего платежа: ' . $str2 . ' № Договора: ' . $new_entry->{ACCOUNT} . $Banc;
		}
	    }
		my $str = $self->mapper($new_entry, 'PAYMENTS', { VALIDATE => 1 });
		push @print_arr, $str;


		if($self->{argv}->{FULL_PAY}) {
			my ($pay_date, $pay_time) = split(/ /, $new_entry->{PAYMENT_DATE});

			if(date_diff($pay_date, $current_date) < 186) {
			    my $sth = $dbh->prepare(qq{
				    INSERT INTO MFISOFT_PAYMENT ($add_query)
					VALUES ('$new_entry->{PAYMENT_TYPE}', '$new_entry->{PAY_TYPE_ID}', '$new_entry->{PAYMENT_DATE}', 
						'$new_entry->{AMOUNT}', '$new_entry->{ACCOUNT}',
						'$new_entry->{axbills_id}', '$country','$region', 
						'$zone', '$city', '$street', '$build', '$apart', 
						'$new_entry->{PHONE_NUMBER}', '$new_entry->{PAY_PARAMS}', '$zip');
			    });
			    $sth->execute() if ($debug == '0');
			 }				
			 next;
		}

		#PAY 6 MONTH
		my $sth = $dbh->prepare(qq{ INSERT INTO MFISOFT_PAYMENT ($add_query)
                			    VALUES ('$new_entry->{PAYMENT_TYPE}', '$new_entry->{PAY_TYPE_ID}', '$new_entry->{PAYMENT_DATE}', 
                        			    '$new_entry->{AMOUNT}', '$new_entry->{ACCOUNT}',
                        			    '$new_entry->{axbills_id}', '$country','$region', 
						    '$zone', '$city', '$street', '$build', '$apart', 
                        			    '$new_entry->{PHONE_NUMBER}', '$new_entry->{PAY_PARAMS}', '$zip');
            	});
            	$sth->execute() if ($debug == '0');
	    } #end if
	} #end foreach

	if($#print_arr > -1) {
		open(PAYMENTS, ">$files{PAYMENTS}");
		print PAYMENTS $head_pay;
		print PAYMENTS @print_arr;
		close(PAYMENTS) or die; 
	}

	return;
}

sub gateway {
    my $self = shift;
    my $db = $self->{db}->{db};
    my $query = qq{
	 SELECT id AS GATE_ID,
		DESCRIPTION,
		GATE_TYPE,
		("$country") as COUNTRY,
		("$region") as REGION,
		("$region_id") as REGION_ID,
		ZIP,
		STREET,
		BUILDING,
		CITY,
		("0") as ADDRESS_TYPE,
		("3") as ADDRESS_TYPE_ID,
		IPV4,
		INET6_NTOA(IPV6) as IPV6,
		APARTMENT,
		BEGIN_TIME,
		DELETED
		from MFISOFT_GATEWAYS
    };
    my $gateways = $db->prepare($query);
    $gateways->execute() or DBI->errstr;

    my $str = '';
    my $str2 = '';

    while(my $row = $gateways->fetchrow_hashref()) {
	$row->{END_TIME} = $date_ended;
	if($row->{DELETED}) {
	    $row->{END_TIME} = $self->{CURRENT_TIMESTAMP_3};
	    $Settings->gateway_del_sc({ ID => $row->{GATE_ID} });
	}
	$str  .= $self->mapper($row, 'GATEWAYS');
	$str2 .= $self->mapper($row, 'GATEWAYS_IPS');
    }
    
    if($str) {
	open(GATEWAYS, ">$files{GATEWAYS}"); 
	print GATEWAYS join(';', @{ $self->{arr}->{GATEWAYS} })."\n";
	print GATEWAYS $str;
	close(GATEWAYS) or die;
    }

    if($str2) {
	open(GATEWAYS_IPS, ">$files{GATEWAYS_IP}");
	print GATEWAYS_IPS join(';', @{ $self->{arr}->{GATEWAYS_IPS} })."\n";
	print GATEWAYS_IPS $str2;
	close(GATEWAYS_IPS) or die;
    }
    return 1;
}

sub regions {
    my $self = shift;
    my @keys = (
	'ID',
	'BEGIN_TIME',
	'END_TIME',
	'DESCRIPTION',
	'MCC',
	'MNC'
    );
    open(REGIONS, ">$files{REGIONS}");
    print REGIONS join(';', @keys)."\n";
    print REGIONS "$region_id;$global_begin;$date_ended;$isp_description;;\n";
    close(REGIONS) or die;    

    return 1;
}


=head2 phone_special($attr)

=cut

sub phone_special {
    my $self = shift;
    my ($attr) = @_;
    my $db = $self->{db}->{db};
    
    my $query = qq{
	SELECT id,
	       DESCRIPTION,
	       PHONE_NUMBER,
	       IPV4,
	       INET6_NTOA(IPV6) as IPV6,
	       BEGIN_TIME,
	       DELETED,
	       ("$region_id") as REGION_ID
	from MFISOFT_PHONE_SPECIAL
    };

    my $prepare = $db->prepare($query);
    $prepare->execute() or die DBI->errstr;
        
    my @rows = ();
    while(my $row = $prepare->fetchrow_hashref()) {
	$row->{END_TIME} = $date_ended;
	if($row->{DELETED}) {
	    $row->{END_TIME} = $self->{CURRENT_TIMESTAMP_3};
	    $Settings->phone_special_del_sc({ ID => $row->{id} });
	}
	push @rows, $self->mapper($row, 'PHONE_SPECIAL');
    }

    if($#rows > -1) {
	my $head_phone_special = join(';', @{ $self->{arr}->{PHONE_SPECIAL} })."\n";                                                           
	open(PHONE_SPECIAL, ">$files{PHONE_SPECIAL}"); print PHONE_SPECIAL $head_phone_special;                                     
	print PHONE_SPECIAL @rows;
	close(PHONE_SPECIAL) or die;
    }

    return 1;
}



sub mapper {
    my $self = shift;
    my ($data, $key, $attr) = @_;

    my $str = '';
    
    if($data->{IPV4}) {
	$data->{IP_TYPE} = '0';
	$data->{IP_MASK_TYPE} = '0';
    }

    if($data->{IPV6}) {
	if($data->{IPV4}) {
	    $data->{IP_TYPE} .= ',1';
	    $data->{IP_MASK_TYPE} .= ',1';
	}
	else {
	    $data->{IP_TYPE} = 1;
	    $data->{IP_MASK_TYPE} = 1;
	}
    }

    map { 
	if( defined($data->{$_}) ) { 
	    if($attr->{VALIDATE}) {
		$data->{$_} = $self->validate($data->{$_});
	    }

	    if($_ eq 'IPV4') {
		my $hexip = sprintf('%X', $data->{$_}) if($data->{$_});
		if($hexip) {
		    for(;;) { $hexip = (length($hexip) < 8&&length($hexip) > 4) ? "0$hexip" : last ; }
		    $str .= $hexip.";";
		} 
		else { $str .= ";"; }
	    }
	    elsif($_ eq 'IPV4_MASK') {
		if(length($data->{IPV4_MASK}) <= 2&&$data->{IPV4_MASK} != '0') {
		    $data->{$_} = $self->ipv4_mask_former($data->{$_});
		}
		my $hexmask = sprintf('%X', $data->{$_}) if($data->{$_});
		$str .= ($hexmask&&$data->{IPV4}) ? $hexmask.';' : ';';
	    }
	    elsif($_ eq 'MAC') {
		$data->{$_} =~ s/[-:\.]//g;
		my @arr = split(//, $data->{$_});
		my $mac = '';
		for my $i (0..11) {
		    $mac .= $arr[$i] if(defined($arr[$i]));
		}
		
		$str .= ($mac&&length($mac) == '12') ? uc($mac).";" : ';';
	    }
	    elsif($_ eq 'IPV6') {
		$str .= $self->ipv6_ip_former($data->{$_}) if($data->{IPV6});
	    }
	    elsif($_ eq 'IPV6_MASK') {
		$str .= ($data->{IPV6}&&$data->{IPV6_MASK}) ? $self->ipv6_mask_former($data->{$_}) : ';';
	    }
	    else { $str .= $data->{$_}.";"; }
	} 
	else {  $str .= ';'; } 
    } @{ $self->{arr}->{$key} };
    $str = $self->trim_end($str);

    return $str;
}

sub ipv4_mask_former {
    my $self = shift;
    my ($attr) = @_;

    my $mask = $attr;
    $mask = unpack("N", pack('B32', (1x$mask)));

    return $mask;
}

sub ipv6_mask_former {
    my $self = shift;
    my ($attr) = @_;

    my $netmask = unpack("H*", pack('B128', (1 x $attr) ) );
    $netmask = uc($netmask);

    return $netmask.';';
}

sub ipv6_ip_former {
    my $self = shift;
    my ($attr) = @_;
    my @ip = $attr =~ /([0-9a-f]{1,5})/g;                                        
    my $octets_count = 7 - $#ip;    
                                             
    if($octets_count) {                          
	my $zero_octets = '';                      
	for (my $i = 0; $i < $octets_count; $i++) {
		$zero_octets .= ":0000";                 
	}                                          
                                         
	$attr =~ s/\:\:/$zero_octets\:/;           
    }                                            

    my @ipv6 = split(/:/, $attr);
    for (my $i = 0; $i <= 7; $i++)  {                    
	for(;;) {                        
    	    if(length($ipv6[$i]) < 4) {         
    		$ipv6[$i] = "0$ipv6[$i]";                        
    	    }                                                
    	    else { last };                             
	}
	$ipv6[$i] = uc($ipv6[$i]);
    }
    
    return join('', @ipv6).";";
}

=head2 vlidate($attr)

=cut

sub validate {
    my $self = shift;
    my ($attr) = @_;

    if(defined($attr)) {
		$attr =~ s/[\r\n\t;!)(,#\'\"\+]//g;
		$attr =~ s/X$//g;
		$attr =~ s/^\s+//g;
		$attr =~ s/\s+$//g;
    } else {
		$attr = q{};
    }

    return $attr;
}


=head2 trim_end($attr)

=cut

sub trim_end {
    my $self = shift;
    my ($attr) = @_;

    $attr =~ s/;$//;
    $attr .= "\n";
    return $attr;
}


=head2 check_date($date, $date2)

=cut

sub check_date {
	my $self = shift;
	my ($date, $date2) = @_;

	my ($start, undef) = split(/ /, $date);
	my ($end, undef) = split(/ /,$date2);

	my $diff = date_diff($date2, $date);
	return $diff;
}

=head2 reverse_address()

=cut

sub reverse_address {
    my $self = shift;
    my ($attr) = @_;

    $attr->{ADDRESS_TYPE_ID} = 3;
    my @keys = ('ZONE','CITY','STREET','BUILDING','APARTMENT');

    map { $attr->{$_} = $attr->{"REG_".$_} } @keys;

    return 1;
}

sub send {                                                                     
  my $self = shift;                                                            
  my ($attr) = @_;
                          
  my $archive = $self->{conf}->{MFISOFT_ARCHIVE} || '0';                          
  my $archive_path = $self->{conf}->{MFISOFT_ARCHIVE_PATH} || '';

  my $ftp = Net::FTP->new($server_ip, Timeout => $self->{conf}->{MFISOFT_FTP_TIMEOUT}, Debug => 0, Passive => $self->{conf}->{MFISOFT_FTP_PASSIVE_MODE} || 0) or die "Cannot connect to $server_ip: $@"; 
  $ftp->login($login, $password) or die "Cannot login ", $ftp->message;
  $ftp->binary() if($self->{conf}->{MFISOFT_FTP_BINNARY});

  foreach my $report (values %files) {
    print $report."\n" if($debug > 2);
    if (-e $report) {
	$ftp->put($report) or die "Error ", $ftp->message;

	if ($archive == 1 && $archive_path ne '') {
           my $dir = strftime "$archive_path/arch-%Y-%m-%d", localtime(time());
	   my $arch = strftime "$dir-%Y-%m-%d.tar", localtime(time());
           unless(mkdir($dir))
           {
                  if ($! != 17)
                  {
                          die("Can't create arch directory: ".$!);
                  }
                  system ("cp $report $dir");
           }                                                                                                                                                                                                                            
        }                                                                                                                                                                                                                           
                                                                                                                                                                                                                                    
        if ($debug < 3) {                                                                                                                                                                                                             
    	    unlink $report;                                                                                                                                                                                                             
        }
    }
 }
 $ftp->quit;

  return 1;                                                                    
}


sub params_former {
    my $self = shift;

    $self->{arr} = {
	ABONENT => [
	    'ID','REGION_ID','CONTRACT_DATE',            
	    'CONTRACT','ACTUAL_FROM','ACTUAL_TO',        
	    'ABONENT_TYPE','NAME_INFO_TYPE',             
	    'FAMILY_NAME','GIVEN_NAME','INITIAL_NAME','UNSTRUCT_NAME','BIRTH_DATE',
	    'IDENT_CARD_TYPE_ID','IDENT_CARD_TYPE','IDENT_CARD_SERIAL','IDENT_CARD_NUMBER','IDENT_CARD_DESCRIPTION',
	    'IDENT_CARD_UNSTRUCT','BANK','BANK_ACCOUNT','FULL_NAME',                  
	    'INN','CONTACT','PHONE_FAX','STATUS','ATTACH','DETACH','NETWORK_TYPE',                              
	    'INTERNAL_ID1','INTERNAL_ID2'
	],
	ABONENT_IDEN => [             
	    'ABONENT_ID','REGION_ID','IDENT_TYPE','PHONE',            
	    'INTERNAL_NUMBER','IMSI','IMEI','ICC','MIN',              
	    'ESN','EQUIPMENT_TYPE','MAC','VPI','VCI','LOGIN',         
	    'E_MAIL','PIN','USER_DOMAIN','RESERVED','ORIGINATOR_NAME',
	    'IP_TYPE','IPV4','IPV6','IP_MASK_TYPE','IPV4_MASK',       
	    'IPV6_MASK','IP_RANGE_START','IP_RANGE_END',              
	    'INTERNAL_ID1','INTERNAL_ID2','BEGIN_TIME',               
	    'END_TIME','LINE_OBJECT','LINE_CROSS',                    
	    'LINE_BLOCK','LINE_PAIR','LINE_RESERVED',                 
	    'LOC_TYPE','LOC_LAC','LOC_CELL','LOC_TA',                 
	    'LOC_CELL_WIRELESS','LOC_MAC','LOC_LATITUDE',             
	    'LOC_LONGITUDE','LOC_PROJECTION_TYPE',                    
	    'LOC_IP_TYPE','LOC_IPV4','LOC_IPV6','LOC_IP_PORT'         
	],
	ABONENT_ADDR => [
	    'ABONENT_ID','REGION_ID','ADDRESS_TYPE_ID','ADDRESS_TYPE',
	    'ZIP','COUNTRY','REGION','ZONE','CITY','STREET','BUILDING',
	    'BUILD_SECT','APARTMENT','UNSTRUCT_INFO',
	    'BEGIN_TIME','END_TIME','INTERNAL_ID1','INTERNAL_ID2'
	],
	ABONENT_SERV => [
	    'ABONENT_ID','REGION_ID','ID',
	    'BEGIN_TIME','END_TIME',
	    'PARAMETER','INTERNAL_ID1','INTERNAL_ID2'
	],
	PAYMENTS    => [
	    'PAYMENT_TYPE','PAY_TYPE_ID','PAYMENT_DATE','AMOUNT',
	    'AMOUNT_CURRENCY','PHONE_NUMBER','ACCOUNT','INTERNAL_ID1',
	    'INTERNAL_ID2','BANK_ACCOUNT','BANK_NAME','EXPRESS_CARD_NUMBER',
	    'TERMINAL_ID','TERMINAL_NUMBER','LATITUDE','LONGITUDE','PROJECTION_TYPE',
	    'CENTER_ID','DONATED_PHONE_NUMBER','DONATED_ACCOUNT',
	    'DONATED_INTERNAL_ID1','DONATED_INTERNAL_ID2',
	    'CARD_NUMBER','PAY_PARAMS','PERSON_RECIEVED','BANK_DIVISION_NAME','BANK_CARD_ID',
	    'ADDRESS_TYPE_ID','ADDRESS_TYPE','ZIP','COUNTRY',
	    'REGION','ZONE','CITY','STREET','BUILDING',
	    'BUILD_SECT','APARTMENT','UNSTRUCT_INFO','REGION_ID'
	],
	COMMUTATORS => [
	    'SWITCH_ID','BEGIN_TIME','END_TIME',
	    'DESCRIPTION','NETWORK_TYPE',
	    'SWITCH_TYPE','ADDRESS_TYPE_ID','ADDRESS_TYPE',
	    'ZIP','COUNTRY','REGION','ZONE','CITY','STREET',
	    'BUILDING','BUILD_SECT','APARTMENT','UNSTRUCT_INFO',
	    'SWITCH_SIGN','REGION_ID'
	],
	PHONE_SPECIAL => [
	    'PHONE_NUMBER','DESCRIPTION','BEGIN_TIME','END_TIME',
	    'IP_TYPE','IPV4','IPV6','REGION_ID'
	],
	SUPPLEMENTARY => [
	    'ID','MNEMONIC','BEGIN_TIME','END_TIME','DESCRIPTION','REGION_ID'
	],
	GATEWAYS => [
	    'GATE_ID','BEGIN_TIME','END_TIME','DESCRIPTION',
	    'GATE_TYPE','ADDRESS_TYPE_ID','ADDRESS_TYPE',
	    'ZIP','COUNTRY','REGION','ZONE','CITY',
	    'STREET','BUILDING','BUILD_SECT','APARTMENT',
	    'UNSTRUCT_INFO','REGION_ID'
	],
	GATEWAYS_IPS => [
	    'GATE_ID','IP_TYPE','IPV4',
	    'IPV6','IP_PORT','REGION_ID'
	],
	IP_PLAN => [
	    'DESCRIPTION','IP_TYPE','IPV4','IPV6',
	    'IP_MASK_TYPE','IPV4_MASK','IPV6_MASK',
	    'BEGIN_TIME','END_TIME','REGION_ID'
	]
    };


    $self->{query_arr} = {
	NEW_ABONENT_ADD => [
	    'ABONENT_ID','CONTRACT_DATE','CONTRACT','ACCOUNT',
	    'ABONENT_TYPE','UNSTRUCT_NAME','BIRTH_DATE',
            'IDENT_CARD_UNSTRUCT','IS_COMPANY','BANK','BANK_ACCOUNT',
	    'FULL_NAME','INN','CONTACT','PHONE_FAX',
	    'STATUS','ACTUAL_FROM','ATTACH','COUNTRY',
	    'REGION','CITY','STREET','BUILDING',
	    'APARTMENT','REG_CITY','REG_STREET',
	    'REG_BUILDING','REG_APARTMENT','ABONENT_ADDR_BEGIN_TIME',
	    'EQUIPMENT_TYPE','MAC','LOGIN','IPV4',
	    'IPV4_MASK','ABONENT_IDENT_BEGIN_TIME','PHONE',
	    'TP_ID','ABONENT_SRV_BEGIN_TIME','PARAMETER'
	],
	NEW_PAYMENTS_ADD => [
	    'PAYMENT_TYPE','PAY_TYPE_ID','PAYMENT_DATE','AMOUNT',
	    'ABONENT_ID','axbills_id','COUNTRY','REGION','ZONE',
	    'CITY','STREET','BUILDING','APARTMENT','PHONE','PAY_PARAMS','ZIP'
	]
    };


    return $self;
}

sub help {
    my $self = shift;

print q{
------------------- HELP --------------------
/usr/axbills/billd mfisoft TYPE=Mfisoft [ATTR]=1
	
[ATTR] -
  
                - Обычный режим работы
  HELP          - Помощь
  RELOAD        - Перезагрузка таблиц и повторная полная выгрузка
  SKIP_PAYMENTS - Не выгружать платежи
  FULL_PAY      - Параметр при первой выгрузке
  SKIP_FTP      - Не выгружать на FTP
};    
return;
}

1
