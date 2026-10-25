#!/usr/bin/env bash

setup_authorized_keys() {
    section_start "Authorizing SSH keys for $USERNAME"

    # add public keys from config.sh
    local user_keys="$USER_HOME/.ssh/authorized_keys"

    install -d -m 700 -o "$USERNAME" -g "$USERNAME" "$USER_HOME/.ssh"
    install -m 600 -o "$USERNAME" -g "$USERNAME" /dev/null "$user_keys.tmp"

    if [ -f "$user_keys" ]; then
        cat "$user_keys" > "$user_keys.tmp"
    fi

    for key in "${SSH_AUTHORIZED_KEYS[@]}"; do
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

    if [ ! -s "$user_keys" ]; then
        echo "No public keys set in config.sh."
        echo "SSH hardening will be skipped until a key is added (see manual actions)."
    fi
}
