#!/usr/bin/env bash

setup_required_packages() {
    section_start "Installing base packages"

    PACKAGES=(
        btop
        ca-certificates
        curl
        fail2ban
        git
        gnupg
        jq
        nano
        net-tools
        nginx
        software-properties-common
        tree
        ufw
        unzip
        vim
        wget
        zip
    )

    apt install -y "${PACKAGES[@]}"
}
