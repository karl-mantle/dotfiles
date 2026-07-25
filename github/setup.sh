#!/usr/bin/env bash

# exit if any command fails
set -e

EMAIL="130184376+karl-mantle@users.noreply.github.com"
KEY="$HOME/.ssh/github_ed25519"

echo "Configuring Git..."

# git config
git config --global user.name "Karl Mantle"
git config --global user.email "$EMAIL"
git config --global init.defaultBranch main


echo "Creating SSH key..."

# create SSH key if it doesn't exist
if [ ! -f "$KEY" ]; then
    ssh-keygen -t ed25519 \
        -C "$EMAIL" \
        -f "$KEY"
else
    echo "SSH key already exists, skipping."
fi


echo "Configuring SSH..."

# create SSH config if missing
mkdir -p ~/.ssh
touch ~/.ssh/config
chmod 600 ~/.ssh/config

# add GitHub config if it isn't already there
if ! grep -q "github_ed25519" ~/.ssh/config; then
    cat >> ~/.ssh/config <<EOF

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/github_ed25519
    AddKeysToAgent yes
EOF
fi


echo "Adding SSH key to agent..."

# use existing agent if available
if [ -n "$SSH_AUTH_SOCK" ]; then
    ssh-add "$KEY" 2>/dev/null || true
else
    echo "No SSH agent running."
    echo "Ubuntu normally starts one automatically."
fi


echo
echo "=============================="
echo "Your GitHub SSH public key:"
echo "=============================="
cat "$KEY.pub"
echo
echo "=============================="
echo "Add this key at:"
echo "GitHub → Settings → SSH and GPG keys"
echo
echo "Then test with:"
echo "ssh -T git@github.com"