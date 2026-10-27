#!/usr/bin/env bash

setup_wordpress_stack() {
    section_start "Installing PHP and MySQL"

    PACKAGES=(
        mysql-server
        php-cli
        php-curl
        php-fpm
        php-gd
        php-mbstring
        php-mysql
        php-xml
        php-zip
    )

    apt install -y "${PACKAGES[@]}"

    echo
    echo "Installed PHP:   $(php -r 'echo PHP_VERSION;')"
    echo "Installed MySQL: $(mysql --version)"

    section_start "Securing MySQL"

    mysql_secure_installation
}

setup_wp_cli() {
    section_start "Installing WP-CLI"

    if [ ! -x /usr/local/bin/wp ]; then
        echo "Installing WP-CLI..."

        local tmp
        tmp=$(mktemp -d)
        local url="https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar"

        curl -fsSL -o "$tmp/wp-cli.phar" "$url"
        echo "$(curl -fsSL "$url.sha512")  $tmp/wp-cli.phar" | sha512sum -c -

        install -m 755 "$tmp/wp-cli.phar" /usr/local/bin/wp
        rm -rf "$tmp"
    else
        echo "WP-CLI already installed, skipping."
    fi

    wp --allow-root --version
}
