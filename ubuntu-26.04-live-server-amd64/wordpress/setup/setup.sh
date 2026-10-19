#!/usr/bin/env bash

set -eo pipefail

export DEBIAN_FRONTEND=noninteractive

SCRIPT_PATH=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_PATH/config.sh"
source "$SCRIPT_PATH/lib/utils.sh"

source "$SCRIPT_PATH/bin/system.sh"
source "$SCRIPT_PATH/bin/packages.sh"
source "$SCRIPT_PATH/bin/authorized-keys.sh"
source "$SCRIPT_PATH/bin/swap.sh"
source "$SCRIPT_PATH/bin/updates.sh"
source "$SCRIPT_PATH/bin/tailscale.sh"
source "$SCRIPT_PATH/bin/firewall.sh"
source "$SCRIPT_PATH/bin/wordpress.sh"
source "$SCRIPT_PATH/bin/fail2ban.sh"
source "$SCRIPT_PATH/bin/ssh.sh"

source "$SCRIPT_PATH/bin/manual-actions.sh"

main() {
    check_sudo

    USERNAME="$SUDO_USER"
    USER_HOME=$(getent passwd "$USERNAME" | cut -d: -f6)

    section_start "Starting karl-mantle/dotfiles/ubuntu-26.04-live-server-amd64/wordpress/setup"

    setup_system
    setup_required_packages
    setup_authorized_keys
    setup_swap
    setup_unattended_upgrades
    setup_tailscale
    setup_firewall
    setup_wordpress_stack
    setup_fail2ban
    setup_ssh_hardening # last in case of above failure

    manual_actions

    echo
    echo "Setup complete!"
}

main "$@"
