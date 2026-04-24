#!/usr/bin/env bash
# 10-imperative-dots.sh - Install imperative-dots shell theme
set -euo pipefail
source /root/customize_airootfs.d/03-lib.sh

install_imperative_dots() {
    echo "Installing imperative-dots..."
    local build_dir="${BUILD_DIR}/imperative-dots_$$"
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$build_dir"

    local retries=3
    local count=0
    while [ $count -lt $retries ]; do
        if GIT_TERMINAL_PROMPT=0 git clone --depth=1 --single-branch --branch main --no-tags "https://github.com/${IMPERATIVE_DOTS_REPO}.git" "$build_dir/imperative-dots"; then
            break
        fi
        count=$((count + 1))
        echo "  Retry $count/$retries..."
        sleep 2
    done

    if [ $count -eq $retries ]; then
        echo "ERROR: Failed to clone imperative-dots after $retries attempts"
        rm -rf "$build_dir"
        return 1
    fi

    mkdir -p "$IMPERATIVE_DOTS_INSTALL_DIR"
    rm -rf "$IMPERATIVE_DOTS_INSTALL_DIR"
    mv "$build_dir/imperative-dots" "$IMPERATIVE_DOTS_INSTALL_DIR"

    if [[ -f "${IMPERATIVE_DOTS_INSTALL_DIR}/scripts/start/start.sh" ]]; then
        chmod +x "${IMPERATIVE_DOTS_INSTALL_DIR}/scripts/start/start.sh"
    fi

    if [[ -f "${IMPERATIVE_DOTS_INSTALL_DIR}/scripts/start/healthcheck.sh" ]]; then
        chmod +x "${IMPERATIVE_DOTS_INSTALL_DIR}/scripts/start/healthcheck.sh"
    fi

    if [[ -d "${IMPERATIVE_DOTS_INSTALL_DIR}/config/hypr/scripts" ]]; then
        find "${IMPERATIVE_DOTS_INSTALL_DIR}/config/hypr/scripts" -type f -name "*.sh" -exec chmod +x {} +
    fi

    local topbar_qml="${IMPERATIVE_DOTS_INSTALL_DIR}/scripts/quickshell/TopBar.qml"
    if [[ -f "$topbar_qml" ]]; then
        python3 - "$topbar_qml" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
orig = text

if "id: iaPill" not in text:
    text = text.replace("// IA Services\n                    Rectangle {", "// IA Services\n                    Rectangle {\n                        id: iaPill", 1)

if "id: helpPill" not in text:
    text = text.replace("// Help (keybinds)\n                    Rectangle {", "// Help (keybinds)\n                    Rectangle {\n                        id: helpPill", 1)

if "id: volPill" not in text:
    text = text.replace("// Volume\n                    Rectangle {", "// Volume\n                    Rectangle {\n                        id: volPill", 1)

if "id: batPill" not in text:
    text = text.replace("// Battery\n                    Rectangle {", "// Battery\n                    Rectangle {\n                        id: batPill", 1)

text = text.replace(
    "onClicked: Quickshell.execDetached([\"bash\", \"-c\", \"~/.config/hypr/scripts/qs_manager.sh toggle launcher\"])",
    "onClicked: Quickshell.execDetached([\"bash\", \"-c\", \"~/.config/hypr/scripts/qs_manager.sh open launcher\"])",
)

order = ["iaPill", "helpPill", "wifiPill", "btPill", "volPill", "batPill"]

timer_rx = re.compile(r"^(\s*)Timer \{ running: rightLayout\.showLayout && !initAnimTrigger; interval: ([0-9]+); onTriggered: initAnimTrigger = true \}$", re.M)
opacity_rx = re.compile(r"^(\s*)opacity: initAnimTrigger \? 1 : 0$", re.M)
transform_rx = re.compile(r"^(\s*)transform: Translate \{ y: initAnimTrigger \? 0 : 15; Behavior on y \{ NumberAnimation \{ duration: 500; easing\.type: Easing\.OutBack \} \} \}$", re.M)

def replace_seq(rx, repl_fn):
    matches = list(rx.finditer(text))
    if len(matches) < len(order):
        return text
    out = []
    last = 0
    for i, m in enumerate(matches):
        out.append(text[last:m.start()])
        out.append(repl_fn(m, i))
        last = m.end()
    out.append(text[last:])
    return "".join(out)

text = replace_seq(
    timer_rx,
    lambda m, i: f"{m.group(1)}Timer {{ running: rightLayout.showLayout && !{order[i]}.initAnimTrigger; interval: {m.group(2)}; onTriggered: {order[i]}.initAnimTrigger = true }}",
)

text = replace_seq(
    opacity_rx,
    lambda m, i: f"{m.group(1)}opacity: {order[i]}.initAnimTrigger ? 1 : 0",
)

text = replace_seq(
    transform_rx,
    lambda m, i: f"{m.group(1)}transform: Translate {{ y: {order[i]}.initAnimTrigger ? 0 : 15; Behavior on y {{ NumberAnimation {{ duration: 500; easing.type: Easing.OutBack }} }} }}",
)

if text != orig:
    path.write_text(text, encoding="utf-8")
PY
    fi

    local qs_manager_sh="${IMPERATIVE_DOTS_INSTALL_DIR}/config/hypr/scripts/qs_manager.sh"
    if [[ -f "$qs_manager_sh" ]]; then
        python3 - "$qs_manager_sh" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

text = text.replace(
    "ACTIVE_MON=$(hyprctl monitors -j | jq -r '.[] | select(.focused==true)')",
    "ACTIVE_MON=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused==true)' 2>/dev/null)",
)
text = text.replace(
    "MX=$(echo \"$ACTIVE_MON\" | jq -r '.x // 0')",
    "MX=$(echo \"$ACTIVE_MON\" | jq -r '.x // 0' 2>/dev/null || echo 0)",
)
text = text.replace(
    "MY=$(echo \"$ACTIVE_MON\" | jq -r '.y // 0')",
    "MY=$(echo \"$ACTIVE_MON\" | jq -r '.y // 0' 2>/dev/null || echo 0)",
)
text = text.replace(
    "MW=$(echo \"$ACTIVE_MON\" | jq -r '(.width / (.scale // 1)) | round // 1920')",
    "MW=$(echo \"$ACTIVE_MON\" | jq -r '(.width / (.scale // 1)) | round // 1920' 2>/dev/null || echo 1920)",
)
text = text.replace(
    "MH=$(echo \"$ACTIVE_MON\" | jq -r '(.height / (.scale // 1)) | round // 1080')",
    "MH=$(echo \"$ACTIVE_MON\" | jq -r '(.height / (.scale // 1)) | round // 1080' 2>/dev/null || echo 1080)",
)

path.write_text(text, encoding="utf-8")
PY
    fi

    rm -rf "$build_dir"

    echo "✓ imperative-dots installed to ${IMPERATIVE_DOTS_INSTALL_DIR}"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_imperative_dots
fi
