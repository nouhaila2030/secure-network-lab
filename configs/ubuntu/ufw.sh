#!/bin/bash
# UFW firewall rules of the Ubuntu server (lab).
# Reconstructed from the lab report. Check the result with: sudo ufw status verbose

sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH: only from the VPN network.
# The report used port 22, but sshd listens on 2222 (see sshd_config.snippet),
# so the rule must target 2222 to match the real SSH port.
sudo ufw allow from 10.8.0.0/24 to any port 2222 proto tcp

# HTTP: only from the internal LAN
sudo ufw allow from 192.168.10.0/24 to any port 80 proto tcp

sudo ufw enable
