#!/usr/bin/env bash

setup_swap() {
    section_start "Setting up swap..."

    if [ ! -f "$SWAP_FILE" ]; then
        echo "Creating $SWAP_SIZE swap file..."

        fallocate -l "$SWAP_SIZE" "$SWAP_FILE"
        chmod 600 "$SWAP_FILE"
        mkswap "$SWAP_FILE"
    else
        echo "$SWAP_FILE already exists, skipping creation."
    fi

    if ! swapon --show=NAME --noheadings | grep -qx "$SWAP_FILE"; then
        swapon "$SWAP_FILE"
    fi

    if ! grep -q "^$SWAP_FILE " /etc/fstab; then
        echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
    fi

    echo "vm.swappiness=$SWAPPINESS" > /etc/sysctl.d/99-swappiness.conf
    sysctl -p /etc/sysctl.d/99-swappiness.conf

    swapon --show
}
