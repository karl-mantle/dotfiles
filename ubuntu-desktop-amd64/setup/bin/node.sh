#!/usr/bin/env bash

setup_nvm() {
    section_start "Installing NVM, Node.js, and global Node packages"

    export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
    mkdir -p "$NVM_DIR"

    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        echo "Installing NVM..."

        curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
    else
        echo "NVM already installed, skipping."
    fi

    # load NVM
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        source "$NVM_DIR/nvm.sh"
    fi

    echo "Installing Node LTS..."

    nvm install --lts
    nvm use --lts
    nvm alias default lts/*

    echo
    echo "Installed Node: $(node -v)"
    echo "Installed npm:  $(npm -v)"

    install_global_node_packages

    # enable corepack for pnpm, yarn
    enable_corepack
}

install_global_node_packages() {
    section_start "Installing global Node packages..."

    PACKAGES=(
        astro-language-server
        corepack
        eslint
        prettier
        typescript
        typescript-language-server
        wrangler
    )

    npm install --global "${PACKAGES[@]}"
}

enable_corepack() {
    section_start "Enabling corepack..."

    if ! command -v corepack >/dev/null 2>&1; then
        echo "Corepack is not available"
        return
    fi

    corepack enable
}
