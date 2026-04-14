#!/usr/bin/env bash
# 15-updater.sh - Install mados-updater
set -euo pipefail
source /root/customize_airootfs.d/03-lib.sh

install_updater() {
    clone_and_install_app "${UPDATER_GITHUB_REPO}/${UPDATER_APP}" "$UPDATER_APP"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_updater
fi
