#!/usr/bin/env bash

setup_system() {
    section_start "Updating system..."

    apt update
    apt upgrade -y

    if [ -n "$HOSTNAME" ] && [ "$(hostnamectl --static)" != "$HOSTNAME" ]; then
        echo "Setting hostname to $HOSTNAME..."

        hostnamectl set-hostname "$HOSTNAME"
    else
        echo "Hostname unchanged: $(hostnamectl --static)"
    fi
}
