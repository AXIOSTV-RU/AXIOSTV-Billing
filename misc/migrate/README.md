
## Плагин миграции из сторонних систем в AXbills.

### Для быстрого переноса данных из других систем была разработана программа 2axbills.pl. 
### Программа формирует файл для импорта акаунтов через модуль Cards. 
### Файл импорта загружается через меню Клиенты>Логины>Интернет+>Карточки пополнения. 
### После импорта аккаунты имеют вид заведённых администратором. 
### При положительном балансе деньги ставятся на счёт и делается отметка 'MIGRATION' в журнале платежей, 
### а при отрицательном - снимаются и делается отметка 'MIGRATION' в журнале начислений.


# Опции:
```
  DEFAULT_PASSWORD    - стандартный пароль для пустых полей
  PASSSWD_ENCRYPTION_KEY - ключ шифрования
  EMAIL_CREATE        - создать email аккаунты
  EMAIL_DOMAIN        - AXbills почтовый домен ( подробнее '/ System configuration/ E-MAIL/ Domains/' )
  DEBUG               - Включить debug
  ADDRESS_DELIMITER=  - Addreess delimeter for field 3.ADDRESS_FULL (Address delimiter street_name[delimeter1]build[delimiter2][flat])
                        ADDRESS_DELIMITER="[delimiter1],[delimiter2]"
  SKIP_ERROR_PARAM=1  - Игнорировать ошибки, не снимать абонплату (Add:  SKIP_ERRORS=1  4.DV_SKIP_FEE=1)
  ADD_PARAMS=         - Add ext params with coma delimeter (ADD_PARAMS="1.GID=1000,5.STATUS=5")
  NO_DEPOSIT          - Не переносить депозит
  FROM                - Миграция с:
                          freenibs
                          mabill
                          utm4
                          utm5
                          utm5pg
                          file      - Файл с разделителем табуляция
                          utm5cards - require IMPORT_FILE paraments with utm cards
                          axbills    - экспортирует пользователей с axbills
                          mikbill - get users from mikbill
                            mikbill_deleted - get deleted users from mikbill
                            mikbill_blocked - get blocked users from mikbill
                          nodeny
                          traffpro
                          stargazer    - MySQL DB
                          stargazer_pg - stargazer Postgre DB
                          carbon4
                          carbon5
                          lms
                          lms_nodes (IP, MAC adresses for lms users)
                          odbc
                          nika
  SYNC_DEPOSIT        - Файл для синхронизации депозита ( ./2axbills.pl FROM=file SYNC_DEPOSIT=/usr/deposits )
  IMPORT_FILE=[file]  - Файл импорта с разделителем табуляция или CEL_DELIMITER=...
  CEL_DELIMITER       - Разделитель для файла
  FILE_FIELDS=[list,.]- Список полей в файле (FILE_FIELDS=LOGIN,PASSWORD,3.FIO...)
  TP_MIGRATION=[file] - Файл с тарифными планами. В первом параметре приводится старый ТП, во втором новый
                        Формат:
                         old_tp=axbills_tp_id
  LOGIN2UID           - Convert login to uid for digit logins
  ADD_NAS             - Добавить NAS-сервера из файла. Поля определяются опцией FILE_FIELDS=...
  DB_HOST             - Хост базы данных
  DB_USER             - Пользователь базы данных
  DB_PASSWORD         - Пароль пользователя
  DB_CHARSET          - Кодировка базы данных
  DB_NAME             - Имя базы данных
  DB_PATH             - Путь к файлу БД при импорте с carbon
  HTML                - Показать экспортируемый файл в виде HTML
  win2utf             - Конвертировать данные из win1251 в utf8
  help                - Помощь
```

## Stargazer -> AXbills
```
 ./2axbills.pl FROM=stargazer
```
## Traffpro -> AXbills
```
 ./2axbills.pl FROM=traffpro
```
## Nodeny -> AXbills
```
 ./2axbills.pl FROM=nodeny
```
## Mikbill -> AXbills
```
 ./2axbills.pl FROM=mikbill
 ./2axbills.pl FROM=mikbill_deleted > deleted_users.txt
 ./2axbills.pl FROM=mikbill_blocked > blocked_users.txt
```
## FreeNIBS -> AXbills
```
 ./2axbills.pl FROM=freenibs
```
## Mabill -> AXbills
```
 ./2axbills.pl FROM=mabill
```
## UTM 4 -> AXbills
```
 ./2axbills.pl FROM=utm4
```
## UTM 5 -> AXbills
```
 ./2axbills.pl FROM=utm5
```
## UTM 5 Postgres -> AXbills
```
 ./2axbills.pl FROM=utm5pg
```
## UTM 5 Internet cards
```
 ./2axbills.pl FROM=utm5cards IMPORT_FILE=XML_файл_с_карточками
```
## LMS -> AXbills
```
Перенос логинов, балансов, персональной информации:
 ./2axbills.pl FROM=lms
Перенос IP и MAC адресов:
 ./2axbills.pl FROM=lms_nodes
```
## Carbon Billing 4 (Требуется ODBC драйвер для FireBird - http://www.firebirdsql.org/en/odbc-driver/)
```
 ./2axbills.pl FROM=carbon4 DB_HOST=192.168.0.64 DB_PASSWORD=servicemode > import_logins.txt
```
## Carbon Billing 5 (Требуется ODBC драйвер для FireBird - http://www.firebirdsql.org/en/odbc-driver/)
```
 ./2axbills.pl FROM=carbon5 DB_HOST=192.168.0.64 DB_PASSWORD=servicemode > import_logins.txt
```
## Миграция с файла
```
 ./2axbills.pl  FROM=file  IMPORT_FILE=[название файла] FILE_FIELDS=[последовательность полей разделённых запятой]
Пример:
FROM=file IMPORT_FILE=clients.txt FILE_FIELDS=LOGIN,PASSWORD,3.FIO,3.PHONE,4.TP_ID,4.IP,5.SUM,4.CID > clients_converted.txt
```
## ISBS -> AXbills
```
Перенос логинов, балансов, персональной информации. isbs2axbills.pl
```

Телеграм: https://t.me/AXIOSTV
E-mail: admin@axiostv.ru
