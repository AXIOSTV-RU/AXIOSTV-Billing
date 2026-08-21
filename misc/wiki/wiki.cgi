#!/usr/bin/perl

use strict;
use warnings;

# Установка ссылок для редиректа
my $redirect_url = 'https://billing.axiostv.ru/pages/viewpage.action?pageId=';
my $clean_url = 'https://billing.axiostv.ru/';

# Хэш соответствий
my %redirects = (
	'Internet:internet_online'		=> $redirect_url.'1867842',
	'Internet:internet_tp'			=> $redirect_url.'1867898',
	'form_users'				=> $redirect_url.'1867854',
	'user_group'				=> $redirect_url.'4358198',
	'Control/Nas_mng:form_nas'		=> $redirect_url.'917554',
	'Abon:abon_tariffs'			=> $redirect_url.'917640',
	'Equipment:equipment_model'		=> $redirect_url.'3145760',
	'Equipment:equipment_types'		=> $redirect_url.'3145741',
#	'Equipment:equipment_traps_types'	=> $redirect_url.'3145741',
	'Equipment:json_conf_main'		=> $redirect_url.'3145770',
	'Storage:storage_main'			=> $redirect_url.'5341292',


    # Добавьте сюда другие соответствия
);

# Получение параметра из URL
my $query = $ENV{'QUERY_STRING'} || '';

# Проверка наличия соответствия в хэше
if (exists $redirects{$query}) {
    my $url = $redirects{$query};
    # Вывод HTTP заголовков и редирект
    print "Location: $url\n";
    print "Content-Type: text/html\n\n";
    print "<html><head><meta http-equiv='refresh' content='1;url=$url'></head><body>Ищем...</body></html>";
} else {
    # Перенаправление на $clean_url, если соответствия нет или не указано
    print "Location: $clean_url\n";
    print "Content-Type: text/html\n\n";
    print "<html><head><meta http-equiv='refresh' content='1;url=$clean_url'></head><body>Не найдена, открываем основное...</body></html>";
}
