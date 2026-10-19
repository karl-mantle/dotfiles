#!/usr/bin/env bash

setup_required_packages() {
    section_start "Checking prerequisites"

    PACKAGES=(
        curl
        git
    )

    MISSING=()

    for package in "${PACKAGES[@]}"; do
        if ! command -v "$package" >/dev/null 2>&1; then
            MISSING+=("$package")
        fi
    done

    if [ ${#MISSING[@]} -gt 0 ]; then
        echo "Installing missing packages: ${MISSING[*]}"

        sudo apt update
        sudo apt install -y "${MISSING[@]}"
    else
        echo "All prerequisites installed, skipping."
    fi
}
