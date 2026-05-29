#!/usr/bin/env bash
set -euo pipefail

SERVER_IP="${1:-127.0.0.1}"

cat <<INFO

====================================
 AIS coursework server deployment completed
====================================

Web interfaces:

  GLPI:
    http://${SERVER_IP}

  BookStack:
    http://${SERVER_IP}:81

Useful checks:

  sudo docker compose -f /opt/ais-coursework/docker-compose.yml ps
  sudo systemctl status nginx --no-pager
  sudo nginx -t
  sudo firewall-cmd --list-ports
  curl -I http://${SERVER_IP}
  curl -I http://${SERVER_IP}:81

Backup:

  sudo /opt/ais-coursework/scripts/backup.sh

Restore latest backup:

  LATEST_BACKUP=\$(sudo find /opt/ais-coursework/backups -maxdepth 1 -name 'backup_*.tar.gz' -type f | sort | tail -n 1)
  sudo /opt/ais-coursework/scripts/restore.sh "\$LATEST_BACKUP"

Main git repo: https://github.com/i7daydepressed/ais-coursework-server/tree/main

============================================================

INFO
