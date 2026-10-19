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

2. Clone the repository and update `./setup/config.sh` (hostname, SSH public keys).

3. Run the below:

```bash
cd ~/dotfiles/ubuntu-26.04-live-server-amd64/wordpress/setup/
sudo ./setup.sh
```

4. Complete the manual actions post-install. **Check you can log in over Tailscale before closing this session.**

### Manual steps

- Tailscale login URL (or set `TS_AUTHKEY` to skip it)
- `mysql_secure_installation`

## Contents

- **system**: apt upgrade, hostname, base packages
- **ssh keys**: public keys from `config.sh` authorized for the user running `sudo`
- **swap**: 2G swap file, swappiness 10
- **unattended-upgrades**: automatic security updates
- **tailscale**: SSH is only reachable over Tailscale
- **ufw**: allows `Nginx Full` publicly, everything on `tailscale0`
- **fail2ban**: `sshd`, `nginx-http-auth` and `wordpress` (`wp-login.php`) jails
- **php + mysql**: php-fpm with WordPress extensions, mysql-server
- **ssh hardening**: no root login, no password login (skipped until the user has a key)

The script is safe to run again, e.g. after adding an SSH key.
