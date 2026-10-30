# Health-care file server.
#
# Runs ProFTPD 1.3.5 - an outdated release vulnerable to CVE-2015-3306:
# the mod_copy module exposes the SITE CPFR / SITE CPTO commands, which let a
# remote, UNAUTHENTICATED attacker copy (read/write) arbitrary files on the
# server. Combined with anonymous login this gives unauthorized data access
# and a path to remote code execution.
#
# ProFTPD 1.3.5 (2014) is compiled from source so the behaviour and version
# banner are exactly the vulnerable ones.
FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive

# Pristine, unpatched upstream ProFTPD 1.3.5 source, pinned by content hash on
# Debian's immutable snapshot archive (the base 1.3.5 release is no longer
# published elsewhere; 1.3.5a+ already contain the CVE-2015-3306 fix).
ARG PROFTPD_URL=https://snapshot.debian.org/file/7eef9570efe6c82c47b76163162432b9ba37f81d
ARG PROFTPD_SHA1=7eef9570efe6c82c47b76163162432b9ba37f81d

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        build-essential ca-certificates curl libncurses-dev; \
    rm -rf /var/lib/apt/lists/*

# Build ProFTPD 1.3.5 with mod_copy (contrib module) enabled.
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
    rm -rf /tmp/proftpd.tar.gz /usr/src/proftpd

# Dedicated accounts: 'proftpd' to drop privileges to, 'ftp' for anonymous.
RUN set -eux; \
    useradd --system --no-create-home --shell /usr/sbin/nologin proftpd || true; \
    useradd --home-dir /srv/ftp --shell /usr/sbin/nologin ftp || true; \
    mkdir -p /srv/ftp /var/run/proftpd

# Service configuration and the published file share.
COPY proftpd.conf /etc/proftpd/proftpd.conf
COPY ftproot/ /srv/ftp/

# Writable by the anonymous 'ftp' user (enables the SITE CPTO demo and the
# "temporary upload" misconfiguration).
RUN set -eux; \
    chown -R ftp:ftp /srv/ftp; \
    chmod -R u+rwX /srv/ftp

EXPOSE 21 30000-30009

# Run in the foreground so Docker manages the process.
CMD ["/usr/local/sbin/proftpd", "--nodaemon", "--config", "/etc/proftpd/proftpd.conf"]
