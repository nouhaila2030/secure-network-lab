# pfSense configuration summary

## OpenVPN (VPN > OpenVPN > Servers, created with the wizard)

| Parameter | Value |
|---|---|
| Mode | Remote access (SSL/TLS + user authentication) |
| Interface / protocol / port | WAN / UDP / 1194 |
| Tunnel network | 10.8.0.0/24 |
| Local network | 192.168.10.0/24 |
| Encryption / digest | AES-256-CBC / SHA256 |
| Certificate authority | internal CA, RSA 2048, SHA256, 3650 days |

Client profile exported with the `openvpn-client-export` package. Profiles (`.ovpn`), certificates and keys are not stored in this repository.

## Firewall and NAT rules

| # | Interface | Rule | Purpose |
|---|---|---|---|
| 1 | WAN | Block ICMP (IPv4) | Reduce ping-flood exposure |
| 2 | WAN | Pass UDP to WAN address, port 1194 | Allow OpenVPN connections |
| 3 | WAN | NAT port forward, TCP 2222 to 192.168.10.10 | SSH redirection (see limitation below) |
| 4 | WAN | Block source 10.92.93.85 | Manual block of the attacker after detection |
| 5 | LAN | Block TCP 2222 from any | No direct SSH from the LAN |
| 6 | LAN | Pass TCP 2222 from 10.8.0.0/24 | SSH from the VPN network only |
| 7 | OpenVPN | Pass TCP 80 from 10.8.0.0/24 to 192.168.10.10 | HTTP through the VPN |
| 8 | OpenVPN | Pass TCP 2222 from 10.8.0.0/24 to 192.168.10.10 | SSH through the VPN |

## Review notes

- Rule 3 exposes SSH on the WAN. It was used to run the brute-force demonstration and must not be kept in a production design.
- The WAN rule list in the lab also contained permissive "allow all" rules created for lab access. They should be removed, and the pfSense web interface should only be reachable from the LAN or the VPN.
- Rule 4 is a manual block. Automatic blocking with Suricata "Block Offenders" was enabled but not demonstrated.
