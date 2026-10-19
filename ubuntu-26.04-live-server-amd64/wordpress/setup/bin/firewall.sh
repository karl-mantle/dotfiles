#!/usr/bin/env bash

setup_firewall() {
    section_start "Configuring firewall"

    # SSH only allowed over Tailscale, must be up before enabling
    if ! tailscale status >/dev/null 2>&1; then
        echo "Cannot enable firewall. Tailscale is not connected."
        echo "Enabling it now would block all SSH access..."
        exit 1
    fi

    ufw allow 'Nginx Full'
    ufw allow in on tailscale0
    ufw --force enable

    echo
    echo "Public SSH is now blocked. This session will stay open."
    echo "Use the Tailscale IP: $(tailscale ip -4)"
    echo

    ufw status verbose
}
