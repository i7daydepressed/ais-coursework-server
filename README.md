# AIS Coursework Server

Курсовая работа по дисциплине «Администрирование информационных систем».

Тема: «Конфигурация Linux-сервера для автоматизации работы IT-отдела учебной организации».

## Назначение проекта

Проект содержит Ansible конфигурацию для автоматизированного развёртывания Linux сервера, на котором запускаются сервисы для автоматизации работы IT отдела учебной организации.

Автоматизируемые процессы:

- обработка заявок пользователей на техническую поддержку;
- учёт компьютерного оборудования и периферии;
- ведение базы знаний с инструкциями и регламентами.

## Состав серверной конфигурации

- GLPI - обработка заявок и учёт оборудования;
- BookStack - база знаний;
- MariaDB - хранение данных прикладных сервисов;
- Docker и Docker Compose - контейнерный запуск сервисов;
- Nginx - reverse proxy для публикации web-интерфейсов;
- Ansible - автоматизация установки и настройки;
- Bash-скрипты - резервное копирование и восстановление.


## Запуск (Ansible)

На серверной виртуальной машине необходимо установить Ansible

```bash
sudo dnf install -y git ansible-core
```

После:

```bash
ansible-playbook -i inventory.ini playbook.yml --ask-become-pass
```

## Проверка состояния сервисов

```bash
sudo docker compose -f /opt/ais-coursework/docker-compose.yml ps
sudo systemctl status nginx --no-pager
sudo nginx -t
sudo firewall-cmd --list-ports
sudo ss -tulpn | grep -E ':80|:81|:8080|:8081'
```

## Доступ к web-интерфейсам

GLPI: http://192.168.56.20

BookStack: http://192.168.56.20:81

## Резервное копирование

```bash
sudo /opt/ais-coursework/scripts/backup.sh
sudo ls -lah /opt/ais-coursework/backups
```

## Восстановление

```bash
LATEST_BACKUP=$(sudo find /opt/ais-coursework/backups -maxdepth 1 -name 'backup_*.tar.gz' -type f | sort | tail -n 1)
sudo /opt/ais-coursework/scripts/restore.sh "$LATEST_BACKUP"
```

После:

```bash
sudo docker compose -f /opt/ais-coursework/docker-compose.yml ps
curl -I http://192.168.56.20
curl -I http://192.168.56.20:81
```
