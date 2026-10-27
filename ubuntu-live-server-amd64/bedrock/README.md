# Bedrock VPS Setup

https://releases.ubuntu.com/26.04/

Sets up a server for a [Bedrock](https://roots.io/bedrock/) WordPress site deployed from GitHub. It can run on the same server as `../wordpress/`: shared parts (nginx catch-all, rate limit, Cloudflare IPs, fail2ban base config) are written identically by both, and each site gets its own user, PHP pool, fail2ban jail and maintenance timer.

The only prerequisite is having `git` installed in order to clone the repo via HTTPS.

## Initialise

1. As root, create your admin user with sudo access, then log in as that user:

```bash
adduser karl-mantle
usermod -aG sudo karl-mantle
su - karl-mantle
```

This is the account you SSH in as and run the script from, not the account WordPress or deploys run as.

2. Clone the repository and update `./setup/config.sh` (hostname, SSH public keys, site domain and repo, deploy keys, Cloudflare).

3. Run the below:

```bash
cd ~/dotfiles/ubuntu-live-server-amd64/bedrock/setup/
sudo ./setup.sh
```

To send fail2ban's Bedrock bans to Cloudflare, pass an API token with the "Zone > Firewall Services > Edit" permission (and set `CF_ZONE_ID` in `config.sh`). It's only needed once:

```bash
sudo CF_API_TOKEN=... ./setup.sh
```

4. Complete the manual actions post-install. **Check you can log in over Tailscale before closing this session.**

### Manual steps

- Tailscale login URL (or set `TS_AUTHKEY` to skip it)
- `mysql_secure_installation`
- Add the printed deploy key to the repo (Settings > Deploy keys, read-only), then run the script again to clone
- certbot email and terms, on the first certificate
- WordPress installer in the browser (`/wp/wp-admin/install.php`), then run the script again to block it
- Run the deploy workflow once, for the theme's built assets
- With Cloudflare's proxy on, set SSL/TLS mode to **Full (strict)**

## Contents

- **system**: apt upgrade, hostname, base packages
- **ssh keys**: public keys from `config.sh` authorized for the user running `sudo`
- **swap**: 2G swap file, swappiness 10
- **unattended-upgrades**: automatic security updates
- **tailscale**: SSH is only reachable over Tailscale
- **ufw**: allows `Nginx Full` publicly, everything on `tailscale0`
- **nginx**: `catch-all` site replacing Debian's default, WordPress login rate limit, Cloudflare real visitor IPs, certbot, and the site for `SITE_DOMAIN`
- **php + mysql**: php-fpm with WordPress extensions, mysql-server
- **wp-cli + composer**: installed to `/usr/local/bin` (checksums verified)
- **deploy user**: owns the code, pulls with a read-only GitHub deploy key, and is what GitHub Actions logs in as (no sudo)
- **bedrock site**: clone, Composer install, database, user and `.env` for `SITE_DOMAIN`, plus `security.txt`
- **php-fpm pool**: a pool per site, running as the site's own system user
- **maintenance**: daily database backup and checks (`wordpress-maintenance-<site user>.timer`)
- **fail2ban**: `sshd`, `nginx-http-auth` and `bedrock` (`wp/wp-login.php`) jails, optionally banning at Cloudflare
- **ssh hardening**: no root login, no password login (skipped until the user has a key)

The script is safe to run again, e.g. after adding the deploy key.

## Users and permissions

| User | Owns | Purpose |
|---|---|---|
| your admin user | - | SSH in and run `sudo ./setup.sh` |
| `DEPLOY_USER` (`deploy`) | the repo in `SITE_ROOT` | `git pull`, Composer, theme rsync; GitHub Actions logs in as it |
| `SITE_USER` | `web/app/uploads` | PHP-FPM runs as it; reads `.env` through its group, can't change the code |

`.env` is `640`, owned by the deploy user with the site user's group. Plugin and core updates come through Composer, not the dashboard (the repo's `DISALLOW_FILE_MODS`).

## Deploys

SSH is only open over Tailscale, so the deploy workflow's runner has to join the tailnet before it can reach the server:

1. In Tailscale, create an OAuth client (or an ephemeral, reusable auth key) tagged `tag:ci`, and allow `tag:ci` to reach the server on port 22 in the ACLs.
2. Add the client ID and secret to the repo's Actions secrets.
3. Add a key pair for Actions: the public key to `DEPLOY_AUTHORIZED_KEYS` in `config.sh` (then run the script again), the private key to the repo's Actions secrets.
4. In `.github/workflows/deploy.yml`, connect to Tailscale before the SSH steps, and SSH in as `deploy` to the server's Tailscale name or IP instead of its public IP:

```yaml
      - name: Connect to Tailscale
        uses: tailscale/github-action@v3
        with:
          oauth-client-id: ${{ secrets.TS_OAUTH_CLIENT_ID }}
          oauth-secret: ${{ secrets.TS_OAUTH_SECRET }}
          tags: tag:ci
```

On the server, the deploy steps stay as they are, run as `deploy` in `SITE_ROOT`: `git pull`, rsync the built theme, and `composer install --no-dev --optimize-autoloader` in the root and the theme.

## Maintenance

`wordpress-maintenance-<site user>.timer` runs once a day:

1. backs up the database to `BACKUP_DIR`, keeping `BACKUP_KEEP_DAYS` days
2. applies any database update from a deployed core update (`wp core update-db`)
3. verifies the core file checksums and checks the database

It doesn't update anything: updates come from Dependabot PRs and the deploy workflow, so `composer.lock` in the repo always matches the server.

```bash
systemctl list-timers 'wordpress-maintenance-*'                   # next runs
journalctl -u wordpress-maintenance-bedrock_karlsblog_dev        # output of past runs
sudo systemctl start wordpress-maintenance-bedrock_karlsblog_dev # run now
```

Backups stay on the server and only cover the database, so copy them somewhere else if the server itself is lost.
