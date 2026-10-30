# Intranet web server (Apache + PHP) for the Compose lab.
# Shares its DocumentRoot (/var/www/html) with the FTP container via a named
# volume, so the unauthenticated ProFTPD mod_copy process can drop a PHP
# payload that Apache executes -> CVE-2015-3306 remote code execution.
FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive

# Pin apt to a frozen snapshot (consistent/reproducible; works around mirrors).
ARG SNAPSHOT=20260901T000000Z
RUN set -eux; \
    { \
      echo "deb http://snapshot.debian.org/archive/debian/${SNAPSHOT}/ bullseye main"; \
      echo "deb http://snapshot.debian.org/archive/debian-security/${SNAPSHOT}/ bullseye-security main"; \
      echo "deb http://snapshot.debian.org/archive/debian/${SNAPSHOT}/ bullseye-updates main"; \
    } > /etc/apt/sources.list; \
    printf 'Acquire::Check-Valid-Until "false";\nAcquire::Retries "5";\n' > /etc/apt/apt.conf.d/80-snapshot; \
    apt-get update; \
    apt-get install -y --no-install-recommends apache2 libapache2-mod-php; \
    rm -rf /var/lib/apt/lists/*

# index.html is baked aside and copied into the shared volume at start; the
# flag lives OUTSIDE the document root (readable by www-data, not by HTTP).
COPY index.html /opt/web/index.html
COPY flag.txt /var/www/flag.txt
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN set -eux; chmod +x /usr/local/bin/entrypoint.sh; chmod 644 /var/www/flag.txt

EXPOSE 80
CMD ["/usr/local/bin/entrypoint.sh"]
