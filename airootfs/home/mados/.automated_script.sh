#!/usr/bin/env bash
# Run in a subshell with explicit error handling to avoid closing the session

script_cmdline() {
    local param
    for param in $(</proc/cmdline); do
        case "${param}" in
            script=*)
                echo "${param#*=}"
                return 0
                ;;
            *)
                :
                ;;
        esac
    done
    return 0
}

automated_script() {
    local script rt
    local tmp_script
    script="$(script_cmdline)"
    if [[ -n "${script}" ]]; then
        tmp_script="$(mktemp /tmp/startup_script.XXXXXX)"
        if [[ "${script}" =~ ^((http|https|ftp|tftp)://) ]]; then
            printf '%s: waiting for network-online.target\n' "$0" 2>/dev/null || true
            until systemctl --quiet is-active network-online.target 2>/dev/null; do
                sleep 1 2>/dev/null || true
            done
            printf '%s: downloading %s\n' "$0" "${script}" 2>/dev/null || true
            curl "${script}" --location --retry-connrefused --retry 10 --fail -s -o "${tmp_script}" 2>/dev/null || true
            rt=$?
        else
            cp "${script}" "${tmp_script}" 2>/dev/null || true
            rt=$?
        fi
        if [[ ${rt} -eq 0 ]] && [[ -f "${tmp_script}" ]]; then
            chmod 700 "${tmp_script}" 2>/dev/null || true
            printf '%s: executing automated script\n' "$0" 2>/dev/null || true
            "${tmp_script}" 2>/dev/null || true
        fi
        rm -f "${tmp_script}" 2>/dev/null || true
    fi
    return 0
}

# Only run on tty1 to avoid issues on SSH
if [[ $(tty 2>/dev/null) == "/dev/tty1" ]]; then
    automated_script
fi

exit 0