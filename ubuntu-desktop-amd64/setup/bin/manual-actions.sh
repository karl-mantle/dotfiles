#!/usr/bin/env bash

manual_actions() {
    section_start "Manual action required"


    # post-setup github actions
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