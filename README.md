# The Forgotten Server — Vulnerable Lab

> Ethical Hacking course — intentionally vulnerable target for group-vs-group exercises.
>
> ⚠️ **Only run this on an isolated lab network or a host you control. Never expose it to the public internet.**

A medium-sized hospital left an old server running on its internal network. It
once handled file sharing and administration and has not been maintained in
years. Several services are still up — some fine, some not.

Your job (as the attacking group) is to find the weak services and use them to
gain unauthorized access to the server and its data.

---

## Services

Once started, the following are reachable on the Docker host:

| Service        | Host port             | What it is                                   |
|----------------|-----------------------|----------------------------------------------|
| CPR-Register   | `5432`                | PostgreSQL citizen database                  |
| File server    | `21` (+ `30000-30009`)| FTP server for internal documents            |
| Intranet       | `80`                  | Internal web portal                          |
| Remote admin   | `2222`                | SSH service                                  |

They run as containers on one Docker network, so from the outside they look
like one host exposing several ports.

---

## Requirements

- Docker Engine 20.10+ and the Docker Compose plugin
- Outbound internet access **the first time you build** (the FTP image is
  compiled from upstream source)

## How to run

From this folder:

```bash
# Build the images and start everything (first build takes a few minutes)
docker compose up -d --build

# Check that the containers are healthy
docker compose ps

# Follow logs if you want to watch connections
docker compose logs -f
```

Stop and clean up:

```bash
docker compose down            # stop
docker compose down -v         # stop and wipe the database volume (re-seeds on next start)
```

Find the host IP the other group should target:

```bash
# Linux
hostname -I
# macOS
ipconfig getifaddr en0
```

> **FTP note:** if attackers connect from another machine and passive-mode
> transfers hang, edit `ftp-server/proftpd.conf`, set
> `MasqueradeAddress <DOCKER_HOST_IP>` to the Docker host's LAN IP, and run
> `docker compose up -d --build ftp-server`.

---

## Objectives for the attacking group

You are **not** told how the server is configured — that is the point. Scan it,
fingerprint the services, and work out what is exploitable.

**Primary objectives — capture both flags:**

1. 🚩 **`FLAG{...}` on the server** — gain **remote code execution** on the box
   and read a flag file that is *not* reachable over the network directly. (FTP
   login is locked down — but the FTP software itself is the way in.)
2. 🚩 **`FLAG{...}` in the CPR-Register** — one of the registered citizens has a
   very strange first name. Read the database and find it.

**What you should be able to demonstrate (learning goals):**

- [ ] Discover the open ports and **identify the software and versions** running.
- [ ] Identify **which service is outdated / vulnerable** and which is a decoy.
- [ ] Exploit an **authentication/credential/permission weakness** to get in.
- [ ] Achieve **remote code execution** by chaining the vulnerable service with
      another exposed service on the host.
- [ ] Access the **citizen data** in the database.
- [ ] **Capture the exploit in network traffic** (e.g. Wireshark/tcpdump) and
      explain what an analyst would see. Most of these services send everything
      in clear text — one does not.

**Hints (use only if stuck):**

- Not every open port is a way in. One service is properly locked down — don't
  waste the whole exercise brute-forcing it.
- Version banners matter. Look up the exact version you fingerprint — there is a
  well-known Metasploit module for it.
- A write primitive is only useful if you can reach what you wrote. Notice which
  *other* service shares the filesystem.
- "Weak admin credentials" is not just a cliché.

The full walkthrough / answer key lives in [`SOLUTION.md`](./SOLUTION.md) —
don't open it until you've had a real go (or you're the group grading it).
```
