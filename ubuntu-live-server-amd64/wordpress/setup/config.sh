#!/usr/bin/env bash

# system
DEVICE_HOSTNAME=""  # leave empty to keep the current hostname

# swapfile
SWAP_FILE="/swapfile"
SWAP_SIZE="2G"
SWAPPINESS=10

# fail2ban (leave email empty to ban without sending mail, most vps block port 25 anyway)
F2B_DESTEMAIL=""
F2B_SENDER=""

# WordPress site (leave empty to skip; the domain's DNS must point here for the certificate)
SITE_DOMAIN=""
SITE_ROOT="/var/www/$SITE_DOMAIN"  # folder containing wp-config.php
SITE_DB_NAME="${SITE_DOMAIN//[^a-zA-Z0-9]/_}"  # e.g. wordpress_karlsblog_dev
SITE_DB_USER="${SITE_DB_NAME:0:32}"  # MySQL user names are at most 32 characters
SITE_USER="${SITE_DB_USER,,}"  # system user the site's PHP runs as and owns its files

# hosts WordPress may make outgoing requests to (WP_ACCESSIBLE_HOSTS), the rest are blocked
SITE_ACCESSIBLE_HOSTS="*.wordpress.org,*.github.com,*.wordfence.com,*.yoast.com"

# plugins installed and activated once WordPress is installed (wordpress.org slugs)
SITE_PLUGINS=(
    disable-xml-rpc
    wordfence
    wordpress-seo
)

# security.txt contact, e.g. "mailto:security@example.com" (leave empty to skip)
SECURITY_CONTACT=""

# daily database backup, then core, plugin and theme updates
BACKUP_DIR="/var/backups/wordpress"
BACKUP_KEEP_DAYS=14

# Cloudflare: true if the DNS record is proxied (orange cloud)
CLOUDFLARE_PROXY=true
# zone ID for fail2ban to ban at Cloudflare; the API token is passed when running:
# sudo CF_API_TOKEN=... ./setup.sh (never commit it)
CF_ZONE_ID=""

# authorized_keys (can SSH in)
SSH_AUTHORIZED_KEYS=(
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEbn2jv0T7gRSqqnCtIcoo4Zc7/hjVKU+Xtp6LfmdHio laptop-lenovo"
)
