#!/usr/bin/env bash

manual_actions() {
    section_start "Manual action required"

    local tailscale_ip
    tailscale_ip=$(tailscale ip -4)

    # check login before closing this session
    echo
    echo "Check you can log in from a new terminal before closing"
    echo "ssh $USERNAME@$tailscale_ip"

    if [ ! -s "$USER_HOME/.ssh/authorized_keys" ]; then
        echo
        echo "$USERNAME has no SSH key yet. Add your public key to"
        echo "SSH_AUTHORIZED_KEYS in config.sh, then run this script again"
        echo "to finish SSH hardening."
    fi

    if [ -n "$SITE_DOMAIN" ] && [ ! -e "/etc/nginx/sites-enabled/$SITE_DOMAIN" ]; then
        echo
        echo "The site $SITE_DOMAIN was skipped (no certificate). Point its DNS"
        echo "here, then run this script again."
    elif [ -n "$SITE_DOMAIN" ] && ! wordpress_is_installed; then
        echo
        echo "Finish installing WordPress now, before anyone else can:"
        echo "https://$SITE_DOMAIN/wp-admin/install.php"
        echo "Then run this script again to block the installer."
    fi
}
