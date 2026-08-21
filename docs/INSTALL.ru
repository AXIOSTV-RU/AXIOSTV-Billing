
=====AXbills - Установка=====
Загрузить пакет можно по адресу [[http://sourceforge.net/projects/axbills/]]\\

  # tar zxvf axbills-0.5x.tgz
  # cp -Rf axbills /usr/
  # cp /usr/axbills/libexec/config.pl.default /usr/axbills/libexec/config.pl

Правим конфигурационный файл системы\\
**/usr/axbills/libexec/config.pl** \\

\\
  #DB configuration 
  $conf{dbhost}='localhost';
  $conf{dbname}='axbills'; 
  $conf{dbuser}='axbills';
  $conf{dbpasswd}='sqlpassword'; 
  $conf{ADMIN_MAIL}='info@your.domain'; 
\\

**При изменении значения в $conf{secretkey} поменяйте его также в файле axbills/axbills.sql **

=====Настройка сопутствующего ПО=====

=====MySQL=====
Загрузить пакет MySQL можно по адресу [http://www.mysql.com]\\
Пример настройки для MySQL версии 5.1

  # tar xvfz mysql-5.1.x.tar.gz
  # cd mysql-5.1.x
  # ./configure
  # make
  # make install

Создаём пользователя и базу.

  # mysql --default-character-set=utf8 -u root -p

  GRANT ALL ON axbills.* TO `axbills`@localhost IDENTIFIED BY "sqlpassword";  
  CREATE DATABASE axbills DEFAULT CHARACTER SET utf8 COLLATE  utf8_general_ci;
  quit;

Загружаем таблицы в базу. \\

  # cd /usr/axbills/db/
  # mysql --default-character-set=utf8 -D axbills < axbills.sql

=====Web Server=====

===Apache===
 [[http://www.apache.org|Apache]]\\
 Веб-сервер должен быть собран  с поддержкой ''mod_rewrite''\\

  # ./configure --prefix=/usr/local/apache --enable-rewrite=shared
  # make
  # make install

Если используем SSL (https), создаём сертификаты. Apache должен быть собран с mod_ssl.

  # /usr/axbills/misc/certs_create.sh apache

Включаем ** axbills/misc/apache/axbills_httpd.conf ** в конфигурационный файл apache\\

2.2\\
  cp /usr/axbills/misc/apache/axbills_httpd.conf /..ваш путь../Includes/
2.4\\
  cp /usr/axbills/misc/apache/axbills_httpd.conf /..ваш путь../sites-enabled/
  
создаём каталог для логов
  touch /var/log/httpd/

=====Perl modules=====
Для работы системы нужны модули.\\

| **DBI**        |                           |
| **DBD-mysql** |                           |
| **Digest-MD5** | для Chap авторизации      |
| **Digest-MD4** | для MS-Chap авторизации   |
| **Crypt-DES**  | для MS-Chap авторизации   |
| **Digest-SHA1**| для MS-ChapV2 авторизации |
| **libnet**     | Нужен только при авторизации из UNIX passwd |
| **Time-HiRes** | Нужен только для тестирования скорости выполнения авторизации, аккаунтинга, и страниц веб-интерфейса |
| **XML-Simple** | Для работы с определёнными платёжными системами модуля Paysys |
| **PDF-API2**   | Для генерации документов в формате PDF c помощью модуля Docs |
| **RRD-Simple** | Для генерации графиков загрузки с помощью скрипта graphics.cgi |

Эти модули можно загрузить с сайта [http://www.cpan.org] или установка с консоли.

  # cd /root 
  # perl -MCPAN -e shell 
  o conf prerequisites_policy ask 
  install    DBI      
  install    DBD::mysql    
  install    Digest::MD5 
  install    Digest::MD4 
  install    Crypt::DES 
  install    Digest::SHA1 
  install    Bundle::libnet 
  install    Time::HiRes 
  install    XML::Simple
  install    PDF::API2
  install    RRD::Simple
  quit 


=====Radius=====
В данной документации описана настройка ''exec'' версии работы биллинга с радиусом, если у Вас больше 500 абонентов просьба пользоваться ''rlm_perl'' конфигурацией 
\\
\\

Загрузить пакет FreeRadius можно по адресу [http://www.freeradius.org]

  # tar zxvf freeradius-1.1.0.tar.gz
  # cd freeradius-1.1.0
  # ./configure --prefix=/usr/local/radiusd/
  # make
  # make install



копируем файлы с настройками:\\

  # cp /usr/axbills/misc/freeradius/v2/radiusd.conf /usr/local/freeradius/etc/raddb/radiusd.conf
  # rm /usr/local/freeradius/etc/raddb/sites-enabled/*
  # cp /usr/axbills/misc/freeradius/v2/users_perl /usr/local/freeradius/etc/raddb/users
  # cp /usr/axbills/misc/freeradius/v2/default_rlm_perl /usr/local/freeradius/etc/raddb/sites-enabled/axbills_default
  # cp /usr/axbills/misc/freeradius/v2/perl /usr/local/freeradius/etc/raddb/modules/
  # ln -s /usr/local/freeradius/sbin/radiusd /usr/sbin/radiusd
  
  
для автоматического запуска радиуса в FreeBSD внести изменения в **/etc/rc.conf** добавить \\
Код:
   radiusd_enable="YES"


=====AXbills - Настройка=====

Вносим в ''cron'' периодические процессы

**billd**    - контролер активных сессий \\
**periodic** - дневные и месячные периодические процессы \\


**/etc/crontab**

<code>
 */5  *      *    *     *   root   /usr/axbills/libexec/billd -all
 1     0     *    *     *   root    /usr/axbills/libexec/periodic daily
 1     1     *    *     *   root    /usr/axbills/libexec/periodic monthly
</code>
\\



Установить права на чтение и запись вебсервером для файлов веб интерфейса \\

  # mkdir /usr/axbills/var/ /usr/axbills/var/log /usr/axbills/backup
  # chown -Rf www /usr/axbills/cgi-bin
  # chown -Rf www /usr/axbills/AXbills/templates
  # chown -Rf www /usr/axbills/backup

=====Начало работы=====
Веб интерфейс администратора:\\
**https://your.host:9443/admin/**\\
\\
Логин администратора по умолчанию **axbills** пароль **axbills**\\

Если вонзникли проблемы с работой веб интерфейса смотрите лог веб сервера

  /var/log/httpd/axbills-error.log

  


Веб интерфейс для пользователей:\\
**https://your.host:9443/**\\
\\



В интерфейсе администратора прежде всего надо сконфигурировать сервера доступа NAS (Network Access Server). \\
Переходим в меню\\
**System configuration->NAS**\\

**Параметры**
^ IP                     | IP адрес NAS сервера                        |
^ Name                   | Название                                    |
^ Radius NAS-Identifier  | Идентификатор сервера (можно не вписывать) |
^ Describe               | Описание сервера                            |
^ Type                   | Тип сервера.  В зависимости от типа по разному обрабатываются запросЫ на авторизацию |
^ Authorization          | Тип авторизации. \\ **SYSTEM** - При хранении паролей в UNIX базе (/etc/passwd)\\ **SQL** - при хранении паролей SQL базе (MySQL, PosgreSQL)\\  |
^ Alive                  | Период отправки Alive пакетов               |
^ Disable                | Отключить                                   |
^ :Manage:               | Секция менеджмента NAS сервера              |
^ IP:PORT                  | IP адрес и порт для контроля соединения. Например, для отключения пользователя из веб-интерфейса |
^ User                   | Пользователь для контроля                   |
^ Password               | Пароль                                      |
^ RADIUS Parameters      | Дополнительные параметры которые передаются NAS серверу после успешной авторизации.|


После заведения сервера доступа добавте ему пул адресов **IP POOLs**.
^ FIRST IP | Первый адрес в пуле|
^ COUNT    | Количество адресов |
Одному серверу доступа может принадлежать несколько пулов адресов.



Создание тарифного плана\\
Меню\\
**System configuration->Internet->Tarif Plans**\\


Регистрация пользователя\\
**Customers->Users->Add**\\


Заведение сервиса Internet на пользователя.\\
**Customers->Users->Information->Services->Internet**\\



**Проверка**\\
Для проверки правильно ли настроен сервис нужно запустить утилиту radtest указав логин и пароль существующего пользователя. \\ 
Логин: test Пароль: 123456
  # radtest test 123456 127.0.0.1:1812 0 secretpass 0 127.0.0.1

Если всё правильно настроено, в журнале ошибок **/Отчёт/Internet/Ошибка/**  должна появиться строка \\

 
  2005-02-23 12:55:55 LOG_INFO: AUTH [test] NAS: 1 (xxx.xxx.xxx.xxx) GT: 0.03799

Если Вы увидите другие ошибки смотрите в [[axbills:docs:modules:dv:ru#%D0%BE%D1%88%D0%B8%D0%B1%D0%BA%D0%B8|список ошибок]]. Если журнал ошибок пуст значит неправильно настроено взаимодействие с RADIUS сервером.


===Дополнительно===
  * [[axbills:docs:manual:ng_car|FreeBSD ng_car  шейпер]]
  * [[axbills:docs:manual:freebsd_dummynet|FreeBSD Dummynet/table  шейпер]]
  * [[axbills:docs:linux:pppd_radattr:ru|Настройка ОС Linux]]
