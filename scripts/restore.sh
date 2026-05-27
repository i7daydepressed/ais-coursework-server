#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/ais-coursework"
BACKUP_ARCHIVE="${1:-}"

if [ -z "${BACKUP_ARCHIVE}" ]; then
  echo "Usage: sudo $0 /opt/ais-coursework/backups/backup_YYYY-MM-DD_HH-MM-SS.tar.gz"
  exit 1
fi

if [ ! -f "${BACKUP_ARCHIVE}" ]; then
  echo "ERROR: backup archive not found: ${BACKUP_ARCHIVE}"
  exit 1
fi

RESTORE_TMP="$(mktemp -d)"
trap 'rm -rf "${RESTORE_TMP}"' EXIT

echo "Restoring from archive:"
echo "${BACKUP_ARCHIVE}"

tar -xzf "${BACKUP_ARCHIVE}" -C "${RESTORE_TMP}"

BACKUP_DIR="$(find "${RESTORE_TMP}" -mindepth 1 -maxdepth 1 -type d | head -n 1)"

if [ -z "${BACKUP_DIR}" ]; then
  echo "ERROR: extracted backup directory not found"
  exit 1
fi

echo "Stopping application containers..."
if [ -f "${APP_DIR}/docker-compose.yml" ]; then
  docker compose -f "${APP_DIR}/docker-compose.yml" down
fi

echo "Restoring configuration files..."
cp "${BACKUP_DIR}/config/docker-compose.yml" "${APP_DIR}/docker-compose.yml"

if [ -f "${BACKUP_DIR}/config/.env" ]; then
  cp "${BACKUP_DIR}/config/.env" "${APP_DIR}/.env"
fi

if [ -f "${BACKUP_DIR}/config/.env.example" ]; then
  cp "${BACKUP_DIR}/config/.env.example" "${APP_DIR}/.env.example"
fi

if [ -f "${BACKUP_DIR}/config/nginx-ais-coursework.conf" ]; then
  cp "${BACKUP_DIR}/config/nginx-ais-coursework.conf" "/etc/nginx/conf.d/ais-coursework.conf"
fi

echo "Restoring application files..."
mkdir -p "${APP_DIR}/data"

rm -rf "${APP_DIR}/data/glpi"
rm -rf "${APP_DIR}/data/bookstack"

tar -xzf "${BACKUP_DIR}/files/glpi_data.tar.gz" -C "${APP_DIR}/data"
tar -xzf "${BACKUP_DIR}/files/bookstack_data.tar.gz" -C "${APP_DIR}/data"

chmod -R 0777 "${APP_DIR}/data/glpi" || true
chmod -R 0777 "${APP_DIR}/data/bookstack" || true

echo "Loading environment variables..."
set -a
source "${APP_DIR}/.env"
set +a

echo "Starting database containers..."
docker compose -f "${APP_DIR}/docker-compose.yml" up -d glpi-db bookstack-db

echo "Waiting for databases..."
sleep 20

restore_db() {
  local container_name="$1"
  local db_name="$2"
  local dump_file="$3"

  echo "Restoring database ${db_name} in ${container_name}..."

  docker exec \
    -e DB_NAME="${db_name}" \
    "${container_name}" \
    sh -c '
      mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS \`$DB_NAME\`; CREATE DATABASE \`$DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
    '

  docker exec -i \
    -e DB_NAME="${db_name}" \
    "${container_name}" \
    sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" "$DB_NAME"' < "${dump_file}"
}

restore_db "ais-glpi-db" "${GLPI_DB_NAME}" "${BACKUP_DIR}/db/glpi.sql"
restore_db "ais-bookstack-db" "${BOOKSTACK_DB_DATABASE}" "${BACKUP_DIR}/db/bookstack.sql"

echo "Starting all containers..."
docker compose -f "${APP_DIR}/docker-compose.yml" up -d

echo "Reloading Nginx..."
nginx -t
systemctl reload nginx

echo "Restore completed successfully."
docker compose -f "${APP_DIR}/docker-compose.yml" ps
