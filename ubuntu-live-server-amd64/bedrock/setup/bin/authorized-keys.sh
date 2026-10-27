#!/usr/bin/env bash

setup_authorized_keys() {
    section_start "Authorizing SSH keys for $USERNAME"

    # add public keys from config.sh
    add_authorized_keys "$USERNAME" "${SSH_AUTHORIZED_KEYS[@]}"

    if [ ! -s "$USER_HOME/.ssh/authorized_keys" ]; then
        echo "No public keys set in config.sh."
        echo "SSH hardening will be skipped until a key is added (see manual actions)."
    fi
}
