#!/usr/bin/env bash

set -eo pipefail

SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_PATH/config.sh"
source "$SCRIPT_PATH/lib/utils.sh"

source "$SCRIPT_PATH/bin/system.sh"
source "$SCRIPT_PATH/bin/packages.sh"
source "$SCRIPT_PATH/bin/tailscale.sh"
source "$SCRIPT_PATH/bin/git.sh"
source "$SCRIPT_PATH/bin/node.sh"
source "$SCRIPT_PATH/bin/ssh.sh"
source "$SCRIPT_PATH/bin/manual-actions.sh"

main() {
    check_sudo
    section_start "Starting karl-mantle/dotfiles/ubuntu-26.04-desktop-amd64/setup"

    setup_system
    setup_required_packages

    setup_tailscale
    setup_git
    setup_nvm
    setup_ssh

    manual_actions

    echo
    echo "Setup complete!"
}

main "$@"