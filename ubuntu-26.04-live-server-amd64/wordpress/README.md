# WordPress VPS Setup

https://releases.ubuntu.com/26.04/

The only prerequisite is having `git` installed in order to clone the repo via HTTPS.

## Initialise

1. As root, create your user with sudo access, then log in as that user:

```bash
adduser wordpress
usermod -aG sudo wordpress
su - wordpress
```

2. Clone the repository and update `./setup/config.sh` (hostname, SSH public keys, site domain).

3. Run the below:

```bash
cd ~/dotfiles/ubuntu-26.04-live-server-amd64/wordpress/setup/
sudo ./setup.sh
```

4. Complete the manual actions post-install. **Check you can log in over Tailscale before closing this session.**

### Manual steps

- Tailscale login URL (or set `TS_AUTHKEY` to skip it)
- `mysql_secure_installation`
- certbot email and terms, on the first certificate
- WordPress installer in the browser, then run the script again

## Contents

- **system**: apt upgrade, hostname, base packages
- **ssh keys**: public keys from `config.sh` authorized for the user running `sudo`
- **swap**: 2G swap file, swappiness 10
- **unattended-upgrades**: automatic security updates
- **tailscale**: SSH is only reachable over Tailscale
- **ufw**: allows `Nginx Full` publicly, everything on `tailscale0`
- **fail2ban**: `sshd`, `nginx-http-auth` and `wordpress` (`wp-login.php`) jails
- **nginx**: `catch-all` site replacing Debian's default (drops requests for unknown hosts), WordPress login rate limit in `conf.d`, certbot, and the site for `SITE_DOMAIN`
- **php + mysql**: php-fpm with WordPress extensions, mysql-server
- **wordpress site**: WordPress files, database, user and `wp-config.php` for `SITE_DOMAIN`
- **ssh hardening**: no root login, no password login (skipped until the user has a key)

The script is safe to run again, e.g. after adding an SSH key.

## Adding a site

Set `SITE_DOMAIN` in `./setup/config.sh` (e.g. `wordpress.karlsblog.dev`) and run the script. Point the domain's DNS at the server first, as certbot needs it to issue the certificate.

The script:

1. downloads the latest WordPress (checksum verified) into `SITE_ROOT`, owned by `www-data`
2. creates the database and a database user with a random password, and writes `wp-config.php` with it and fresh salts
3. requests the certificate, writes `/etc/nginx/sites-available/$SITE_DOMAIN` using the installed PHP-FPM version, and enables it

Each step is skipped if it's already done. If the certificate fails, the nginx site is skipped and the rest of the setup still runs.

The installer (`wp-admin/install.php`) stays reachable until WordPress is installed. Run it straight away, then run the script again to block it.
