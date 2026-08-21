#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use JSON;
use CGI;
use Encode;
use File::Basename;
use CGI::Carp qw(fatalsToBrowser);
use CGI qw(:standard);
use POSIX 'strftime';
use Time::Local;
use Net::SMPP;

# Подключаем конфигурацию
our %conf;
require '/usr/axbills/libexec/config.pl';

# Флаг для включения дебага
my $debug_mode = $conf{smpp_log} || 0;

# Функция для записи отладочной информации в файл
sub debug_log {
    my ($message) = @_;
    return unless $debug_mode;

    my $log_file = $conf{smpp_log_file} || '/usr/axbills/var/log/smpp.log';
    open my $fh, '>>', $log_file or warn "Не удалось открыть файл лога: $!";

    if ($fh) {
        print $fh scalar(localtime) . " - $message\n";
        close $fh or warn "Не удалось закрыть файл лога: $!";
    }
}

# Логируем начало обработки запроса
debug_log("Запуск скрипта");

# Устанавливаем соединение с базой данных
debug_log("Подключение к базе данных");
my $dbh = DBI->connect("dbi:mysql:$conf{dbname}", $conf{dbuser}, $conf{dbpasswd})
    or die "Не удалось подключиться к базе данных: $DBI::errstr";


# Параметры подключения к SMPP-серверу
my $host = $conf{SMPP_SERVER_HOST}; 'your.smpp.server';  # Замените на адрес вашего SMPP-сервера
my $port = $conf{SMPP_SERVER_PORT}; 2775;                 # Порт SMPP-сервера (обычно 2775)
my $system_id = $conf{SMPP_SYSTEM_ID}; 'your_system_id'; # Ваш system_id
my $password = $conf{SMPP_PASSWORD}; 'your_password';   # Ваш пароль
my $source_addr = $conf{SMPP_CLIENT_ID}; 'source_addr';  # Отправитель
my $destination_addr; # Получатель
my $message; # Сообщение

GetOptions("number=s" => \$destination_addr, "text=s" => \$message);

# Создаем объект SMPP
my $smpp = Net::SMPP->new(
    host      => $host,
    port      => $port,
    system_id => $system_id,
    password  => $password,
);

# Подключаемся к SMPP-серверу
$smpp->connect or die "Cannot connect to SMPP server: $!";

# Отправляем сообщение
my $result = $smpp->send_sms(
    source_addr       => $source_addr,
    destination_addr  => $destination_addr,
    short_message     => $message,
    data_coding       => 0, # 0 - default (ASCII)
);

if ($result) {
    print "Message sent successfully!\n";
} else {
    print "Failed to send message: " . $smpp->error . "\n";
}

# Отключаемся от SMPP-сервера
$smpp->disconnect;

