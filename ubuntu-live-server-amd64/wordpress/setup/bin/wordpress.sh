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
