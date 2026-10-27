#!/usr/bin/env bash

setup_wordpress_site() {
    section_start "Setting up WordPress site $SITE_DOMAIN"

    if [ -z "$SITE_DOMAIN" ]; then
        echo "No SITE_DOMAIN set in config.sh, skipping."
        return
    fi

    # system user the site's PHP-FPM pool runs as: no login, no sudo
    if ! id "$SITE_USER" >/dev/null 2>&1; then
        echo "Creating system user $SITE_USER..."

        useradd --system --user-group --no-create-home \
            --home-dir "$SITE_ROOT" --shell /usr/sbin/nologin "$SITE_USER"
    else
        echo "User $SITE_USER already exists, skipping."
    fi

    # the site user's home is the site, which WP-CLI can't use as a cache
    install -d -o "$SITE_USER" -g "$SITE_USER" "/var/cache/wp-cli/$SITE_USER"

    # download WordPress
    if [ ! -f "$SITE_ROOT/wp-includes/version.php" ]; then
        echo "Downloading WordPress to $SITE_ROOT..."

        local tmp
        tmp=$(mktemp -d)

        curl -fsSL -o "$tmp/wordpress.tar.gz" https://wordpress.org/latest.tar.gz
        echo "$(curl -fsSL https://wordpress.org/latest.tar.gz.sha1)  $tmp/wordpress.tar.gz" | sha1sum -c -

        mkdir -p "$SITE_ROOT"
        tar -xzf "$tmp/wordpress.tar.gz" -C "$SITE_ROOT" --strip-components=1
        rm -rf "$tmp"

        # the site's PHP runs as its own user, which needs to write uploads, plugins
        # and updates; files stay world-readable so nginx (www-data) can serve them
        chown -R "$SITE_USER:$SITE_USER" "$SITE_ROOT"
        find "$SITE_ROOT" -type d -exec chmod 755 {} +
        find "$SITE_ROOT" -type f -exec chmod 644 {} +
    else
        echo "WordPress already in $SITE_ROOT, skipping download."
    fi

    setup_security_txt

    mysql -e "CREATE DATABASE IF NOT EXISTS \`$SITE_DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

    # database user and wp-config.php are created together, as the password only lives there
    if [ -f "$SITE_ROOT/wp-config.php" ]; then
        echo "wp-config.php already exists, skipping database user and config."
        return
    fi

    echo "Creating database user $SITE_DB_USER and wp-config.php..."

    # suffix guarantees mixed case, a digit and a special character,
    # in case mysql_secure_installation enabled password validation
    local db_password
    db_password="$(openssl rand -base64 24)-Aa1"

    mysql <<EOF
CREATE USER IF NOT EXISTS '$SITE_DB_USER'@'localhost' IDENTIFIED BY '$db_password';
ALTER USER '$SITE_DB_USER'@'localhost' IDENTIFIED BY '$db_password';
GRANT ALL PRIVILEGES ON \`$SITE_DB_NAME\`.* TO '$SITE_DB_USER'@'localhost';
EOF

    # authentication keys and salts, same as https://api.wordpress.org/secret-key/1.1/salt/
    local salts
    salts=$(php -r '
        foreach (["AUTH_KEY", "SECURE_AUTH_KEY", "LOGGED_IN_KEY", "NONCE_KEY",
                  "AUTH_SALT", "SECURE_AUTH_SALT", "LOGGED_IN_SALT", "NONCE_SALT"] as $name) {
            printf("define( %s, %s );\n", var_export($name, true), var_export(bin2hex(random_bytes(32)), true));
        }
    ')

    install -m 640 -o "$SITE_USER" -g "$SITE_USER" /dev/null "$SITE_ROOT/wp-config.php"

    cat > "$SITE_ROOT/wp-config.php" <<EOF
<?php

define( 'DB_NAME', '$SITE_DB_NAME' );
define( 'DB_USER', '$SITE_DB_USER' );
define( 'DB_PASSWORD', '$db_password' );
define( 'DB_HOST', 'localhost' );
define( 'DB_CHARSET', 'utf8mb4' );
define( 'DB_COLLATE', '' );

$salts

\$table_prefix = 'wp_';

define( 'WP_DEBUG', false );

// hardening: no theme/plugin editor in the dashboard, HTTPS-only admin,
// and outgoing requests only to the hosts listed (updates still work)
define( 'DISALLOW_FILE_EDIT', true );
define( 'FORCE_SSL_ADMIN', true );
define( 'WP_HTTP_BLOCK_EXTERNAL', true );
define( 'WP_ACCESSIBLE_HOSTS', '$SITE_ACCESSIBLE_HOSTS' );

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
EOF
}

setup_security_txt() {
    if [ -z "$SECURITY_CONTACT" ]; then
        echo "No SECURITY_CONTACT set in config.sh, skipping security.txt."
        return
    fi

    # RFC 9116: Expires is required and should be under a year away,
    # so it's rewritten on every run
    install -d -o "$SITE_USER" -g "$SITE_USER" "$SITE_ROOT/.well-known"

    cat > "$SITE_ROOT/.well-known/security.txt" <<EOF
Contact: $SECURITY_CONTACT
Expires: $(date -u -d "+1 year" +%Y-%m-%dT%H:%M:%SZ)
Preferred-Languages: en
Canonical: https://$SITE_DOMAIN/.well-known/security.txt
EOF

    echo "Wrote security.txt, expires in a year (run this script again to renew)."
}

setup_wordpress_plugins() {
    section_start "Installing WordPress plugins"

    if [ -z "$SITE_DOMAIN" ] || ! wordpress_is_installed; then
        echo "WordPress isn't installed yet, skipping. Run this script again after the installer."
        return
    fi

    for plugin in "${SITE_PLUGINS[@]}"; do
        # only installs missing plugins, so ones you deactivate stay deactivated
        if wp_site plugin is-installed "$plugin"; then
            echo "$plugin already installed, skipping."
        else
            wp_site plugin install "$plugin" --activate
        fi
    done
}

wordpress_is_installed() {
    # the installer creates the options table, so it exists once WordPress is installed
    [ -n "$(mysql -N -e "SHOW TABLES LIKE 'wp_options'" "$SITE_DB_NAME" 2>/dev/null)" ]
}
