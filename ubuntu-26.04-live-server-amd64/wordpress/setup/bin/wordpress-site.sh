#!/usr/bin/env bash

setup_wordpress_site() {
    section_start "Setting up WordPress site $SITE_DOMAIN"

    if [ -z "$SITE_DOMAIN" ]; then
        echo "No SITE_DOMAIN set in config.sh, skipping."
        return
    fi

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

        # PHP-FPM runs as www-data and needs to write uploads, plugins and updates
        chown -R www-data:www-data "$SITE_ROOT"
        find "$SITE_ROOT" -type d -exec chmod 755 {} +
        find "$SITE_ROOT" -type f -exec chmod 644 {} +
    else
        echo "WordPress already in $SITE_ROOT, skipping download."
    fi

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

    install -m 640 -o www-data -g www-data /dev/null "$SITE_ROOT/wp-config.php"

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

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
EOF
}

wordpress_is_installed() {
    # the installer creates the options table, so it exists once WordPress is installed
    [ -n "$(mysql -N -e "SHOW TABLES LIKE 'wp_options'" "$SITE_DB_NAME" 2>/dev/null)" ]
}
