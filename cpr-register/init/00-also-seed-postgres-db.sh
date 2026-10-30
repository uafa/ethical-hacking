#!/bin/bash
# The official image runs 01-schema.sql / 02-seed.sql against POSTGRES_DB (cpr).
# This also loads them into the default "postgres" database, so a bare
# connection (many GUI tools default to the "postgres" db) sees the data too
# instead of an empty database. Runs first (00-) but only needs the .sql files
# to exist in this directory, which they do.
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
     -f /docker-entrypoint-initdb.d/01-schema.sql
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres \
     -f /docker-entrypoint-initdb.d/02-seed.sql
