# CPR-Register: an old, internal citizen database.
# Weakness: trivial administrator credentials (admin / 123456) and the port is
# left exposed on the network. Anyone who finds it can read every record.
FROM postgres:13

# Seed scripts in /docker-entrypoint-initdb.d are executed automatically the
# first time the database is initialised (empty data directory).
COPY init/ /docker-entrypoint-initdb.d/
