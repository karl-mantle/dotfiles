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

# Bedrock site (leave empty to skip; the domain's DNS must point here for the certificate)
SITE_DOMAIN=""
SITE_REPO="git@github.com:karl-mantle/bedrock-karlsblog.git"
SITE_THEME="karlsblog"  # folder in web/app/themes/ with its own composer.json (leave empty if none)
SITE_ROOT="/var/www/$SITE_DOMAIN"  # repo root, containing .env and composer.json
SITE_WEB_ROOT="$SITE_ROOT/web"  # nginx document root
SITE_DB_NAME="${SITE_DOMAIN//[^a-zA-Z0-9]/_}"  # e.g. bedrock_karlsblog_dev
SITE_DB_USER="${SITE_DB_NAME:0:32}"  # MySQL user names are at most 32 characters
SITE_USER="${SITE_DB_USER,,}"  # system user the site's PHP runs as, owns uploads only

# deploy user: owns the code, pulls from GitHub and is what GitHub Actions logs in as (no sudo)
DEPLOY_USER="deploy"
# public keys allowed to SSH in as the deploy user, e.g. the key GitHub Actions uses
DEPLOY_AUTHORIZED_KEYS=(
    ""
)

# security.txt contact, e.g. "mailto:security@example.com" (leave empty to skip)
SECURITY_CONTACT=""

# daily database backup (updates come from Composer through deploys)
BACKUP_DIR="/var/backups/wordpress"
BACKUP_KEEP_DAYS=14

# Cloudflare: true if the DNS record is proxied (orange cloud)
CLOUDFLARE_PROXY=true
# zone ID for fail2ban to ban at Cloudflare; the API token is passed when running:
# sudo CF_API_TOKEN=... ./setup.sh (never commit it)
CF_ZONE_ID=""

# authorized_keys (can SSH in as the user running sudo)
SSH_AUTHORIZED_KEYS=(
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEbn2jv0T7gRSqqnCtIcoo4Zc7/hjVKU+Xtp6LfmdHio laptop-lenovo"
)
