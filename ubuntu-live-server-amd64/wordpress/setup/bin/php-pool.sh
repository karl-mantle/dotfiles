#!/usr/bin/env bash

setup_php_pool() {
    section_start "Configuring PHP-FPM pool for $SITE_DOMAIN"

    if [ -z "$SITE_DOMAIN" ]; then
        echo "No SITE_DOMAIN set in config.sh, skipping."
        return
    fi

    local php_version
    php_version=$(php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION;')

    local pool_dir="/etc/php/$php_version/fpm/pool.d"
    local pool_conf="$pool_dir/$SITE_USER.conf"

    # only written once, so settings added later (e.g. for Wordfence) aren't overwritten;
    # delete the file and run this script again to start fresh
    if [ -f "$pool_conf" ]; then
        echo "$pool_conf already exists, keeping it."
    else
        write_php_pool "$pool_conf"
    fi

    # nothing uses the stock [www] pool now, so stop it keeping idle processes around
    if [ -f "$pool_dir/www.conf" ]; then
        echo "Disabling the stock [www] pool..."

        mv "$pool_dir/www.conf" "$pool_dir/www.conf.disabled"
    fi

    "php-fpm$php_version" -t
    systemctl reload "php$php_version-fpm"
}

write_php_pool() {
    echo "Creating pool $1..."

    # A pool per site, running as the site's own user: a hacked plugin can't touch other
    # sites' files or read their wp-config.php, and PHP settings here only affect this site.
    cat > "$1" <<EOF
[$SITE_USER]
user = $SITE_USER
group = $SITE_USER

; nginx connects as www-data
listen = /run/php/php-fpm-$SITE_USER.sock
listen.owner = www-data
listen.group = www-data
listen.mode = 0660

; only start PHP processes when requests come in, and stop them when idle
pm = ondemand
pm.max_children = 5
pm.process_idle_timeout = 30s
pm.max_requests = 500

; match nginx's client_max_body_size, so media uploads up to 64 MB work
php_admin_value[upload_max_filesize] = 64M
php_admin_value[post_max_size] = 64M

; site-specific settings go here, e.g. the line Wordfence's "Optimize the Firewall" gives:
; php_admin_value[auto_prepend_file] = $SITE_ROOT/wordfence-waf.php
EOF
}
