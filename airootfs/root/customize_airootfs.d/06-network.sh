#!/usr/bin/env bash
# 06-network.sh - Ensure live ISO network defaults
set -euo pipefail

configure_network_services() {
    echo "Configuring network services..."

    mkdir -p /etc/systemd/system/multi-user.target.wants
    ln -sf /usr/lib/systemd/system/NetworkManager.service \
        /etc/systemd/system/multi-user.target.wants/NetworkManager.service
    ln -sf /usr/lib/systemd/system/mados-network-bootstrap.service \
        /etc/systemd/system/multi-user.target.wants/mados-network-bootstrap.service

    rm -f /etc/systemd/system/multi-user.target.wants/systemd-networkd.service
    rm -f /etc/systemd/system/network-online.target.wants/systemd-networkd-wait-online.service

    echo "NetworkManager enabled with ethernet bootstrap"
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    configure_network_services
fi
