# AXIOSTV Billing System

Это версия биллинга с полным функционалом для Интернета, ТВ, телефона, видеонаблюдения и видеодомофонов с открытым исходным кодом.

Включает в себя функционал добавления ключей Mifare в договор абонента.

В новой версии значительно улучшен функционал компании. Теперь любой договор можно с физического лица переключить на компанию и наоборот, включив соотвествующее и заполнив необходимые реквизиты.

В эту версию не входят коммерческие модули, разработанные по заказу клиентов, 
направленные на ускорение работы с большой абонентской базой, так как они написаны на языке Go и поставляются в скомпилированном виде.

Если Вы заинтересованы во внедрении полного комплекса, обращайтесь admin@axiostv.ru


Распаковываем архив в папку /usr/axbills
Далее выставляем права:

#chmod -R 755 /usr/axbills

#chown -R root:root /usr/axbills

#mkdir /usr/axbills/backup

#mkdir /usr/axbills/var

#chown -R nginx:root /usr/axbills/backup

#chown -R nginx:root /usr/axbills/var

#chown -R nginx:root /usr/axbills/AXbills/templates

Устанавливаем необходимые пакеты:

MySQL или MariaDB, nginx, fcgiwrap

Подключимся к mysql серверу:

#mysql --default-character-set=utf8 -u root -p

Создадим пользователя и базу данных (где sqlpassword — укажем свой пароль):

#use mysql;

#GRANT ALL ON axbills.* TO `axbills`@localhost IDENTIFIED BY "sqlpassword";

#CREATE DATABASE axbills DEFAULT CHARACTER SET utf8 COLLATE  utf8_general_ci;

#flush privileges;

#quit

Данные

Импортируем данные mysql базы данных:

mysql --default-character-set=utf8 -u root -p -D axbills < /usr/axbills/db/axbills.sql

Установим необходимые perl модули:

cd /usr/axbills/misc/

./perldeps.pl rpm

На вопрос Would you like us to update it for you? (y/N)? отвечаем - n

Далее добиваемся установки всех зависимостей (зависит от дистрибутива). Для наших клиентов есть отдельный репозиторий, где собрано все необходимое.

После этого установку можно считать законченной. Переходим к настройке. Необходимо настроить nginx на роботу в связке с fcgiwrap, настроить доменное имя и перевести на доступ по https 

Конфиг nginx:

server {
        listen       80;
        server_name  billing.ru; # домен Вашего биллинга

        location /.well-known {
        root /www;
        }

        location / {
        return 301 https://billing.ru:443$request_uri; # домен Вашего биллинга

        }

}

server {

      listen 443 ssl;

      server_name  billing.ru; # домен Вашего биллинга

      root /usr/axbills/cgi-bin;
      index index.cgi;
      charset utf-8;

      access_log      /var/log/nginx/bll-access.log;
      error_log       /var/log/nginx/bll-error.log warn;

      ssl_certificate       /etc/letsencrypt/live/billing.ru/fullchain.pem; # Путь до файла

      ssl_certificate_key   /etc/letsencrypt/live/billing.ru/privkey.pem; # Путь до файла

      ssl_session_timeout  5m;

      ssl_protocols TLSv1.2 SSLv3 TLSv1.1;
      ssl_ciphers  ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP:+eNULL;
      ssl_prefer_server_ciphers   off;

    location ^~ /images/ {
        alias /usr/axbills/AXbills/templates/;
        location ~* \.(jpg|gif|png|css|js|JPG|GIF)$ {
          allow all;
        }
        deny all;
    }

    location ~ \.cgi {
        try_files $uri =404;
        gzip off;
        fastcgi_param HTTPS on;
        fastcgi_pass unix:/run/fcgiwrap.sock;
        fastcgi_index index.cgi;
        fastcgi_param HTTP_CGI_AUTHORIZATION $http_authorization;
        fastcgi_param SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

}

После этих настрое админ интерфейс будет доступен по адресу https:/billing.ru/admin # домен Вашего биллинга

стандартный логин — axbills, пароль — axbills

Клиентский интерфейс будет доступен по адресу https:/billing.ru # домен Вашего биллинга
