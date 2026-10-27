#!/usr/bin/env bash

setup_fail2ban() {
    section_start "Configuring Fail2Ban"

    # email action only works with a mail address set
    local mail_settings=""

    if [ -n "$F2B_DESTEMAIL" ]; then
        mail_settings="destemail = $F2B_DESTEMAIL
sender = ${F2B_SENDER:-fail2ban@$(hostname -f)}
action = %(action_mwl)s"
    fi

    # local override, never edit jail.conf
    cat > /etc/fail2ban/jail.local <<EOF
# Fail2Ban local overrides

[DEFAULT]
# Ban time in seconds (1 hour)
bantime  = 3600
# How many failed attempts before banning
maxretry = 5
# Time window for maxretry (seconds)
findtime = 600
$mail_settings

# ---------------------------------------------
# SSH protection
# ---------------------------------------------
[sshd]
enabled = true
port = ssh
filter = sshd
backend = systemd

# ---------------------------------------------
# Nginx login attempts (admin panels)
# ---------------------------------------------
[nginx-http-auth]
enabled = true
filter = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3
EOF

    # WordPress login attempts (wp-login.php)
    cat > /etc/fail2ban/filter.d/wordpress.conf <<EOF
[Definition]
failregex = <HOST> .* "POST /wp-login\.php
ignoreregex =
EOF

    cat > /etc/fail2ban/jail.d/wordpress.local <<EOF
[wordpress]
enabled  = true
filter   = wordpress
port     = http,https
logpath  = /var/log/nginx/access.log
maxretry = 5
EOF

    setup_fail2ban_cloudflare

    systemctl enable fail2ban
    systemctl restart fail2ban

    # give fail2ban a moment to start before querying it
    sleep 2

    fail2ban-client status
}

setup_fail2ban_cloudflare() {
    local conf=/etc/fail2ban/jail.d/cloudflare.local

    if [ "$CLOUDFLARE_PROXY" != "true" ]; then
        rm -f "$conf"
        return
    fi

    # Behind the proxy, banning an IP on this server doesn't stop it reaching the site
    # through Cloudflare, so WordPress bans are also sent to Cloudflare's firewall.
    if [ -z "$CF_ZONE_ID" ] || [ -z "$CF_API_TOKEN" ]; then
        if [ -f "$conf" ]; then
            echo "Cloudflare ban action already configured, keeping it."
        else
            echo "CF_ZONE_ID or CF_API_TOKEN not set, WordPress bans only apply on this server."
        fi
        return
    fi

    if [ ! -f /etc/fail2ban/action.d/cloudflare-token.conf ]; then
        echo "This fail2ban has no cloudflare-token action, skipping Cloudflare bans."
        return
    fi

    echo "Sending WordPress bans to Cloudflare..."

    # holds the API token, so root only
    install -m 600 /dev/null "$conf"

    cat > "$conf" <<EOF
[wordpress]
action = %(action_)s
         cloudflare-token[cfzone="$CF_ZONE_ID", cftoken="$CF_API_TOKEN"]
EOF
}
