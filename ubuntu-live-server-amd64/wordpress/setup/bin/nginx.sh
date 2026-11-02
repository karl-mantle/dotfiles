#!/usr/bin/env bash

setup_nginx() {
    section_start "Configuring nginx"

    # certbot's nginx plugin creates the options-ssl-nginx.conf and
    # ssl-dhparams.pem files the site includes
    apt install -y certbot python3-certbot-nginx

    # Shared rate limit for WordPress logins. Goes in /etc/nginx/conf.d/ once per server,
    # not in each site file: defining the same zone twice stops nginx starting.
    cat > /etc/nginx/conf.d/wordpress-limits.conf <<'EOF'
# only POSTs (actual login attempts) count; viewing the form or logging out isn't limited
map $request_method $wp_login_limit_key {
    POST    $binary_remote_addr;
    default "";
}

limit_req_zone $wp_login_limit_key zone=wp_login:10m rate=10r/m;
limit_req_status 429;
EOF

    setup_cloudflare_real_ip

    # Catch-all for requests whose Host doesn't match any site, such as scanners hitting
    # the server's IP address. Closes the connection instead of serving a site.
    # Its own file, so Debian's packaged default site is left untouched for upgrades.
    cat > /etc/nginx/sites-available/catch-all <<'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    listen 443 ssl default_server;
    listen [::]:443 ssl default_server;
    server_name _;

    # refuse HTTPS without needing a certificate
    ssl_reject_handshake on;

    return 444;
}
EOF

    # only one site can be default_server, so disable Debian's
    rm -f /etc/nginx/sites-enabled/default
    ln -sf /etc/nginx/sites-available/catch-all /etc/nginx/sites-enabled/catch-all

    nginx -t
    systemctl reload nginx
}

setup_nginx_site() {
    section_start "Configuring nginx site $SITE_DOMAIN"

    if [ -z "$SITE_DOMAIN" ]; then
        echo "No SITE_DOMAIN set in config.sh, skipping."
        return
    fi

    # the site's HTTPS block needs the certificate to exist before nginx will load it
    if [ ! -f "/etc/letsencrypt/live/$SITE_DOMAIN/fullchain.pem" ]; then
        echo "Requesting certificate for $SITE_DOMAIN..."

        if ! certbot certonly --nginx -d "$SITE_DOMAIN"; then
            echo
            echo "Could not get a certificate for $SITE_DOMAIN, skipping the site."
            echo "Check the domain's DNS points to this server, then run this script again."
            return
        fi
    else
        echo "Certificate for $SITE_DOMAIN already exists, skipping."
    fi

    # leave the installer reachable until WordPress is installed, then block it
    local install_rule='location ~* ^/wp-admin/install\.php$ { return 444; }'

    if ! wordpress_is_installed; then
        install_rule="# $install_rule  (open until the installer has run, then run setup.sh again)"
    fi

    cat > "/etc/nginx/sites-available/$SITE_DOMAIN" <<EOF
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    server_name $SITE_DOMAIN;

    root $SITE_ROOT;
    index index.php index.html;

    ssl_certificate /etc/letsencrypt/live/$SITE_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$SITE_DOMAIN/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    autoindex off;
    server_tokens off;
    client_max_body_size 64m;

    # Security headers. These cover static files too, so turn off the plugin's
    # "Send security headers" and "Send HSTS header" features to avoid sending them twice.
    # Add "; includeSubDomains" to HSTS only on an apex domain whose subdomains are all HTTPS.
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
    add_header Strict-Transport-Security "max-age=31536000" always;

    # Regex locations are checked in order and the first match wins,
    # so the blocks below must stay above the PHP handler at the bottom.

    # Hidden files (.git, .env, .htaccess...), except Let's Encrypt's .well-known
    location ~ /\.(?!well-known/) { return 444; }

    # Config, install and version-revealing files
    location ~* ^/(?:wp-config(?:-sample)?\.php|readme\.html|license\.txt)$ { return 444; }
    $install_rule

    # XML-RPC
    location ~* ^/xmlrpc\.php$ { return 444; }

    # Logs (WP_DEBUG_LOG writes to wp-content/debug.log by default), backups and dumps
    location ~* \.(?:log|sql|bak|old|orig|swp|ini|sh|dist)$ { return 444; }
    # Archives, apart from ones uploaded through the media library
    location ~* ^/(?!wp-content/uploads/).*\.(?:zip|tar|gz|tgz|rar|7z)$ { return 444; }

    # Never run PHP from uploads
    location ~* ^/wp-content/uploads/.*\.php$ { return 444; }

    # Wordfence's rules and logs, written by PHP and never served
    location ^~ /wp-content/wflogs/ { return 444; }

    # Rate limit login attempts
    location ~* ^/wp-login\.php$ {
        limit_req zone=wp_login burst=5 nodelay;
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm-$SITE_USER.sock;
    }

    # Cache static assets in the browser
    location ~* \.(?:css|js|mjs|jpe?g|png|gif|webp|avif|svg|ico|woff2?|ttf|otf)$ {
        expires 30d;
        access_log off;
        try_files \$uri /index.php?\$args;
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php-fpm-$SITE_USER.sock;
    }
}

server {
    listen 80;
    listen [::]:80;
    server_name $SITE_DOMAIN;
    return 301 https://\$host\$request_uri;
}
EOF

    ln -sf "/etc/nginx/sites-available/$SITE_DOMAIN" "/etc/nginx/sites-enabled/$SITE_DOMAIN"

    nginx -t
    systemctl reload nginx
}

setup_cloudflare_real_ip() {
    local conf=/etc/nginx/conf.d/cloudflare-real-ip.conf

    if [ "$CLOUDFLARE_PROXY" != "true" ]; then
        rm -f "$conf"
        return
    fi

    echo "Trusting Cloudflare's CF-Connecting-IP header for visitor IPs..."

    # Behind Cloudflare's proxy every request comes from a Cloudflare IP. This swaps in
    # the visitor's real IP for logs, the login rate limit, fail2ban and PHP.
    # The ranges rarely change; run this script again to refresh them.
    local ranges
    ranges=$(curl -fsSL https://www.cloudflare.com/ips-v4; echo; curl -fsSL https://www.cloudflare.com/ips-v6)

    {
        echo "# Cloudflare IP ranges, from https://www.cloudflare.com/ips/"
        grep -v '^$' <<< "$ranges" | sed 's/^/set_real_ip_from /; s/$/;/'
        echo
        echo "real_ip_header CF-Connecting-IP;"
    } > "$conf"
}
