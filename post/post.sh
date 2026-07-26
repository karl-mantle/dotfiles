#!/usr/bin/env bash

setup_post_actions() {
    section_start "Actions to take after setup"


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