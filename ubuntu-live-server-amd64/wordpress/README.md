# WordPress VPS Setup

https://releases.ubuntu.com/26.04/

The only prerequisite is having `git` installed in order to clone the repo via HTTPS.

## Initialise

1. As root, create your admin user with sudo access, then log in as that user:

```bash
adduser karl-mantle
usermod -aG sudo karl-mantle
su - karl-mantle
```

This is the account you SSH in as and run the script from, not the account WordPress runs as.

2. Clone the repository and update `./setup/config.sh` (hostname, SSH public keys, site domain, Cloudflare).

3. Run the below:

```bash
cd ~/dotfiles/ubuntu-live-server-amd64/wordpress/setup/
sudo ./setup.sh
```

To send fail2ban's WordPress bans to Cloudflare, pass an API token with the "Zone > Firewall Services > Edit" permission (and set `CF_ZONE_ID` in `config.sh`):

```bash
sudo CF_API_TOKEN=... ./setup.sh
```

It's only needed once, as it's saved to `/etc/fail2ban/jail.d/cloudflare.local`.

4. Complete the manual actions post-install. **Check you can log in over Tailscale before closing this session.**

### Manual steps

- Tailscale login URL (or set `TS_AUTHKEY` to skip it)
- `mysql_secure_installation`
- certbot email and terms, on the first certificate
- WordPress installer in the browser, then run the script again (blocks the installer and installs the plugins)
- With Cloudflare's proxy on, set SSL/TLS mode to **Full (strict)**. Flexible causes a redirect loop with `FORCE_SSL_ADMIN`

## Contents

- **system**: apt upgrade, hostname, base packages
- **ssh keys**: public keys from `config.sh` authorized for the user running `sudo`
- **swap**: 2G swap file, swappiness 10
- **unattended-upgrades**: automatic security updates
- **tailscale**: SSH is only reachable over Tailscale
- **ufw**: allows `Nginx Full` publicly, everything on `tailscale0`
- **nginx**: `catch-all` site replacing Debian's default (drops requests for unknown hosts), WordPress login rate limit, Cloudflare real visitor IPs, certbot, and the site for `SITE_DOMAIN`
- **php + mysql**: php-fpm with WordPress extensions, mysql-server
- **wp-cli**: installed to `/usr/local/bin/wp` (checksum verified)
- **wordpress site**: WordPress files, database, user, hardened `wp-config.php`, `security.txt` and plugins for `SITE_DOMAIN`
- **php-fpm pool**: a pool per site, running as the site's own system user (the stock `[www]` pool is disabled)
- **maintenance**: daily database backup, then core, plugin and theme updates (`wordpress-maintenance.timer`)
- **fail2ban**: `sshd`, `nginx-http-auth` and `wordpress` (`wp-login.php`) jails, optionally banning at Cloudflare
- **ssh hardening**: no root login, no password login (skipped until the user has a key)

The script is safe to run again, e.g. after adding an SSH key.

## Adding a site

Set `SITE_DOMAIN` in `./setup/config.sh` (e.g. `wordpress.karlsblog.dev`) and run the script. Point the domain's DNS at the server first, as certbot needs it to issue the certificate.

The script:

1. creates the site's system user (`SITE_USER`, no login or sudo), and downloads the latest WordPress (checksum verified) into `SITE_ROOT`, owned by that user so it can update itself from the dashboard
2. creates the database and a database user with a random password, and writes `wp-config.php` with it, fresh salts and hardening settings
3. writes `.well-known/security.txt` if `SECURITY_CONTACT` is set
4. creates the site's PHP-FPM pool (`/etc/php/<version>/fpm/pool.d/$SITE_USER.conf`), running as `SITE_USER`
5. requests the certificate, writes `/etc/nginx/sites-available/$SITE_DOMAIN` pointing at the pool's socket, and enables it
6. once WordPress is installed, installs and activates `SITE_PLUGINS`
7. installs the daily backup and update timer

Each step is skipped if it's already done. If the certificate fails, the nginx site is skipped and the rest of the setup still runs.

The installer (`wp-admin/install.php`) stays reachable until WordPress is installed. Run it straight away, then run the script again to block it.

### PHP-FPM pool

Each site's PHP runs in its own pool as its own user, so a hacked plugin can't change other sites' files or read their `wp-config.php`. PHP settings for one site, such as the `auto_prepend_file` line from Wordfence's "Optimize the Firewall", go in that site's pool file, followed by `sudo systemctl reload php<version>-fpm`. The script only creates the pool file once, so your changes are kept when it runs again.

### wp-config.php hardening

- `DISALLOW_FILE_EDIT`: no theme/plugin code editor in the dashboard (updates and installs still work)
- `FORCE_SSL_ADMIN`: logins and the dashboard over HTTPS only
- `WP_HTTP_BLOCK_EXTERNAL` + `WP_ACCESSIBLE_HOSTS`: outgoing requests only to `SITE_ACCESSIBLE_HOSTS`. If a plugin can't reach its service, add its domain there and in `wp-config.php`

## Maintenance

`wordpress-maintenance.timer` runs once a day:

1. backs up the database to `BACKUP_DIR`, keeping `BACKUP_KEEP_DAYS` days
2. updates core, plugins and themes
3. verifies the core file checksums and checks the database

```bash
systemctl list-timers wordpress-maintenance.timer   # next run
journalctl -u wordpress-maintenance                 # output of past runs
sudo systemctl start wordpress-maintenance          # run now
```

Backups stay on the server and only cover the database, so copy them somewhere else if the server itself is lost.
