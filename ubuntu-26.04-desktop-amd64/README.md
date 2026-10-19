# Ubuntu 26.04 Desktop AMD64

https://releases.ubuntu.com/26.04/

The only prerequisite is having `git` installed in order to clone the repo via HTTPS.

## Initialise

1. Clone the repository to the home folder.

2. Run the below:

```bash
cd ~/dotfiles/ubuntu-26.04-desktop-amd64/setup/
./setup.sh
```

3. Complete the manual actions post-install

## Contents

- **git configuration**: update values in `./setup/config.sh`
- **nvm + node.js**: installs latest LTS version

### Node packages installed

- astro-language-server
- eslint
- prettier
- typescript
- typescript-language-server
- wrangler
