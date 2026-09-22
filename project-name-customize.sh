#!/bin/bash
set -eux

# ── 1. Stop unattended-upgrades immediately so it can't hold apt locks ──────
sudo systemctl stop unattended-upgrades || true
sudo systemctl disable unattended-upgrades || true
sudo pkill -x unattended-upgrade || true

# ── 2. Repair any interrupted dpkg state, then wait for all locks ────────────
sudo dpkg --configure -a

wait_for_apt() {
    local locks=(
        /var/lib/dpkg/lock-frontend
        /var/lib/dpkg/lock
        /var/cache/apt/archives/lock
    )
    for lock in "${locks[@]}"; do
        while sudo fuser "$lock" >/dev/null 2>&1; do
            echo "Waiting for $lock ..."
            sleep 5
        done
    done
}

wait_for_apt

# ── 3. Refresh package index before removals ─────────────────────────────────
sudo apt-get update

# ── 4. Remove packages that don't affect network connectivity ────────────────
sudo apt-get remove -y --autoremove \
    gnome-initial-setup \
    update-notifier

wait_for_apt
sudo apt-get remove -y --autoremove power-profiles-daemon

sudo apt-get autoremove -y
sudo apt-get clean

# ── 5. Clean up NetworkManager leftover state ────────────────────────────────
sudo rm -rf /etc/NetworkManager/system-connections/*

# ── 6. Clean up existing netplan configs so MAAS starts fresh ────────────────
sudo rm -f /etc/netplan/*.yaml

# ── 7. Write netplan config with networkd renderer ───────────────────────────
sudo tee /etc/netplan/40-renderer.yaml > /dev/null <<'NETPLAN'
network:
  version: 2
  renderer: networkd
NETPLAN
sudo chmod 600 /etc/netplan/40-renderer.yaml

# ── 8. Unmask and enable networkd ────────────────────────────────────────────
sudo systemctl unmask systemd-networkd
sudo systemctl unmask systemd-networkd-wait-online
sudo systemctl unmask systemd-networkd.socket
sudo systemctl enable systemd-networkd
sudo systemctl enable systemd-networkd-wait-online

# ── 9. Fix DNS: enable resolved and re-link resolv.conf ──────────────────────
sudo systemctl enable systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# ── 10. Enable SSH ────────────────────────────────────────────────────────────
sudo systemctl enable ssh

# ── 11. Remove SSH host keys — each deployed machine generates its own ───────
sudo rm -f /etc/ssh/ssh_host_*

# ── 12. Pin cloud-init datasource to MAAS ────────────────────────────────────
sudo tee /etc/cloud/cloud.cfg.d/90_maas.cfg > /dev/null <<'EOF'
datasource_list: [MAAS, None]
EOF

# ── 13. Truncate machine-id so each deployed machine gets a unique identity ──
sudo truncate -s 0 /etc/machine-id
sudo rm -f /var/lib/dbus/machine-id
sudo ln -sf /etc/machine-id /var/lib/dbus/machine-id

# ── 14. Clean cloud-init state so MAAS boot is treated as first run ──────────
sudo cloud-init clean --logs --seed

# ── 15. Keep NetworkManager installed but disabled ──────────────────────────
#        but disabled: the image boots on systemd-networkd so cloud-init can
#        reach MAAS; deploy-time cloud-init user-data can hand over to NM.
sudo systemctl disable NetworkManager NetworkManager-wait-online NetworkManager-dispatcher || true

echo "project-name-customize.sh completed successfully."
