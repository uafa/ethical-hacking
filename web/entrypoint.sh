#!/bin/sh
# Ensure the shared DocumentRoot has the landing page and is world-writable
# (so the FTP container's mod_copy process can drop files into it), then run
# Apache in the foreground. Runs every start, so it is robust regardless of the
# shared volume's initial state.
set -e

mkdir -p /var/www/html
cp /opt/web/index.html /var/www/html/index.html
chmod 777 /var/www/html
chmod 644 /var/www/html/index.html

. /etc/apache2/envvars
exec /usr/sbin/apache2 -DFOREGROUND
