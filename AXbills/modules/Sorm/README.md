# Модуль СОРМ3
### ИС СОРМ 
- НорсиТранс
- МФИ СОФТ - выгрузка идентична, должно работать

## По умолчанию установлен модуль для НорсиТранс!!!
### Как работает! Сначала читаем, потом запускаем !

#### В зависимости от производителя СОРМ делаем следующее:
### МФИ-Софт
#### Копируем нужные файлы из /usr/axbills/misc/sorm/mfi/Sorm в папку /usr/axbills/AXbills/mysql/Sorm
```
cp /usr/axbills/misc/sorm/mfi/Sorm/* /usr/axbills/AXbills/mysql/Sorm
```
### НорсиТранс
#### Копируем нужные файлы из /usr/axbills/misc/sorm/norsi/Sorm в папку /usr/axbills/AXbills/mysql/Sorm
```
cp /usr/axbills/misc/sorm/norsi/Sorm/* /usr/axbills/AXbills/mysql/Sorm
```

#### Создаём путь для архивных записей (сначала прописываем её в config.pl см ниже):
```
mkdir /usr/axbills/var/sorm/Archive/
```

### Создание первичной базы:
#### Применяем изменения в БД (внимание, по умолчанию удаляются существующие таблицы SORM и создаются заново):
```
mysql -D axbills </usr/axbills/db/Sorm.sql
```

### Первый запуск
```
/usr/axbills/libexec/billd sorm TYPE=Fenix START=1
```

#### Работает АВТОМАТИЧЕСКИ!
#### Перед созданием первой выгрузки - рекомендуется изменить время работы плагина billd - all до 10 минут
#### После возвращаем в естественное значение


#  ВНИМАНИЕ! ОТДЕЛЬНЫЙ ЗАПУСК НЕ НУЖЕН! РАБОТАЕТ ОТ billd -all ! 

В **config.pl**:
Включаем модуль:
```
@MODULES = (
             'Sorm'
           );
```
Прописываем параметры: 
```
Добавляем новый аргумент через запятую в параметре $conf{BILLD_PLUGINS} = 'sorm';
$conf{SORM_TIME_OFFSET} = 'Сдвиг до UTC. Например для Москвы -3';
$conf{SORM_ARCHIVE} = 1; Включение архивации выгрузок
$conf{SORM_ARCHIVE_PATH} = '/путь/до/архива/'; # Копия выгрузки на FTP - ПАПКУ СОЗДАЁМ САМИ !!!
$conf{SORM_ISP_ID} = 'Идентификатор провайдера из "Информация по операторам связи и их филалах"';
$conf{SORM_DEFAULT_ZIP} = 'Индекс по умолчанию';
$conf{SORM_COUNTRY} = 'РОССИЙСКАЯ ФЕДЕРАЦИЯ';
$conf{SORM_REGION} = 'Область';
$conf{SORM_ZONE} = 'Район';
$conf{OFFICE_CITY} = 'Город';
$conf{OFFICE_STREET} = 'Улица';
$conf{OFFICE_BUILD} = 'Дом';
$conf{OFFICE_APART} = 'Кв./Офис';
$conf{OFFICE_ZIP} = 'Индекс адреса компании';
```

Параметры для выгрузки в сам СОРМ

```
$conf{SORM_SERVER} = 'Адрес сервера';
$conf{SORM_LOGIN} = 'Логин';
$conf{SORM_PASSWORD} = 'Пароль';
$conf{SORM_ERR_LOGIN} = 'Логи для получения лога ошибок;'
$conf{SORM_ERR_PASSWORD} = 'Пароль для получения лога ошибок';
```

=====================================================================

Телеграм: https://t.me/AXIOSTV
E-mail: admin@axiostv.ru
