#!/usr/bin/env bash

check_sudo() {
    if [ "$EUID" -ne 0 ] || [ -z "$SUDO_USER" ] || [ "$SUDO_USER" = "root" ]; then
        echo "**Run this script with sudo: sudo ./setup.sh**"
        exit 1
    fi
}

# run WP-CLI against the site as the user its PHP runs as
wp_site() {
    sudo -u "$SITE_USER" WP_CLI_CACHE_DIR="/var/cache/wp-cli/$SITE_USER" /usr/local/bin/wp --path="$SITE_ROOT" "$@"
}

section_start() {
    echo
    echo "=============================="
    echo "$1"
    echo "=============================="
}
