#!/usr/bin/env bash
# 06-network.sh - Ensure live ISO network defaults
set -euo pipefail

configure_network_services() {
    echo "Configuring network services..."

    mkdir -p /etc/systemd/system/multi-user.target.wants
    ln -sf /etc/systemd/system/mados-hw-quirks.service \
        /etc/systemd/system/multi-user.target.wants/mados-hw-quirks.service
    ln -sf /usr/lib/systemd/system/NetworkManager.service \
        /etc/systemd/system/multi-user.target.wants/NetworkManager.service
    ln -sf /usr/lib/systemd/system/mados-network-bootstrap.service \
        /etc/systemd/system/multi-user.target.wants/mados-network-bootstrap.service
    ln -sf /etc/systemd/system/firewalld.service \
        /etc/systemd/system/multi-user.target.wants/firewalld.service

    rm -f /etc/systemd/system/multi-user.target.wants/systemd-networkd.service
    rm -f /etc/systemd/system/network-online.target.wants/systemd-networkd-wait-online.service

    echo "NetworkManager enabled with ethernet bootstrap"
    echo "Hardware quirks service enabled"
    echo "firewalld enabled"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    configure_network_services
fi
