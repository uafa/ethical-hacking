#!/bin/sh
# Build-time initialisation of the CPR-Register (runs as the postgres user).
set -eux

PGDATA=/var/lib/postgresql/data
PGBIN=/usr/lib/postgresql/13/bin

# Create the cluster.
"$PGBIN/initdb" --encoding=UTF8 --locale=C -D "$PGDATA"

# Listen on all interfaces, and accept TCP logins with cleartext "password"
# auth (intentional: credentials are then visible in a packet capture).
printf "\nlisten_addresses = '*'\n" >> "$PGDATA/postgresql.conf"
printf "host all all 0.0.0.0/0 password\n" >> "$PGDATA/pg_hba.conf"

# Start locally (socket only) just long enough to seed, then stop.
"$PGBIN/pg_ctl" -D "$PGDATA" -o "-c listen_addresses=''" -w start

psql -v ON_ERROR_STOP=1 --command "CREATE USER admin WITH SUPERUSER PASSWORD '123456';"

# Seed the default "postgres" database so any connection sees the data.
psql -v ON_ERROR_STOP=1 -d postgres -f /tmp/cpr-init/01-schema.sql
psql -v ON_ERROR_STOP=1 -d postgres -f /tmp/cpr-init/02-seed.sql

"$PGBIN/pg_ctl" -D "$PGDATA" -m fast -w stop
