.RECIPEPREFIX := >
SERVER_IP ?= $(shell ./scripts/detect_ip.sh)

.PHONY: syntax start status info backup restore devtools

syntax:
> ansible-playbook -i inventory.ini playbook.yml --syntax-check -e "server_ip=$(SERVER_IP)"

start:
> @echo "Detected server IP: $(SERVER_IP)"
> ansible-playbook -i inventory.ini playbook.yml --ask-become-pass -e "server_ip=$(SERVER_IP)"
> @./scripts/show_info.sh "$(SERVER_IP)"

status:
> sudo docker compose -f /opt/ais-coursework/docker-compose.yml ps
> sudo systemctl status nginx --no-pager
> sudo nginx -t
> sudo firewall-cmd --list-ports
> sudo ss -tulpn | grep -E ':80|:81|:8080|:8081' || true
> curl -I http://$(SERVER_IP)
> curl -I http://$(SERVER_IP):81

info:
> @./scripts/show_info.sh "$(SERVER_IP)"

backup:
> sudo /opt/ais-coursework/scripts/backup.sh

restore:
> @LATEST_BACKUP=$$(sudo find /opt/ais-coursework/backups -maxdepth 1 -name 'backup_*.tar.gz' -type f | sort | tail -n 1); \
> echo "Using backup: $$LATEST_BACKUP"; \
> sudo /opt/ais-coursework/scripts/restore.sh "$$LATEST_BACKUP"

