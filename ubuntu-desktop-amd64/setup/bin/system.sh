#!/usr/bin/env bash

setup_system() {
    section_start "Updating system..."

    sudo apt update
    sudo apt upgrade -y

    if [ -n "$DEVICE_HOSTNAME" ] && [ "$(hostnamectl --static)" != "$DEVICE_HOSTNAME" ]; then
        echo "Setting hostname to $DEVICE_HOSTNAME..."

        sudo hostnamectl set-hostname "$DEVICE_HOSTNAME"
        # point Ubuntu's 127.0.1.1 entry at the new name, so sudo can resolve it
        sudo sed -i "s/^127\.0\.1\.1\s.*/127.0.1.1\t$DEVICE_HOSTNAME/" /etc/hosts
    else
        echo "Hostname unchanged: $(hostnamectl --static)"
    fi
}
