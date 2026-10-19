# Ubuntu 26.04 Desktop AMD64

https://releases.ubuntu.com/26.04/

The only prerequisite is having `git` installed in order to clone the repo via HTTPS.

## Initialise

1. Clone the repository to the home folder.

2. Check and update `./setup/config.sh`

3. Run the below:

```bash
cd ~/dotfiles/ubuntu-26.04-desktop-amd64/setup/
./setup.sh
```

4. Complete the manual actions post-install.

### Manual steps

- Tailscale login URL (or set `TS_AUTHKEY` to skip it)
- Add SSH key to GitHub: https://github.com/settings/keys

## Contents

- **system**: apt upgrade, hostname, base packages
- **tailscale**: For connecting to other machines securely e.g. vps, pi, etc.
- **git configuration**: update values in `./setup/config.sh`
- **nvm + node.js**: installs latest LTS version

### Node packages installed

- astro-language-server
- corepack
- eslint
- prettier
- typescript
- typescript-language-server
- wrangler
