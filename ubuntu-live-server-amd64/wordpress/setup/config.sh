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

# authorized_keys (can SSH in)
SSH_AUTHORIZED_KEYS=(
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEbn2jv0T7gRSqqnCtIcoo4Zc7/hjVKU+Xtp6LfmdHio laptop-lenovo"
)
