#!/usr/bin/env bash

setup_system() {
    section_start "Updating system..."

    apt update
    apt upgrade -y

    if [ -n "$DEVICE_HOSTNAME" ] && [ "$(hostnamectl --static)" != "$DEVICE_HOSTNAME" ]; then
        echo "Setting hostname to $DEVICE_HOSTNAME..."

        hostnamectl set-hostname "$DEVICE_HOSTNAME"
        # point Ubuntu's 127.0.1.1 entry at the new name, so sudo can resolve it
        sed -i "s/^127\.0\.1\.1\s.*/127.0.1.1\t$DEVICE_HOSTNAME/" /etc/hosts

        # stop cloud-init resetting the hostname and /etc/hosts on boot
        if [ -d /etc/cloud/cloud.cfg.d ]; then
            echo "cloud-init found, preserving hostname across reboots..."

            cat > /etc/cloud/cloud.cfg.d/99-preserve-hostname.cfg <<EOF
preserve_hostname: true
manage_etc_hosts: false
EOF
        fi
    else
        echo "Hostname unchanged: $(hostnamectl --static)"
    fi
}
