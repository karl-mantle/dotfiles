#!/usr/bin/env bash

setup_ssh() {
    section_start "Setting up GitHub SSH"

    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    # create SSH key if missing
    if [ ! -f "$SSH_KEY_PATH" ]; then
        echo "Creating SSH key..."

        ssh-keygen \
            -t ed25519 \
            -C "$GIT_EMAIL" \
            -f "$SSH_KEY_PATH"
    else
        echo "SSH key already exists, skipping."
    fi

    # configure SSH
    touch "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"

    if ! grep -q "$SSH_KEY_NAME" "$HOME/.ssh/config"; then
        cat >> "$HOME/.ssh/config" <<EOF

Host github.com
    HostName github.com
    User git
    IdentityFile $SSH_KEY_PATH
    AddKeysToAgent yes
EOF
    else
        echo "GitHub SSH config already exists, skipping."
    fi

    # add key to current SSH agent if available
    if [ -n "$SSH_AUTH_SOCK" ]; then
        ssh-add "$SSH_KEY_PATH" 2>/dev/null || true
    else
        echo "No SSH agent detected."
        echo "Ubuntu normally starts one automatically."
    fi

    echo
    echo "Your GitHub SSH public key:"
    echo "--------------------------------"
    cat "${SSH_KEY_PATH}.pub"
    echo "--------------------------------"
    echo
    echo "Add this key to GitHub:"
    echo "https://github.com/settings/keys"
    echo
    echo "Test with:"
    echo "ssh -T git@github.com"
}