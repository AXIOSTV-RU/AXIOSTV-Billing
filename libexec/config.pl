#!/usr/bin/perl -w
# AXbills configuretion file

$PROGRAM='AXIOSTV Billing System';

#Брендирование мини лого 50x50 основное лого 220x50
$conf{FULL_LOGO} = '/img/logo/logo.png';
$conf{MINI_LOGO} = '/img/logo/logo-mini.png';

#DB configuration
$conf{dbhost}='127.0.0.1';
$conf{dbname}='bill';
$conf{dbuser}='bill';
$conf{dbpasswd}='bill';
$conf{dbtype}='mysql';
#For MySQL 5 and highter (cp1251, utf8)
$conf{dbcharset}='utf8mb4';

#Mail configuration
$conf{ADMIN_MAIL}='admin@lis.su';
$conf{USERS_MAIL_DOMAIN}='axiostv.ru';
$conf{MAIL_CHARSET}='utf-8';
$conf{default_language}='russian';
$conf{default_charset}='utf-8';
$conf{WEB_TITLE}='AXIOSTV billing systems';
$conf{WEB_TITLE_ADMIN}='AXIOSTV admin billing systems';
$conf{CONTACTS_NEW} = 1;
$conf{PASSWORD_RECOVERY}=1;

$conf{HELP_DESK_LOGIN} = 'public_vers';
$conf{HELP_DESK_PID} = 10000;
$conf{HELP_DESK_ISSUETYPE} = 10000;

our @MODULES = ('Internet',
            'Cams',
            'Netblock',
            'Events',
            'Docs',
            'Mail',
            'Msgs',
            #'Ureports',
            'Sysinfo',
            'Equipment',
            'Dhcphosts',
            #'Ipn',
            'Tags',
            'Cards',
            'Paysys',
            'Abon',
            'Callcenter',
            'Maps',
            'Hotspot',
            'Voip',
            'Ring',
            'Iptv',
            'Tasks',
            'Sorm3'
);

$conf{BILLD_PLUGINS} = 'sorm3';
$conf{SORM3_TYPE} = 'spectech';	# spectech | norsi | citadel | mfisoft
$conf{OFFICE_ZIP} = '398024';
$conf{OFFICE_CITY} = 'Липецк';
$conf{OFFICE_STREET} = 'Победы';
$conf{OFFICE_BUILD} = '106а';
$conf{OFFICE_APART} = '38';
$conf{SORM3_TIME_OFFSET} = '-3';
$conf{SORM3_ARCHIVE} = 1;
$conf{SORM3_ARCHIVE_PATH} = '/usr/axbills/var/sorm/Archive/';
$conf{SORM3_ISP_ID} = '44';
#	Идентификатор провайдера из "Информация по операторам связи и их филалах"
$conf{SORM3_DEFAULT_ZIP} = '398000';
$conf{SORM3_COUNTRY} = 'РОССИЙСКАЯ ФЕДЕРАЦИЯ';
$conf{SORM3_REGION} = 'Липецкая';
$conf{SORM3_ZONE} = 'Липецкий';
$conf{SORM3_SERVER} = '192.168.1.1';
$conf{SORM3_LOGIN} = 'sorm';
$conf{SORM3_PASSWORD} = 'sorm';
$conf{SORM3_ERR_LOGIN} = 'err_sorm';
$conf{SORM3_ERR_PASSWORD} = 'err_sorm';
$conf{SORM3_BACKBON_IP_PLAN} = [[ 'backbon0', '', '' ], [ 'backbon1', '',  '' ], [ 'backbon2', '',  '' ], [ 'staff_net', '',  '' ],];

$conf{rt_billing}=1;
$conf{INTERNET_CUSTOM_PERIOD}=1;

$conf{NETBLOCK_OSSL_BIN}='/gost-ssl/bin/openssl';
$conf{NETBLOCK_DNS_TPL}='local-data: «%NAME A 10.0.0.7»';
$conf{NETBLOCK_DNS_ADD_CMD}='/usr/local/sbin/unbound-control -s 10.0.0.4 local_data %NAME A 10.0.0.7';
$conf{NETBLOCK_DNS_DEL_CMD}='/usr/local/sbin/unbound-control -s 10.0.0.4 local_data_remove %NAME';
$conf{NETBLOCK_SKIP_NAME}='www.youtube.com,youtube.com,ru.wikipedia.org';
#$conf{NETBLOCK_SKIP_IP}='64.233.161.198,64.233.162.198,64.233.163.198,64.233.164.198'
#$conf{NETBLOCK_FW_SKIP_CMD} = '/sbin/ipfw table 14 add %IP';
#$conf{NETBLOCK_TZ} = '+05:00';
$conf{NETBLOCK_CRT_ALERT}='30';

$conf{DOCS_ACCOUNT_EXPIRE_PERIOD}=30;
$conf{MONEY_UNIT_NAMES}='руб.;коп.';
$conf{DOCS_VAT_INCLUDE}=0;
$conf{DOCS_ORDERS}=['Услуги связи', 'Тех. поддержка'];
$conf{DOCS_LANGUAGE}='russian';
#$conf{DOCS_PAYMENT_METHODS}='-'
$conf{DOCS_PAYMENT_SYSTEM_CURRENCY}=1;
$conf{DOCS_PRE_INVOICE_PERIOD}=25;
#$conf{DOCS_INVOICE_ORDERS}=12;
#$conf{DOCS_PAYMENT_RECEIPT_SKIP}=1;
#$conf{DOCS_PAYMENT_SENDMAIL}=1;
$conf{DOCS_USERPORTAL_ACT}=1;
$conf{SKIP_PERIOD_INFO}=1;
$conf{DOCS_PDF_PRINT}=1;
#$conf{DOCS_CERT_CMD}="/gost-ssl/bin/openssl smime -sign -signer 1.pem -gost89 -binary -noattr -outform DER -in %INPUT_FILE% -out %CERT_FILE%";
#$conf{DOCS_STORE_DIR}='/usr/axbills/var/docs/';

$conf{REVISOR_UID} = '138';
$conf{REVISOR_ALLOW_IP} = '185.90.227.1';

$conf{WORDPRESS_URL} = 'http://axiostv.ru/';
$conf{WORDPRESS_BLOGID} = 1;
$conf{WORDPRESS_ADMIN} = 'admin';
$conf{WORDPRESS_PASSWORD} = '12345678';

%AUTH = ();
$AUTH{default} = 'Auth2';
$AUTH{accel_ppp}='Auth2';
$AUTH{mpd5}='Auth2';
#For VoIP GNU Gatekeeper Auth
$AUTH{gnugk}    = 'Voip_aaa';
#For Astrisk accounting
$AUTH{asterisk} = 'Voip_aaa';

%ACCT = ();
$ACCT{default} = 'Acct2';
$ACCT{accel_ppp}='Acct2';
#For VoIP GNU Gatekeeper accounting
$ACCT{gnugk}    = 'Voip_aaa';
#For Astrisk accounting
$ACCT{asterisk} = 'Voip_aaa';

$conf{VOIP_AGI_PROTOCOL}='SIP';
$conf{VOIP_DEFAULTDIALTIMEOUT}=120;
$conf{VOIP_MAX_SESSION_TIME}=10800;
$conf{VOIP_NUMBER_EXPR} = '^\+7/7;^810/;^8/7;^2([0-9]{5})/747422$number';
$conf{VOIP_ASTERISK_USERS}='/usr/axbills/AXbills/templates/users.conf';
$conf{VOIP_ONEMONTH_INCOMMING_ALLOW}=0;
$conf{VOIP_ASTERISK_IVR_DIR}='/var/lib/asterisk/sounds/';
$conf{VOIP_AGI_DIAL_DELIMITER}=',';
$conf{VOIP_ASTERISK_RESTART}='';
$conf{CALLCENTER_MENU}=1;
$conf{ASTERISK_AMI_IP}='91.192.99.1';
$conf{ASTERISK_AMI_PORT}='5039';
$conf{ASTERISK_AMI_USERNAME}='admin';
$conf{ASTERISK_AMI_SECRET}='123456';
$conf{ASTERISK_CALL}='from-internal';

$conf{IPTV_CUSTOM_PERIOD}=1;
#$conf{IPTV_ALLOW_GIDS}='1,23,56';
#$conf{IPTV_CLOSE_PERIOD}=1;
$conf{IPTV_USER_CHG_TP}=1;
$conf{IPTV_USER_CHG_CHANNELS}=1;
#$conf{IPTV_USER_EXT_CMD}='iptv_access_ctl.pl LOGIN=%LOGIN%';
#$conf{IPTV_CMD_DEBUG}=1;
$conf{IPTV_STALKER_SINGLE_ACCOUNT}=1;

#Technical works banner in admin and user interface
#$conf{tech_works}='Technical works';

$conf{CUSTOM_START_PAGE}=1;
$conf{AUTH_METHOD}=1;

#Periodic functions
$conf{p_admin_mails}=1;  # Send periodic admin reports
$conf{p_users_mails}=1;  # Send user warning  messages

# chap encryption decription key
$conf{secretkey}="123456789012345678901234";
$conf{s_detalization}=1; #make session detalization recomended for vpn leathed lines
$conf{ERROR2DB}=1;

#Octets direction
# server - Count octets from server side
# user   - Count octets from user side (default)
$conf{octets_direction}='user';

#Check web interface brute force
$conf{wi_bruteforce}=10;
$conf{user_finance_menu}=1; 

#Minimum session costs
$conf{MINIMUM_SESSION_TIME}=10; # minimum session time for push session to db
$conf{MINIMUM_SESSION_TRAF}=200; # minimum session trafic for push session to db

#System admin id
#ID for system operation, periodic procces
$conf{SYSTEM_ADMIN_ID}=2;
#ID For users web operations
$conf{USERS_WEB_ADMIN_ID}=3;

#System Langs
$conf{LANGS}="russian:Русский;";

$conf{SYSTEM_CURRENCY}=643;
$conf{CURRENCY_ICON}='fas fa-ruble-sign';
#$conf{CURRENCY_ICON}='currency rouble';

#Web interface
$conf{PASSWD_LENGTH}=6;
$conf{PASSWD_SYMBOLS}="1234567890";

$conf{MAX_USERNAME_LENGTH}=9;

# User name expration
$conf{USERNAMEREGEXP}="^[a-z0-9_][a-z0-9_-]*\$";
$conf{list_max_recs}=25;
$conf{web_session_timeout} = 86000;
$conf{user_chg_passwd}=0;

#$conf{PHONE_FORMAT}='\d+';

#Auto assigning MAC in first connect
$conf{MAC_AUTO_ASSIGN} = 1;
$conf{KBYTE_SIZE}      = 1024;
$conf{ADDRESS_REGISTER}= 1;

# Debug mod 
$conf{debug}=10;
$conf{foreground}=0;
$conf{debugmods}='LOG_ALERT LOG_WARNING LOG_ERR LOG_INFO';

#show auth and accounting time need Time::HiRes module (available from CPAN)
# Check script runnig time
$conf{time_check}=1;

# Folders and files
$base_dir='/usr/axbills/';
$lang_path=$base_dir . 'language/';
$lib_path=$base_dir .'libexec/';
$var_dir=$base_dir .'var/';
$conf{SPOOL_DIR}=$base_dir.'var/q';

# Backup SQL data
$conf{BACKUP_DIR}=$base_dir.'/backup';

# Template folder
$conf{TPL_DIR}   = $base_dir . 'AXbills/templates/';
$conf{LOG_DEBUG} = $base_dir . 'var/log/axbills.debug';
$conf{LOGFILE}   = $base_dir . 'var/log/axbills.log';

use POSIX qw(strftime);
$DATE    = strftime "%Y-%m-%d", localtime(time);
$TIME    = strftime "%H:%M:%S", localtime(time);
$curtime = strftime("%F %H.%M.%S", localtime(time));
$year    = strftime("%Y", localtime(time));

#@REGISTRATION = ('Internet');
#$conf{REGISTRATION_CAPTCHA}=1;
#$conf{DV_REGISTRATION_TP_GIDS}='1;2;35;' #	Группы тарифных планов доступные при регистрации
#$conf{DV_REGISTRATION_SEND_SMS}=1; 	#Отправлять смс при регистрации (если включён модуль SMS)
#$conf{DV_REGISTRATION_ADDRESS}=1; 	#Показывать форму адреса при регистрации 
$conf{REGISTRATION_SHOW_PASSWD}=1; #	Показывать пользователю пароль после регистрации
#$conf{REGISTRATION_GID}='11'; #	Вносить вновь зарегистрированных абонентов в группу
#$conf{REGISTRATION_PREFIX}='a_'; #	добавляется данный префикс при регистрации логинов
#$conf{REGISTRATION_DEFAULT_TP}='111'; #	Тарифный план по умолчанию при регистрации
$conf{REGISTRATION_CHECK_PHONE}=1; #	Обязательный телефон при регистрации 
###
#$conf{NAS_PORT_AUTH}=1;
#$conf{DHCPHOSTS_SWITCH_MAC_AUTH}='1,2,…';
#$conf{ACCEL_IPOE_GUEST_POOL}='NAS_ID:POOL_ID';
$conf{DHCPHOSTS_LEASES}='db';
#$conf{ACCEL_IPOE_DEBUG}=3;
$conf{AUTH_EXPR}='DHCP-Option82:0x(01)(06)[0-9a-f]{4}([0-9a-f]{4})\d{2}([0-9a-f]{2})(02)(08)[0-9a-f]{4}([0-9a-f]{12}):ID,SIZE,VLAN,PORT,ID,SIZE,NAS_MAC';
$conf{AUTH_PARAMS}=1;

$conf{PAYSYS_DEBUG}=0;

#PAYSYS new schema
$conf{PAYSYS_NEW_SCHEME}=1;
$conf{PAYSYS_NEW_SETTINGS} = 1;
$conf{PAYMENT_METHOD_NEW}=1;


### HOTSPOT
#$conf{HOTSPOT_LOGIN_LENGTH} = 7;
#$conf{HOTSPOT_LOGIN_PREFIX} = '1';
$conf{HOTSPOT_AUTO_LOGIN} = 1;
#$conf{HOTSPOT_MAC_CHANGE} = 1;
$conf{HOTSPOT_REDIRECT_URL} = 'https://www.google.com';
$conf{HOTSPOT_CHECK_PHONE} = 1;
$conf{HOTSPOT_AUTH_NUMBER} = '210000';
$conf{HOTSPOT_GUESTS_GROUP} = 'Hotspot cliets';
$conf{HOTSPOT_GUESTS_GID} = '5';
$conf{HOTSPOT_LOGIN_LENGTH} = 7;
$conf{HOTSPOT_LOGIN_PREFIX} = '9';
#$conf{HOTSPOT_MAC_LOGIN} = 1;
$conf{HOTSPOT_PHONE_LOGIN} = 1;
$conf{HOTSPOT_TPS} = '99';

### Telegram
#$conf{TELEGRAM_LOAD_EXTENSIONS} = "User_interface";
#$conf{TELEGRAM_TOKEN} = '';
#$conf{TELEGRAM_MSGS_BOT_ENABLE} = 1;
$conf{BILLING_URL} = 'https://stat.axiostv.ru/';
$conf{TELEGRAM_DEBUG} = 8;
$conf{TELEGRAM_LOG} = '/var/log/telegram.log';
$conf{TELEGRAM_DEBUG_FILE} = '/var/log/telegram.log';
$conf{TELEGRAM_API_REQUEST_INTERVAL} = 3;
$conf{TELEGRAM_API_DEBUG} = 8;
$conf{TELEGRAM_API_DEBUG_FILE} = '/var/log/telegram.log';
#$conf{MSGS_MESSAGING_DEBUG_FILE} = '/var/log/telegram_msgs.log';

$conf{WEBSOCKET_ENABLED} = 1;
$conf{WEBSOCKET_DEBUG} = 6;

1
