# Плагин ACCIDENT
### Баш скрипт мониторинга NAS серверов
- RC1

### Как работает! Сначала читаем, потом запускаем !

#### config.pl
#### Параметры для скрипта
```
$conf{ACCIDENT_TELEGRAM_BOT}='12345678:KGgbkufjlkjhYfvjhmgFyjhuyjh';   # Токен бота телеги
$conf{ACCIDENT_TELEGRAM_CHAT_ID}='12345678';                           # ID чата, куда слать
$conf{ACCIDENT_MONITOR_IP}='198.18.1.0,198.18.1.1,198.18.1.2';         # Список IP через запятую, какие мониторим

```

### Два режима работы:
#### Проверка ВСЕХ NAS серверов, зарегестрированных в биллинге
```
/usr/axbills/misc/accident/accident_check.sh GET_FROM_DB
```

#### ПРоверка только тех, которые указаны в $conf{ACCIDENT_MONITOR_IP}
```
/usr/axbills/misc/accident/accident_check.sh GET_FROM_CONFIG
```

#### Так как это RC верия, то в крон, желательно, ставить раз в 5 минут
### Мы работаем для ускорения процесса проверки

=====================================================================

Телеграм: https://t.me/AXIOSTV
E-mail: admin@axiostv.ru