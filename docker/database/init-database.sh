#!/usr/bin/env bash
set -Eeuo pipefail

readonly SQLCMD="/opt/mssql-tools18/bin/sqlcmd"
readonly SERVER="database"
readonly DATABASE_NAME="${DB_DATABASE:-BITSAC}"
readonly BACKUP_FILE="${DB_BACKUP_FILE:-BITSAC2}"
readonly BACKUP_PATH="/var/opt/mssql/backup/${BACKUP_FILE}"

if [[ ! "${DATABASE_NAME}" =~ ^[A-Za-z0-9_]+$ ]]; then
  echo "DB_DATABASE contiene caracteres no permitidos." >&2
  exit 1
fi

if [[ ! "${BACKUP_FILE}" =~ ^[A-Za-z0-9._-]+$ ]]; then
  echo "DB_BACKUP_FILE contiene caracteres no permitidos." >&2
  exit 1
fi

if [[ ! -f "${BACKUP_PATH}" ]]; then
  echo "No se encontró el respaldo ${BACKUP_PATH}." >&2
  exit 1
fi

export SQLCMDPASSWORD="${MSSQL_SA_PASSWORD}"

for attempt in $(seq 1 60); do
  if "${SQLCMD}" -S "${SERVER}" -U sa -C -Q "SELECT 1" -b -o /dev/null; then
    break
  fi

  if [[ "${attempt}" -eq 60 ]]; then
    echo "SQL Server no estuvo disponible dentro del tiempo esperado." >&2
    exit 1
  fi

  sleep 2
done

"${SQLCMD}" \
  -S "${SERVER}" \
  -U sa \
  -C \
  -b \
  -i /docker-entrypoint-initdb.d/restore-database.sql \
  -v DatabaseName="${DATABASE_NAME}" BackupPath="${BACKUP_PATH}"

echo "Base ${DATABASE_NAME} restaurada y verificada correctamente."
