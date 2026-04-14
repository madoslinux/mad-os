#!/usr/bin/env bash
# shellcheck disable=SC2034
set -euo pipefail

# Configure Firefox for madOS
# Homepage: www.kodingvibes.com + chat.qwen.ai (opens both on launch)

FIREFOX_DEFAULTS_URL="https://www.kodingvibes.com"
FIREFOX_CHAT_URL="https://chat.qwen.ai"
FIREFOX_HOME_URLS="${FIREFOX_DEFAULTS_URL}|${FIREFOX_CHAT_URL}"

setup_firefox_policies() {
    local policies_dir="/usr/lib/firefox/distribution/policies"
    local policies_file="${policies_dir}/policies.json"

    mkdir -p "${policies_dir}"

    cat > "${policies_file}" << EOF
{
  "policies": {
    "Homepage": {
      "URL": "${FIREFOX_DEFAULTS_URL}",
      "Locked": true,
      "StartPage": "homepage"
    },
    "Preferences": {
      "browser.startup.homepage": "${FIREFOX_HOME_URLS}",
      "browser.startup.page": 1,
      "browser.newtabpage.enabled": false,
      "browser.newtab.preload": false,
      "browser.aboutWelcome.enabled": false,
      "browser.shell.checkDefaultBrowser": false,
      "datareporting.healthreport.service.enabled": false,
      "datareporting.policy.dataSubmissionEnabled": false,
      "toolkit.telemetry.enabled": false,
      "browser.pingCentre.enabled": false,
      "browser.crashReporter.enabled": false,
      "app.update.enabled": false,
      "app.update.auto": false,
      "browser.pocket.enabled": false,
      "network.http.pipelining": false,
      "general.smoothScroll.enabled": false,
      "toolkit.cosmeticAnimations.enabled": false,
      "layers.acceleration.disabled": true,
      "gfx.direct2d.disabled": true,
      "media.peerconnection.enabled": false,
      "dom.ipc.processCount": 1,
      "browser.cache.memory.capacity": 51200,
      "browser.cache.disk.capacity": 51200
    },
    "DisableTelemetry": true,
    "DisableUpdateChecks": true,
    "NoDefaultBookmarks": true
  }
}
EOF

    local etc_policies_dir="/etc/firefox/policies"
    local etc_policies_file="${etc_policies_dir}/policies.json"
    mkdir -p "${etc_policies_dir}"
    cp "${policies_file}" "${etc_policies_file}"
}

setup_firefox_desktop_override() {
    local desktop_dir="/usr/share/applications"
    local desktop_file="${desktop_dir}/firefox.desktop"

    mkdir -p "${desktop_dir}"

    cat > "${desktop_file}" << 'DESKTOP'
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox
GenericName=Web Browser
Comment=Fast and private browser
Exec=/usr/lib/firefox/firefox --new-tab https://www.kodingvibes.com --new-tab https://chat.qwen.ai %u
Terminal=false
Icon=firefox
StartupNotify=true
Categories=Network;WebBrowser;
MimeType=text/html;application/xhtml+xml;application/xml;
DESKTOP
}

setup_firefox_wrapper() {
    local wrapper_path="/usr/local/bin/firefox"
    cat > "${wrapper_path}" << 'WRAPPER'
#!/bin/bash
exec /usr/lib/firefox/firefox --new-tab https://www.kodingvibes.com --new-tab https://chat.qwen.ai "$@"
WRAPPER
    chmod +x "${wrapper_path}"
}

setup_skel_firefox_prefs() {
    local skel_moz_dir="/etc/skel/.mozilla/firefox"
    local timestamp
    timestamp=$(date +%s)
    local skel_profile_dir="${skel_moz_dir}/.default-${timestamp}"

    mkdir -p "${skel_moz_dir}"
    mkdir -p "${skel_profile_dir}"

    cat > "${skel_profile_dir}/user.js" << EOF
// Firefox preferences for madOS
user_pref("browser.startup.homepage", "${FIREFOX_HOME_URLS}");
user_pref("browser.startup.page", 1);
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.newtab.preload", false);
user_pref("browser.aboutWelcome.enabled", false);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("datareporting.healthreport.service.enabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("browser.pocket.enabled", false);
user_pref("layers.acceleration.disabled", true);
user_pref("dom.ipc.processCount", 1);
user_pref("browser.cache.memory.capacity", 51200);
EOF

    cat > "${skel_moz_dir}/profiles.ini" << EOF
[General]
StartWithLastProfile=1

[Profile0]
Name=default
IsRelative=1
Path=.default-${timestamp}
Default=1
EOF
}

setup_root_firefox_prefs() {
    local root_moz_dir="/root/.mozilla/firefox"
    local timestamp
    timestamp=$(date +%s)
    local root_profile_dir="${root_moz_dir}/.default-${timestamp}"

    mkdir -p "${root_moz_dir}"
    mkdir -p "${root_profile_dir}"

    cat > "${root_profile_dir}/user.js" << EOF
// Firefox preferences for madOS
user_pref("browser.startup.homepage", "${FIREFOX_HOME_URLS}");
user_pref("browser.startup.page", 1);
user_pref("browser.newtabpage.enabled", false);
user_pref("browser.newtab.preload", false);
user_pref("browser.aboutWelcome.enabled", false);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("datareporting.healthreport.service.enabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("browser.pocket.enabled", false);
user_pref("layers.acceleration.disabled", true);
user_pref("dom.ipc.processCount", 1);
user_pref("browser.cache.memory.capacity", 51200);
EOF

    cat > "${root_moz_dir}/profiles.ini" << EOF
[General]
StartWithLastProfile=1

[Profile0]
Name=default
IsRelative=1
Path=.default-${timestamp}
Default=1
EOF
}

setup_firefox_policies
setup_firefox_desktop_override
setup_firefox_wrapper
setup_skel_firefox_prefs
setup_root_firefox_prefs