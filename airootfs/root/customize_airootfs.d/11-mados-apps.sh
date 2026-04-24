#!/usr/bin/env bash
# 11-mados-apps.sh - Install madOS native applications
set -euo pipefail
source /root/customize_airootfs.d/03-lib.sh

install_mados_apps() {
    for app in "${MADOS_APPS[@]}"; do
        clone_and_install_app "${GITHUB_REPO}/${app}" "$app"
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_mados_apps
fi
