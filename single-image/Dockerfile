# =============================================================================
# The Forgotten Server - ALL-IN-ONE single image
#
# One container that runs all three services together (via supervisord):
#   - PostgreSQL 13   (CPR-Register, admin/123456)           -> port 5432
#   - ProFTPD 1.3.5   (CVE-2015-3306 mod_copy + anon login)  -> port 21 (+30000-30009)
#   - OpenSSH         (hardened decoy)                        -> port 22
#
# The database is initialised and seeded AT BUILD TIME, so the resulting image
# is fully self-contained and deterministic - ideal for shipping as a .tar.
#
# BUILD FROM THE REPO ROOT (so the existing config/seed files are in context):
#   docker build -f single-image/Dockerfile -t forgotten-server:latest .
# =============================================================================
FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PGDATA=/var/lib/postgresql/data \
    PGBIN=/usr/lib/postgresql/13/bin

# Pinned, unpatched upstream ProFTPD 1.3.5 (see ftp-server/Dockerfile for notes).
ARG PROFTPD_URL=https://snapshot.debian.org/file/7eef9570efe6c82c47b76163162432b9ba37f81d
ARG PROFTPD_SHA1=7eef9570efe6c82c47b76163162432b9ba37f81d

# ---------------------------------------------------------------------------
# Packages: database, ssh, process supervisor, and the toolchain to build FTP.
# ---------------------------------------------------------------------------
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        postgresql-13 \
        openssh-server \
        supervisor \
        build-essential ca-certificates curl libncurses-dev; \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Build ProFTPD 1.3.5 with mod_copy (CVE-2015-3306), then drop the toolchain.
# ---------------------------------------------------------------------------
RUN set -eux; \
    curl -fsSL "${PROFTPD_URL}" -o /tmp/proftpd.tar.gz; \
    echo "${PROFTPD_SHA1}  /tmp/proftpd.tar.gz" | sha1sum -c -; \
    mkdir -p /usr/src/proftpd; \
    tar -xzf /tmp/proftpd.tar.gz -C /usr/src/proftpd --strip-components=1; \
    cd /usr/src/proftpd; \
    ./configure \
        --prefix=/usr/local \
        --sysconfdir=/etc/proftpd \
        --localstatedir=/var/run/proftpd \
        --with-modules=mod_copy; \
    make; \
    make install; \
    cd /; \
    rm -rf /tmp/proftpd.tar.gz /usr/src/proftpd; \
    apt-get purge -y build-essential libncurses-dev curl; \
    apt-get autoremove -y; \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Accounts:
#   proftpd  - privilege-drop target for the FTP daemon
#   ftp      - anonymous FTP user
#   itadmin  - SSH decoy account (password locked -> key-only, no brute force)
# ---------------------------------------------------------------------------
RUN set -eux; \
    useradd --system --no-create-home --shell /usr/sbin/nologin proftpd || true; \
    useradd --home-dir /srv/ftp --shell /usr/sbin/nologin ftp || true; \
    useradd --create-home --shell /bin/bash itadmin; \
    passwd -l itadmin; \
    mkdir -p /srv/ftp /var/run/proftpd /run/sshd

# ---------------------------------------------------------------------------
# FTP: config + published hospital file share (incl. flag.txt).
# ---------------------------------------------------------------------------
COPY ftp-server/proftpd.conf /etc/proftpd/proftpd.conf
COPY ftp-server/ftproot/ /srv/ftp/
RUN set -eux; \
    chown -R ftp:ftp /srv/ftp; \
    chmod -R u+rwX /srv/ftp

# ---------------------------------------------------------------------------
# SSH: hardened config (host keys are generated on first start by supervisord).
# ---------------------------------------------------------------------------
COPY ssh-decoy/sshd_config /etc/ssh/sshd_config

# ---------------------------------------------------------------------------
# PostgreSQL: initialise the cluster and seed the CPR-Register at build time.
#   - admin / 123456 (SUPERUSER)
#   - cleartext "password" auth over TCP so credentials are visible in a pcap
#     (intentional, for the network-traffic learning goal)
# ---------------------------------------------------------------------------
COPY cpr-register/init/ /tmp/cpr-init/
COPY single-image/pg-init.sh /tmp/pg-init.sh
RUN set -eux; \
    mkdir -p "$PGDATA"; \
    chown -R postgres:postgres /var/lib/postgresql; \
    su postgres -c "sh /tmp/pg-init.sh"; \
    rm -rf /tmp/cpr-init /tmp/pg-init.sh

# ---------------------------------------------------------------------------
# Run everything under supervisord.
# ---------------------------------------------------------------------------
COPY single-image/supervisord.conf /etc/supervisor/conf.d/forgotten.conf

EXPOSE 21 22 5432 30000-30009

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]
