#!/usr/bin/env bash

check_sudo() {
    if [ "$EUID" -eq 0 ]; then
        echo "**Do not run this script as root/with sudo.**"
        echo "It's configured to the home directory and will prompt for sudo when needed."
        exit 1
    fi
}

section_start() {
    echo
    echo "=============================="
    echo "$1"
    echo "=============================="
}