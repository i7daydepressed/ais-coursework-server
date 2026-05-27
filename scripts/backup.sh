#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/ais-coursework"
BACKUP_ROOT="${APP_DIR}/backups"
DATE_TAG="$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP_NAME="backup_${DATE_TAG}"
WORKDIR="${BACKUP_ROOT}/${BACKUP_NAME}"
ARCHIVE_PATH="${BACKUP_ROOT}/${BACKUP_NAME}.tar.gz"

ENV_FILE="${APP_DIR}/.env"

if [ ! -f "${ENV_FILE}" ]; then
  echo "ERROR: .env file not found: ${ENV_FILE}"
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

mkdir -p "${WORKDIR}/db"
mkdir -p "${WORKDIR}/files"
mkdir -p "${WORKDIR}/config"
mkdir -p "${WORKDIR}/meta"

dump_db() {
  local container_name="$1"
  local db_user="$2"
  local db_password="$3"
  local db_name="$4"
  local output_file="$5"

  docker exec \
    -e DB_USER="${db_user}" \
    -e DB_PASSWORD="${db_password}" \
    -e DB_NAME="${db_name}" \
    "${container_name}" \
    sh -c '
      if command -v mariadb-dump >/dev/null 2>&1; then
        DUMP_TOOL="mariadb-dump"
      else
        DUMP_TOOL="mysqldump"
      fi

      "$DUMP_TOOL" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME"
    ' > "${output_file}"
}

echo "Creating backup: ${BACKUP_NAME}"

echo "Dumping GLPI database..."
dump_db "ais-glpi-db" "${GLPI_DB_USER}" "${GLPI_DB_PASSWORD}" "${GLPI_DB_NAME}" "${WORKDIR}/db/glpi.sql"

echo "Dumping BookStack database..."
dump_db "ais-bookstack-db" "${BOOKSTACK_DB_USERNAME}" "${BOOKSTACK_DB_PASSWORD}" "${BOOKSTACK_DB_DATABASE}" "${WORKDIR}/db/bookstack.sql"

echo "Archiving application files..."
tar -czf "${WORKDIR}/files/glpi_data.tar.gz" -C "${APP_DIR}/data" glpi
tar -czf "${WORKDIR}/files/bookstack_data.tar.gz" -C "${APP_DIR}/data" bookstack

echo "Saving configuration files..."
cp "${APP_DIR}/docker-compose.yml" "${WORKDIR}/config/docker-compose.yml"
cp "${APP_DIR}/.env" "${WORKDIR}/config/.env"
cp "${APP_DIR}/.env.example" "${WORKDIR}/config/.env.example"

if [ -f "/etc/nginx/conf.d/ais-coursework.conf" ]; then
  cp "/etc/nginx/conf.d/ais-coursework.conf" "${WORKDIR}/config/nginx-ais-coursework.conf"
fi

if [ -d "${APP_DIR}/scripts" ]; then
  cp -a "${APP_DIR}/scripts" "${WORKDIR}/config/scripts"
fi

echo "Saving metadata..."
date > "${WORKDIR}/meta/created_at.txt"
docker compose -f "${APP_DIR}/docker-compose.yml" ps > "${WORKDIR}/meta/docker_compose_ps.txt"
du -sh "${APP_DIR}/data" > "${WORKDIR}/meta/data_size.txt" || true

echo "Creating final archive..."
tar -czf "${ARCHIVE_PATH}" -C "${BACKUP_ROOT}" "${BACKUP_NAME}"

rm -rf "${WORKDIR}"

echo "Backup created successfully:"
echo "${ARCHIVE_PATH}"
ls -lh "${ARCHIVE_PATH}"
