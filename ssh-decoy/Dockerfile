# SSH decoy - the red herring.
#
# This is a correctly configured, up-to-date OpenSSH service. It is here to be
# discovered and attacked, but it is NOT the way in: root login is disabled,
# password auth is off (key-only), and the one account has no usable password.
# Time spent brute-forcing this port is time wasted - the real foothold is FTP.
FROM debian:bullseye-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends openssh-server; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir -p /run/sshd

# A normal-looking admin account. Password login is disabled server-side, and
# the account is locked (no password) so brute force cannot succeed.
RUN set -eux; \
    useradd --create-home --shell /bin/bash itadmin; \
    passwd -l itadmin

COPY sshd_config /etc/ssh/sshd_config

EXPOSE 22

# Host keys are generated on first start if missing, then sshd runs foreground.
CMD ["/bin/sh", "-c", "ssh-keygen -A && exec /usr/sbin/sshd -D -e"]
