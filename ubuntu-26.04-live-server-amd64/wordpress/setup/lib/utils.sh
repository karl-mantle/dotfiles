#!/usr/bin/env bash

check_sudo() {
    if [ "$EUID" -ne 0 ] || [ -z "$SUDO_USER" ] || [ "$SUDO_USER" = "root" ]; then
        echo "**Run this script with sudo: sudo ./setup.sh**"
        exit 1
    fi
}

section_start() {
    echo
    echo "=============================="
    echo "$1"
    echo "=============================="
}
