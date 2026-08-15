#!/usr/bin/env bash

set -euo pipefail

if [ -f /etc/egm/deploy/env-files/ckan/.env ]; then
  ENV_FILE="/etc/egm/deploy/env-files/ckan/.env"
  BACKUP_DIR="/opt/deploy/backup/ckan"
else
  ENV_FILE="$HOME/ckan-docker/.env"
  BACKUP_DIR="$HOME/backup/ckan"
fi

# Docker env files are plain KEY=VALUE, not shell syntax: values here can
# contain characters ($, `, #, unquoted spaces...) that `source` would
# misinterpret, so pull out only the keys we need instead of sourcing it
env_value() {
  local val
  val=$(grep -m1 -E "^$1=" "$ENV_FILE" | cut -d'=' -f2-)
  val="${val%\"}"; val="${val#\"}"
  val="${val%\'}"; val="${val#\'}"
  printf '%s' "$val"
}

POSTGRES_USER=$(env_value POSTGRES_USER)
CKAN_DB=$(env_value CKAN_DB)
DATASTORE_DB=$(env_value DATASTORE_DB)
CKAN_STORAGE_PATH=$(env_value CKAN_STORAGE_PATH)

if [ -z "$POSTGRES_USER" ] || [ -z "$CKAN_DB" ] || [ -z "$DATASTORE_DB" ]; then
    echo "Could not read POSTGRES_USER/CKAN_DB/DATASTORE_DB from $ENV_FILE! Exiting."
    exit 1
fi

# Number of days of history kept for backups
# 1st argument passed on the command line, 30 by default
DAYS_HISTORY=${1:-30}

mkdir -p "$BACKUP_DIR"
now=$(date +%Y-%m-%d)
echo "Backups will be suffixed with date $now and placed into $BACKUP_DIR"

echo
echo "Performing a backup of PostgreSQL databases (CKAN and DataStore)"

# pg_dump/pg_dumpall must run as the postgres OS user inside the container,
# but the target role is whatever POSTGRES_USER is configured to
docker exec -u postgres ckan-db pg_dump -U "$POSTGRES_USER" -Fc "$CKAN_DB" | gzip -c > /tmp/ckan_db_$now.gz
docker exec -u postgres ckan-db pg_dump -U "$POSTGRES_USER" -Fc "$DATASTORE_DB" | gzip -c > /tmp/ckan_datastore_$now.gz
docker exec -u postgres ckan-db pg_dumpall -U "$POSTGRES_USER" -r | gzip -c > /tmp/ckan_roles_$now.sql.gz

mv /tmp/ckan_db_$now.gz "$BACKUP_DIR"/.
mv /tmp/ckan_datastore_$now.gz "$BACKUP_DIR"/.
mv /tmp/ckan_roles_$now.sql.gz "$BACKUP_DIR"/.

echo
echo "Performing a backup of CKAN file storage (uploaded resources)"

docker run --rm --volumes-from ckan -v "$BACKUP_DIR:/backup" ubuntu tar czf /backup/ckan_storage_$now.tar.gz "${CKAN_STORAGE_PATH:-/var/lib/ckan}"

echo
echo "Deleting backups older than $DAYS_HISTORY days"

find "$BACKUP_DIR" -mtime +$DAYS_HISTORY -delete

echo
echo "Backup terminated!"
