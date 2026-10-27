#!/usr/bin/env bash

setup_deploy_user() {
    section_start "Setting up deploy user $DEPLOY_USER"

    # a normal login user without sudo: owns the code, pulls from GitHub and runs Composer
    if ! id "$DEPLOY_USER" >/dev/null 2>&1; then
        echo "Creating user $DEPLOY_USER..."

        adduser --disabled-password --comment "" "$DEPLOY_USER"
    else
        echo "User $DEPLOY_USER already exists, skipping."
    fi

    # keys allowed to log in as the deploy user, e.g. GitHub Actions over Tailscale
    add_authorized_keys "$DEPLOY_USER" "${DEPLOY_AUTHORIZED_KEYS[@]}"

    local deploy_home
    deploy_home=$(getent passwd "$DEPLOY_USER" | cut -d: -f6)
    local deploy_key="$deploy_home/.ssh/github_deploy"

    # read-only deploy key for the repo, no passphrase so pulls can run unattended
    if [ ! -f "$deploy_key" ]; then
        echo "Creating GitHub deploy key..."

        as_deploy ssh-keygen -t ed25519 -N "" -C "$DEPLOY_USER@$(hostname)" -f "$deploy_key"
    else
        echo "GitHub deploy key already exists, skipping."
    fi

    # GitHub's published host keys, so the first pull doesn't ask to trust it
    curl -fsSL https://api.github.com/meta \
        | jq -r '.ssh_keys[] | "github.com " + .' \
        | as_deploy tee "$deploy_home/.ssh/known_hosts" >/dev/null

    as_deploy touch "$deploy_home/.ssh/config"
    chmod 600 "$deploy_home/.ssh/config"

    if ! grep -q "^Host github.com" "$deploy_home/.ssh/config"; then
        as_deploy tee -a "$deploy_home/.ssh/config" >/dev/null <<EOF

Host github.com
    HostName github.com
    User git
    IdentityFile $deploy_key
    IdentitiesOnly yes
EOF
    else
        echo "GitHub SSH config already exists, skipping."
    fi
}

setup_bedrock_site() {
    section_start "Setting up Bedrock site $SITE_DOMAIN"

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

    # clone the repo as the deploy user, who owns the code
    if [ ! -d "$SITE_ROOT/.git" ]; then
        if ! as_deploy git ls-remote "$SITE_REPO" >/dev/null 2>&1; then
            echo "Can't read $SITE_REPO yet, skipping the site."
            echo "Add the deploy key to the repo (see manual actions), then run this script again."
            return
        fi

        echo "Cloning $SITE_REPO to $SITE_ROOT..."

        install -d -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$SITE_ROOT"
        as_deploy git clone "$SITE_REPO" "$SITE_ROOT"
    else
        echo "Repo already cloned to $SITE_ROOT, skipping."
    fi

    # first install only; after that, deploys run Composer
    if [ ! -d "$SITE_ROOT/vendor" ]; then
        echo "Installing Composer dependencies..."

        as_deploy composer install --no-dev --optimize-autoloader --no-interaction --working-dir="$SITE_ROOT"
    fi

    local theme_dir="$SITE_WEB_ROOT/app/themes/$SITE_THEME"

    if [ -n "$SITE_THEME" ] && [ -f "$theme_dir/composer.json" ] && [ ! -d "$theme_dir/vendor" ]; then
        echo "Installing theme Composer dependencies..."

        as_deploy composer install --no-dev --optimize-autoloader --no-interaction --working-dir="$theme_dir"
    fi

    # code is read-only to PHP, apart from uploads and the cache
    # (Acorn compiles the Sage theme's Blade views into app/cache/acorn)
    for dir in uploads cache; do
        mkdir -p "$SITE_WEB_ROOT/app/$dir"
        chown "$SITE_USER:$SITE_USER" "$SITE_WEB_ROOT/app/$dir"
        chmod 755 "$SITE_WEB_ROOT/app/$dir"
    done

    setup_security_txt

    mysql -e "CREATE DATABASE IF NOT EXISTS \`$SITE_DB_NAME\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

    # database user and .env are created together, as the password only lives there
    if [ -f "$SITE_ROOT/.env" ]; then
        echo ".env already exists, skipping database user and config."
        return
    fi

    echo "Creating database user $SITE_DB_USER and .env..."

    # suffix guarantees mixed case, a digit and a special character,
    # in case mysql_secure_installation enabled password validation
    local db_password
    db_password="$(openssl rand -base64 24)-Aa1"

    mysql <<EOF
CREATE USER IF NOT EXISTS '$SITE_DB_USER'@'localhost' IDENTIFIED BY '$db_password';
ALTER USER '$SITE_DB_USER'@'localhost' IDENTIFIED BY '$db_password';
GRANT ALL PRIVILEGES ON \`$SITE_DB_NAME\`.* TO '$SITE_DB_USER'@'localhost';
EOF

    # owned by the deploy user, readable by the site's PHP through its group
    install -m 640 -o "$DEPLOY_USER" -g "$SITE_USER" /dev/null "$SITE_ROOT/.env"

    cat > "$SITE_ROOT/.env" <<EOF
DB_NAME='$SITE_DB_NAME'
DB_USER='$SITE_DB_USER'
DB_PASSWORD='$db_password'
DB_HOST='localhost'

WP_ENV='production'
WP_HOME='https://$SITE_DOMAIN'
WP_SITEURL="\${WP_HOME}/wp"

AUTH_KEY='$(openssl rand -base64 48)'
SECURE_AUTH_KEY='$(openssl rand -base64 48)'
LOGGED_IN_KEY='$(openssl rand -base64 48)'
NONCE_KEY='$(openssl rand -base64 48)'
AUTH_SALT='$(openssl rand -base64 48)'
SECURE_AUTH_SALT='$(openssl rand -base64 48)'
LOGGED_IN_SALT='$(openssl rand -base64 48)'
NONCE_SALT='$(openssl rand -base64 48)'
EOF
}

setup_security_txt() {
    if [ -z "$SECURITY_CONTACT" ]; then
        echo "No SECURITY_CONTACT set in config.sh, skipping security.txt."
        return
    fi

    # RFC 9116: Expires is required and should be under a year away,
    # so it's rewritten on every run
    install -d "$SITE_WEB_ROOT/.well-known"

    cat > "$SITE_WEB_ROOT/.well-known/security.txt" <<EOF
Contact: $SECURITY_CONTACT
Expires: $(date -u -d "+1 year" +%Y-%m-%dT%H:%M:%SZ)
Preferred-Languages: en
Canonical: https://$SITE_DOMAIN/.well-known/security.txt
EOF

    echo "Wrote security.txt, expires in a year (run this script again to renew)."
}

bedrock_is_cloned() {
    [ -f "$SITE_ROOT/composer.json" ]
}

wordpress_is_installed() {
    # the installer creates the options table, so it exists once WordPress is installed
    [ -n "$(mysql -N -e "SHOW TABLES LIKE 'wp_options'" "$SITE_DB_NAME" 2>/dev/null)" ]
}
