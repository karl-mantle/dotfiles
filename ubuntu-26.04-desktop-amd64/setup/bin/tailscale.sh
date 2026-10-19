#!/usr/bin/env bash

setup_tailscale() {
    section_start "Installing Tailscale..."

    if ! command -v tailscale >/dev/null 2>&1; then
        echo "Installing Tailscale..."

        curl -fsSL https://tailscale.com/install.sh | sh
    else
        echo "Tailscale already installed, skipping."
    fi

    if ! tailscale status >/dev/null 2>&1; then
        echo "Connecting to Tailscale, open the login URL and sign in with GitHub..."

        # set TS_AUTHKEY in the environment to skip the browser login
        sudo tailscale up ${TS_AUTHKEY:+--auth-key="$TS_AUTHKEY"}
    else
        echo "Tailscale already connected, skipping."
    fi

    tailscale status
}
