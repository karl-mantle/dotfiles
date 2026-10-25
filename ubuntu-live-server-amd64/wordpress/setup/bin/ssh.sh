#!/usr/bin/env bash

setup_ssh_hardening() {
    section_start "Disabling root and password SSH login"

    # never lock out the user: only harden once they can log in with a key
    if [ ! -s "$USER_HOME/.ssh/authorized_keys" ]; then
        echo "$USERNAME has no authorized_keys, skipping SSH hardening."
        echo "Add a key (see manual actions) and run this script again."
        return
    fi

    # sshd uses the FIRST value it reads, and sshd_config includes
    # sshd_config.d/*.conf at the top in name order, so 10- beats 50-cloud-init
    cat > /etc/ssh/sshd_config.d/10-hardening.conf <<EOF
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
PubkeyAuthentication yes
EOF

    sshd -t
    systemctl restart ssh

    # check the settings actually took effect
    local effective
    effective=$(sshd -T | grep -E "^(permitrootlogin|passwordauthentication) ")

    echo "$effective"

    if ! grep -qx "permitrootlogin no" <<< "$effective" \
        || ! grep -qx "passwordauthentication no" <<< "$effective"; then
        echo "SSH hardening did not take effect, check /etc/ssh/sshd_config.d/."
        exit 1
    fi
}
