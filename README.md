# AIS Coursework Server

Курсовая работа по дисциплине «Администрирование информационных систем».

Тема: «Конфигурация Linux-сервера для автоматизации работы IT-отдела учебной организации».

## Назначение проекта

Проект содержит Ansible конфигурацию для автоматизированного развёртывания Linux сервера, на котором запускаются сервисы для автоматизации работы IT отдела учебной организации.

Автоматизируемые процессы:

- обработка заявок пользователей на техническую поддержку;
- учёт компьютерного оборудования и периферии;
- ведение базы знаний с инструкциями и регламентами.

---

## Состав серверной конфигурации

- GLPI - обработка заявок и учёт оборудования;
- BookStack - база знаний;
- MariaDB - хранение данных прикладных сервисов;
- Docker и Docker Compose - контейнерный запуск сервисов;
- Nginx - reverse proxy для публикации web-интерфейсов;
- Ansible - автоматизация установки и настройки;
- Bash-скрипты - резервное копирование и восстановление.

---

## Запуск (Make-pipeline, clone, download)

На серверной виртуальной машине необходимо установить Ansible, git, Make

```bash
sudo dnf install -y git ansible-core make
```

После клонируем:

```bash
git clone https://github.com/i7daydepressed/ais-coursework-server.git
cd ais-coursework-server
```

Проверить синтаксис Ansible playbook:

```bash
make syntax
```

Запустить развертывание:

```bash
make start
```

Команда make start автоматически определяет IP-адрес текущей VM, передаёт его в Ansible через файл с переменными окружения и после завершения выводит справочную информацию с адресами сервисов и полезными командами проверки.

---

## Основные мейк команды

Проверка синтаксиса Ansible playbook

```bash
make syntax
```

Запуск полного развертывания серверной конфигурации

```bash 
make start 
```

Проверка состояния контейнеров, nginx, firewall, портов и http доступности сервисов

```bash
make status
```

Вывод справки с адресами web интерфейсов и командами обслуживания

```bash
make info
```

Создание резервной копии серверной конфигурации

```bash
make backup
```

Восстановление из последней найденной резервной копии.

```bash
make restore
```

---

## Доступ к web интерфейсам

После успешного выполнения make start адреса будут выведены автоматически.

```bash
make info
```

GLPI: http://-

BookStack: http://-

Узнать IP вручную можно так:

```bash
./scripts/detect_ip.sh
```

## Проверка состояния сервисов

Полная проверка:

```bash
make status 
```

Ручная проверка:

```bash
sudo docker compose -f /opt/ais-coursework/docker-compose.yml ps sudo systemctl status nginx --no-pager sudo nginx -t sudo firewall-cmd --list-ports sudo ss -tulpn | grep -E ':80|:81|:8080|:8081' 
```

Ожидаемая логика портов:

text 0.0.0.0:80 -> Nginx -> GLPI 0.0.0.0:81 -> Nginx -> BookStack 127.0.0.1:8080  -> GLPI container 127.0.0.1:8081  -> BookStack container 

---

## Резервное копирование

Создать резервную копию:

```bash
make backup 
```

Или вручную:

```bash
sudo /opt/ais-coursework/scripts/backup.sh 
```

Проверить архивы:

```bash
sudo ls -lah /opt/ais-coursework/backups 
```

Резервная копия включает:

- дамп базы данных GLPI
- дамп базы данных BookStack
- файлы данных GLPI
- файлы данных BookStack
- docker-compose.yml
- .env
- конфигурацию nginx
- backup/restore-скрипты
- служебную мета информацию

---

## Восстановление

Восстановить последнюю резервную копию:

```bash
make restore 
```

Или вручную:

```bash
LATEST_BACKUP=$(sudo find /opt/ais-coursework/backups -maxdepth 1 -name 'backup_*.tar.gz' -type f | sort | tail -n 1) sudo /opt/ais-coursework/scripts/restore.sh "$LATEST_BACKUP" 
```

После восстановления:

```bash
make status 
```

---

## Роли Ansible

- common — установка базовых пакетов, настройка firewalld, создание рабочих каталогов
- docker — установка Docker Engine и Docker Compose plugin
- services — развёртывание GLPI, BookStack и MariaDB через Docker Compose
- reverse_proxy — установка и настройка nginx reverse proxy
- backup — установка backup/restore скриптов

---
