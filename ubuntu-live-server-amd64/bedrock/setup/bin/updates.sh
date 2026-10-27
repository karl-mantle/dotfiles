#!/usr/bin/env bash

setup_unattended_upgrades() {
    section_start "Enabling automatic security updates"

    apt install -y unattended-upgrades

    # same result as `dpkg-reconfigure unattended-upgrades` answering yes
    cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

    systemctl enable --now unattended-upgrades
}
