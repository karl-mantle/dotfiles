#!/usr/bin/env bash

check_sudo() {
    if [ "$EUID" -ne 0 ] || [ -z "$SUDO_USER" ] || [ "$SUDO_USER" = "root" ]; then
        echo "**Run this script with sudo: sudo ./setup.sh**"
        exit 1
    fi
}

# These run from / because the script runs from inside the admin user's home folder,
# which other users can't read, and git, Composer and WP-CLI fail in a folder they can't read.

# run WP-CLI against the site as the user its PHP runs as (Bedrock keeps core in web/wp)
wp_site() {
    (cd / && sudo -u "$SITE_USER" WP_CLI_CACHE_DIR="/var/cache/wp-cli/$SITE_USER" /usr/local/bin/wp --path="$SITE_WEB_ROOT/wp" "$@")
}

# run a command as the deploy user, who owns the code
as_deploy() {
    (cd / && sudo -u "$DEPLOY_USER" -H "$@")
}

# add keys to a user's authorized_keys, skipping ones already there
# usage: add_authorized_keys <user> <key>...
add_authorized_keys() {
    local user="$1"
    shift

    local home
    home=$(getent passwd "$user" | cut -d: -f6)
    local user_keys="$home/.ssh/authorized_keys"

    install -d -m 700 -o "$user" -g "$user" "$home/.ssh"
    install -m 600 -o "$user" -g "$user" /dev/null "$user_keys.tmp"

    if [ -f "$user_keys" ]; then
        cat "$user_keys" > "$user_keys.tmp"
    fi

    for key in "$@"; do
        if [ -z "$key" ]; then
            continue
        fi

        if grep -qxF "$key" "$user_keys.tmp"; then
            echo "Key already authorized, skipping: ${key:0:40}..."
        else
            echo "Authorizing key: ${key:0:40}..."

            echo "$key" >> "$user_keys.tmp"
        fi
    done

    mv "$user_keys.tmp" "$user_keys"
}

section_start() {
    echo
    echo "=============================="
    echo "$1"
    echo "=============================="
}
