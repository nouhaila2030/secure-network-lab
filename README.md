# Secure Enterprise Network Lab: pfSense, OpenVPN and Suricata

Hands-on security lab (May–June 2026): design, hardening and attack testing of a small enterprise network built with VirtualBox. It combines a pfSense firewall, a client-to-site OpenVPN, a hardened Ubuntu server, a Suricata IDS/IPS and attack simulations from Kali Linux.

> **Scope and safety:** all attacks were run against virtual machines I own, in an isolated lab. Nothing in this repository should be used against systems you do not own or have written permission to test.

## Objectives

- Secure remote access for employees through a VPN
- Protect a critical Linux server
- Detect and react to external attacks
- Supervise security events

## Architecture

```
                        WAN (10.92.93.0/24, bridged)
   ┌─────────────────────┐              ┌─────────────────────┐
   │ Kali Linux          │              │ Windows client      │
   │ ATTACKER            │              │ VPN user            │
   │ 10.92.93.85         │              │ VPN IP: 10.8.0.6    │
   └──────────┬──────────┘              └──────────┬──────────┘
              │ attacks                            │ OpenVPN tunnel
              │ (nmap, hydra, hping3)              │ UDP 1194 (10.8.0.0/24)
              ▼                                    ▼
        ┌───────────────────────────────────────────────────┐
        │ pfSense CE 2.8.1                                  │
        │ WAN: 10.92.93.137            LAN: 192.168.10.1    │
        │ Firewall + NAT | OpenVPN server | Suricata (IPS)  │
        └─────────────────────────┬─────────────────────────┘
                                  │
                       LAN 192.168.10.0/24 (host-only)
                                  │
                       ┌──────────┴──────────┐
                       │ Ubuntu Server 24.04 │
                       │ 192.168.10.10       │
                       │ Apache (80)         │
                       │ SSH (2222, key only)│
                       │ SFTP (chroot)       │
                       └─────────────────────┘
```

| Flow | Path | Status |
|---|---|---|
| Employee to server (HTTP, SSH) | VPN client, pfSense, Ubuntu (80, 2222) | Allowed |
| Direct SSH from the LAN | LAN to Ubuntu 2222 | Blocked |
| Attacker to WAN | Kali to pfSense | Monitored by Suricata |

| Network | Machine | Address |
|---|---|---|
| LAN | pfSense LAN | 192.168.10.1 |
| LAN | Ubuntu Server | 192.168.10.10 |
| VPN | OpenVPN tunnel | 10.8.0.0/24 |
| VPN | Windows client | 10.8.0.6 |
| WAN | pfSense WAN | 10.92.93.137 (DHCP) |
| WAN | Kali Linux | 10.92.93.85 |

VirtualBox network modes: pfSense WAN and the Windows and Kali VMs in bridged mode, pfSense LAN and Ubuntu in host-only mode.

## What was implemented

### 1. OpenVPN on pfSense
- Internal certificate authority (RSA 2048, SHA256, 3650 days), server certificate and a VPN user with a client certificate
- Remote access server: UDP 1194, tunnel network 10.8.0.0/24, access to the LAN 192.168.10.0/24, AES-256-CBC with SHA256 as set in the wizard
- Client profile exported with `openvpn-client-export` and tested from Windows (tunnel up, ping to the Ubuntu server through the VPN)

### 2. Ubuntu server hardening
- System updates, unnecessary services checked (avahi and bluetooth not installed)
- IPv6 disabled and sysctl hardening (`tcp_syncookies`, ICMP redirects disabled)
- UFW: default deny incoming, rules limited to the VPN and LAN networks
- GRUB password (PBKDF2), root account locked
- PAM: password ageing (90 days max), complexity with `pwquality` (minimum length 12), lockout after failed attempts
- SSH: port 2222, root login disabled, password authentication disabled, public key only, 3 attempts maximum
- Services: Apache web server and SFTP restricted to a chroot directory

### 3. Suricata IDS/IPS on pfSense
- Installed on the WAN interface in inline IPS mode with ET Open rules and "Block Offenders" enabled
- Custom rules:

| SID | Detection | Condition |
|---|---|---|
| 9001 | Nmap SYN scan | SYN packets, 20 in 2 s per source |
| 9002 | SSH brute force | packets to port 2222, 5 in 60 s per source |
| 9003 | ICMP flood | 50 ICMP packets in 5 s per source |
| 9004 | SYN scan detection | SYN without ACK, 20 in 2 s per source |

### 4. pfSense firewall rules
- WAN: block inbound ICMP, allow OpenVPN UDP 1194, port forward 2222 to the Ubuntu server, manual block of the attacker IP
- LAN: block direct SSH from the LAN, allow SSH from the VPN network
- OpenVPN: allow HTTP (80) and SSH (2222) from 10.8.0.0/24 to the Ubuntu server

## Attack simulations and results

| Attack (from Kali) | Tool | Result |
|---|---|---|
| SYN scan | `nmap -sS` | Detected by Suricata (custom SID 9004 visible in the alerts) |
| Service detection | `nmap -sV` | Detected (ET SCAN Nmap Scripting Engine User-Agent) |
| SSH brute force | Hydra with rockyou.txt | Detected (SID 9002). Password authentication is disabled, so password guessing cannot succeed |
| ICMP flood | `hping3 --icmp --flood` | About 6.5 million packets sent. **No Suricata alert was generated** (SID 9003), and the pfSense web interface became temporarily unreachable |

## Findings and limitations

This lab is a learning environment, not a production design. Points identified when reviewing the results:

- **ICMP flood not mitigated:** the flood made the pfSense interface unreachable and no alert was raised for the custom ICMP rule. The explanation I considered (inline Netmap processing) was not verified. Rate limiting (pfSense limiters, state limits) and a drop rule would be the next steps to test.
- **SSH exposed on the WAN:** the port forward on 2222 lets the WAN reach the Ubuntu SSH service. This was needed to run the brute-force demonstration. In production, SSH would only be reachable through the VPN, without this port forward.
- **WAN exposure of pfSense:** the Nmap scan showed ports 80 and 443 open on the pfSense WAN address, and the WAN rule set contains permissive rules created for lab access. The administration interface should only be reachable from the LAN or the VPN.
- **Automatic blocking not demonstrated:** "Block Offenders" is enabled, but the attacker IP was blocked with a manual firewall rule.
- **UFW and SSH port:** the UFW rule written for SSH targets port 22 while SSH listens on 2222. The rule must match the SSH port.
- **No central logging:** alerts are only viewed in the pfSense interface. Forwarding them to a SIEM (Splunk or Wazuh) would be a natural extension.

## Skills demonstrated

Network segmentation and firewalling (pfSense), PKI and VPN deployment (OpenVPN), Linux hardening (UFW, PAM, SSH, GRUB, sysctl), IDS/IPS rule writing (Suricata), attack simulation and detection analysis (Nmap, Hydra, hping3), technical documentation.

## Repository structure

```
.
├── README.md
├── configs/                # sshd_config, UFW, sysctl, PAM, GRUB and pfSense rules (text only)
├── suricata/custom.rules   # the four custom rules
└── docs/
    ├── report.pdf          # short sanitized technical report (French)
    └── screenshots/        # sanitized screenshots (optional)
```

No private keys, certificates, `.ovpn` profiles or password hashes are included in this repository.

## Report

Short sanitized technical report (French): [docs/report.pdf](docs/report.pdf)

## Author

**Nouhaila El Hamal** — Engineering student in Information Systems Security.
[LinkedIn](https://www.linkedin.com/in/nouhaila-el-hamal-972805293/) · [GitHub](https://github.com/nouhaila2030)
