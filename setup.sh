#!/usr/bin/env bash

set -e

SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_PATH/config.sh"
source "$SCRIPT_PATH/lib/utils.sh"

source "$SCRIPT_PATH/setup/git.sh"
source "$SCRIPT_PATH/setup/languages.sh"
source "$SCRIPT_PATH/setup/ssh.sh"

source "$SCRIPT_PATH/post/post.sh"

main() {
    section_start "Starting dotfiles setup"

    setup_git
    setup_nvm
    setup_ssh

    setup_post_actions

    echo
    echo "Setup complete."
}

main "$@"