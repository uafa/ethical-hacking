# Health-care file server.
#
# Runs ProFTPD 1.3.5 - an outdated release vulnerable to CVE-2015-3306:
# the mod_copy module exposes the SITE CPFR / SITE CPTO commands, which a
# remote, UNAUTHENTICATED attacker can use (before login) to copy (read/write)
# arbitrary files. Because the shared web root is writable by this process, an
# attacker can drop a PHP payload there and execute it via the web container
# -> remote code execution (Metasploit proftpd_modcopy_exec).
#
# ProFTPD 1.3.5 (2014) is compiled from source so the behaviour and version
# banner are exactly the vulnerable ones.
FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive

# Pristine, unpatched upstream ProFTPD 1.3.5 source, pinned by content hash on
# Debian's immutable snapshot archive (the base 1.3.5 release is no longer
# published elsewhere; 1.3.5a+ already contain the CVE-2015-3306 fix). HTTP
# (not HTTPS) avoids TLS-intercepting proxies; the SHA1 check ensures integrity.
ARG PROFTPD_URL=http://snapshot.debian.org/file/7eef9570efe6c82c47b76163162432b9ba37f81d
ARG PROFTPD_SHA1=7eef9570efe6c82c47b76163162432b9ba37f81d

# Pin apt to a frozen snapshot so index and pool stay consistent/reproducible.
ARG SNAPSHOT=20260901T000000Z
RUN set -eux; \
    { \
      echo "deb http://snapshot.debian.org/archive/debian/${SNAPSHOT}/ bullseye main"; \
      echo "deb http://snapshot.debian.org/archive/debian-security/${SNAPSHOT}/ bullseye-security main"; \
      echo "deb http://snapshot.debian.org/archive/debian/${SNAPSHOT}/ bullseye-updates main"; \
    } > /etc/apt/sources.list; \
    printf 'Acquire::Check-Valid-Until "false";\nAcquire::Retries "5";\n' > /etc/apt/apt.conf.d/80-snapshot; \
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

# 'proftpd' is the unprivileged account the daemon drops to.
RUN set -eux; \
    useradd --system --no-create-home --shell /usr/sbin/nologin proftpd || true; \
    mkdir -p /srv/ftp /var/run/proftpd /var/www/html

# Service configuration and some realistic (world-readable) files on disk.
COPY proftpd.conf /etc/proftpd/proftpd.conf
COPY ftproot/ /srv/ftp/
RUN set -eux; chmod -R a+rX /srv/ftp

EXPOSE 21 30000-30009

# Run in the foreground so Docker manages the process.
CMD ["/usr/local/sbin/proftpd", "--nodaemon", "--config", "/etc/proftpd/proftpd.conf"]
