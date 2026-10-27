#!/usr/bin/env bash

setup_wordpress_maintenance() {
    section_start "Setting up daily Bedrock backup and checks"

    if [ -z "$SITE_DOMAIN" ]; then
        echo "No SITE_DOMAIN set in config.sh, skipping."
        return
    fi

    # one per site, so other sites' setups on this server don't overwrite it
    local name="wordpress-maintenance-$SITE_USER"

    # Updates come from Composer through deploys (Dependabot PRs, then the deploy workflow),
    # not from here: updating on the server would leave composer.lock out of step with the repo.
    # site values are written into the script, so it runs on its own from the timer
    cat > "/usr/local/sbin/$name" <<EOF
#!/usr/bin/env bash
# Daily backup and checks for $SITE_DOMAIN, written by dotfiles bedrock/setup.
# Run by $name.timer, see: journalctl -u $name

set -eo pipefail

SITE_WEB_ROOT="$SITE_WEB_ROOT"
DB_NAME="$SITE_DB_NAME"
BACKUP_DIR="$BACKUP_DIR"
BACKUP_KEEP_DAYS=$BACKUP_KEEP_DAYS
SITE_USER="$SITE_USER"

wp() {
    sudo -u "\$SITE_USER" WP_CLI_CACHE_DIR="/var/cache/wp-cli/\$SITE_USER" /usr/local/bin/wp --path="\$SITE_WEB_ROOT/wp" "\$@"
}

if ! wp core is-installed; then
    echo "WordPress isn't installed yet, skipping."
    exit 0
fi

install -d -m 700 "\$BACKUP_DIR"
backup="\$BACKUP_DIR/\$DB_NAME-\$(date +%Y%m%d-%H%M%S).sql.gz"
mysqldump --single-transaction --add-drop-table "\$DB_NAME" | gzip > "\$backup"
chmod 600 "\$backup"
echo "Backed up database to \$backup"

find "\$BACKUP_DIR" -name "\$DB_NAME-*.sql.gz" -mtime +"\$BACKUP_KEEP_DAYS" -delete

# apply database changes from a core update that came in with a deploy
wp core update-db

# fails the run (and shows in systemctl --failed) if core files were changed
wp core verify-checksums
wp db check
EOF

    chmod 750 "/usr/local/sbin/$name"

    cat > "/etc/systemd/system/$name.service" <<EOF
[Unit]
Description=Bedrock backup and checks for $SITE_DOMAIN
After=mysql.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/$name
EOF

    cat > "/etc/systemd/system/$name.timer" <<EOF
[Unit]
Description=Daily Bedrock backup and checks for $SITE_DOMAIN

[Timer]
OnCalendar=daily
RandomizedDelaySec=1h
# run on the next boot if the server was off at the scheduled time
Persistent=true

[Install]
WantedBy=timers.target
EOF

    systemctl daemon-reload
    systemctl enable --now "$name.timer"

    systemctl list-timers "$name.timer"
}
