#!/bin/bash
# 009_id_and_nocodb_databases.sh
#
# Two additional databases join the instance:
#
#   id_db      — identity data owned by the `id` app (users, identities,
#                revocable SSO sessions, handoff codes). Schema follows in
#                010_id_schema.sql.
#   nocodb_db  — NocoDB's metadata store. NocoDB manages its own schema; the
#                oAuthConfig settings table that id and the other apps read
#                lives inside NocoDB.
#
# A .sh init script (rather than .sql) because the app user's name comes from
# the environment. Runs only on first initialisation of an empty datadir —
# for an existing deployment run the statements manually.

set -euo pipefail

mysql -uroot -p"${MYSQL_ROOT_PASSWORD}" <<SQL
CREATE DATABASE IF NOT EXISTS id_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE DATABASE IF NOT EXISTS nocodb_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;

GRANT ALL PRIVILEGES ON id_db.*     TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON nocodb_db.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL
