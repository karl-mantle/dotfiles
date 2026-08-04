#!/usr/bin/env bash

setup_nvm() {
    section_start "Installing NVM"

    export NVM_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/nvm"
    mkdir -p "$NVM_DIR"

    if [ ! -s "$NVM_DIR/nvm.sh" ]; then
        echo "Installing NVM..."

        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
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

    # enable Corepack for pnpm, yarn
    if command -v corepack >/dev/null 2>&1; then
        corepack enable
    fi

    echo
    echo "Installed Node: $(node -v)"
    echo "Installed npm:  $(npm -v)"
}

setup_node_packages() {
    section_start "Installing Node packages"

    PACKAGES=(
        prettier
        eslint
        typescript
        typescript-language-server
        astro-language-server
    )

    npm install --global "${PACKAGES[@]}"
}