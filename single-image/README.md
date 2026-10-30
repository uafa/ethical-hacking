# The Forgotten Server — all-in-one image

This packages the **same lab** as the Compose setup into **one Docker image**
that runs all three services together (PostgreSQL + ProFTPD 1.3.5 + OpenSSH)
under `supervisord`. The database is seeded at build time, so the image is
fully self-contained — perfect for shipping as a `.tar`.

> ⚠️ Intentionally vulnerable. Run only on an isolated lab network you control.

## 1. Build the image

Run **from the repository root** (the build needs the existing config/seed
files, so the context must be the root, not `single-image/`):

```bash
docker build -f single-image/Dockerfile -t forgotten-server:latest .
```

First build takes a few minutes (it compiles ProFTPD 1.3.5 from source) and
needs internet access.

## 2. Export it as a .tar (to hand to the other group)

```bash
# plain tar
docker save -o forgotten-server.tar forgotten-server:latest

# or compressed (much smaller — recommended)
docker save forgotten-server:latest | gzip > forgotten-server.tar.gz
```

Give them `forgotten-server.tar` (or `.tar.gz`) plus the "Objectives" section
of the top-level [`../README.md`](../README.md). **Do not** send them
`../SOLUTION.md` unless you want the answers spoiled.

## 3. The other group loads and runs it

```bash
# load the image (gzip is auto-detected)
docker load -i forgotten-server.tar          # or: docker load -i forgotten-server.tar.gz

# run it — all services in one container
docker run -d --name forgotten-server \
  -p 21:21 \
  -p 80:80 \
  -p 2222:22 \
  -p 5432:5432 \
  -p 30000-30009:30000-30009 \
  forgotten-server:latest
```

Now reachable on the host:

| Service      | Host port              |
|--------------|------------------------|
| FTP          | `21` (+ `30000-30009`) |
| Intranet (HTTP) | `80`                |
| SSH (decoy)  | `2222`                 |
| PostgreSQL   | `5432`                 |

> SSH is mapped to **2222** so it doesn't clash with a host SSH daemon — change
> the left side of `-p 2222:22` if you prefer another port.
>
> **Passive FTP from another machine:** if downloads hang, the FTP server needs
> to advertise the host's real IP. Either rebuild after setting
> `MasqueradeAddress <HOST_IP>` in `ftp-server/proftpd.conf`, or run with
> `-e` and a wrapper — simplest is to set MasqueradeAddress before `docker save`.

## Manage / reset

```bash
docker logs -f forgotten-server     # watch all services
docker rm -f forgotten-server       # stop & remove

# The data (and flag) are baked into the image, so a fresh `docker run`
# always starts from the same clean, seeded state.
```

## Credentials / flags (same as the Compose lab)

- PostgreSQL: `admin` / `123456`, database `postgres` — one citizen's firstname is a flag.
- FTP: **anonymous login disabled**. ProFTPD 1.3.5 is vulnerable to CVE-2015-3306
  (`mod_copy` `SITE CPFR`/`CPTO`, usable *before* login). The web DocumentRoot
  (`/var/www/html`) is writable by the FTP process, so you can drop a PHP shell
  and execute it over HTTP → RCE (Metasploit `proftpd_modcopy_exec`). The flag
  is at `/var/www/flag.txt`, readable only after you get a shell.
- SSH: hardened decoy (`itadmin`, key-only, no password) — not the way in.

See [`../SOLUTION.md`](../SOLUTION.md) for the full exploit walkthrough.
