#!/usr/bin/env bash

set -eo pipefail

SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_PATH/config.sh"
source "$SCRIPT_PATH/lib/utils.sh"

source "$SCRIPT_PATH/bin/git.sh"
source "$SCRIPT_PATH/bin/node.sh"
source "$SCRIPT_PATH/bin/packages.sh"
source "$SCRIPT_PATH/bin/ssh.sh"

source "$SCRIPT_PATH/bin/post-install.sh"

main() {
    check_sudo
    section_start "Starting karl-mantle/dotfiles/ubuntu-26.04-desktop-amd64/setup"

    setup_required_packages

    setup_git
    setup_ssh

    setup_nvm
    setup_global_node_packages

    setup_post_actions

    echo
    echo "Setup complete!"
}

main "$@"