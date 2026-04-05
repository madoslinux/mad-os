#!/usr/bin/env bash

set -euo pipefail

export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}
export DISPLAY=${DISPLAY:-}

notify() {
    notify-send "WiFi" "$1"
}

wofi_menu() {
    wofi --show dmenu \
        --width=460 \
        --height=420 \
        --matching=fuzzy \
        --location=center \
        --force-display \
        --hide-scroll=true \
        --prompt="$1" \
        --title="$2" \
        --gtk-dark \
        2>/dev/null
}

wofi_input() {
    printf "\n" | wofi --show dmenu \
        --width=460 \
        --height=140 \
        --location=center \
        --force-display \
        --prompt="$1" \
        --title="$2" \
        --gtk-dark \
        2>/dev/null
}

wifi_state() {
    nmcli -t -f WIFI general 2>/dev/null || echo "disabled"
}

wifi_iface() {
    nmcli -t -f DEVICE,TYPE device status | awk -F: '$2=="wifi"{print $1; exit}'
}

current_ssid() {
    nmcli -t -f ACTIVE,SSID device wifi | awk -F: '$1=="yes"{print $2; exit}'
}

current_ip() {
    local iface
    iface=$(wifi_iface)
    if [[ -z "$iface" ]]; then
        echo "-"
        return
    fi

    ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n 1
}

ensure_wifi_on() {
    if [[ "$(wifi_state)" != "enabled" ]]; then
        nmcli radio wifi on
        sleep 1
    fi
}

connect_to_ssid() {
    local ssid="$1"
    local security="$2"
    local pass

    if nmcli -t -f NAME connection show | grep -Fxq "$ssid"; then
        if nmcli connection up id "$ssid" >/dev/null 2>&1; then
            notify "Conectado a $ssid"
            return 0
        fi
    fi

    if [[ -z "$security" || "$security" == "--" ]]; then
        if nmcli device wifi connect "$ssid" >/dev/null 2>&1; then
            notify "Conectado a $ssid"
            return 0
        fi
        notify "No se pudo conectar a $ssid"
        return 1
    fi

    pass=$(wofi_input "Clave para $ssid" "Password WiFi")
    if [[ -z "$pass" ]]; then
        notify "Conexion cancelada"
        return 1
    fi

    if nmcli device wifi connect "$ssid" password "$pass" >/dev/null 2>&1; then
        notify "Conectado a $ssid"
        return 0
    fi

    notify "No se pudo conectar a $ssid"
    return 1
}

menu_connect_network() {
    local raw choice i line inuse ssid signal security lock prefix
    local -a labels=()
    local -a ssids=()
    local -a securities=()

    ensure_wifi_on
    nmcli device wifi rescan >/dev/null 2>&1 || true

    raw=$(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list --rescan no)
    if [[ -z "$raw" ]]; then
        notify "No se encontraron redes"
        return 0
    fi

    while IFS=: read -r inuse ssid signal security; do
        [[ -z "$ssid" ]] && continue
        lock=""
        if [[ -n "$security" && "$security" != "--" ]]; then
            lock=" [lock]"
        fi
        prefix="  "
        if [[ "$inuse" == "*" ]]; then
            prefix="* "
        fi
        line="${prefix}${ssid} (${signal}%)${lock}"
        labels+=("$line")
        ssids+=("$ssid")
        securities+=("$security")
    done <<< "$raw"

    if [[ ${#labels[@]} -eq 0 ]]; then
        notify "No se encontraron redes"
        return 0
    fi

    choice=$(printf "%s\n" "${labels[@]}" | wofi_menu "Selecciona red" "Redes WiFi")
    [[ -z "$choice" ]] && return 0

    for i in "${!labels[@]}"; do
        if [[ "${labels[$i]}" == "$choice" ]]; then
            connect_to_ssid "${ssids[$i]}" "${securities[$i]}"
            return $?
        fi
    done

    notify "Seleccion invalida"
    return 1
}

menu_hidden_network() {
    local ssid pass

    ensure_wifi_on

    ssid=$(wofi_input "SSID oculta" "Conectar red oculta")
    [[ -z "$ssid" ]] && return 0

    pass=$(wofi_input "Clave (vacia = abierta)" "Conectar $ssid")

    if [[ -z "$pass" ]]; then
        if nmcli device wifi connect "$ssid" hidden yes >/dev/null 2>&1; then
            notify "Conectado a $ssid"
            return 0
        fi
        notify "No se pudo conectar a $ssid"
        return 1
    fi

    if nmcli device wifi connect "$ssid" password "$pass" hidden yes >/dev/null 2>&1; then
        notify "Conectado a $ssid"
        return 0
    fi

    notify "No se pudo conectar a $ssid"
    return 1
}

menu_disconnect() {
    local active
    active=$(nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2=="802-11-wireless"{print $1; exit}')
    if [[ -z "$active" ]]; then
        notify "No hay conexion WiFi activa"
        return 0
    fi

    if nmcli connection down id "$active" >/dev/null 2>&1; then
        notify "WiFi desconectado"
        return 0
    fi

    notify "No se pudo desconectar"
    return 1
}

menu_toggle_wifi() {
    if [[ "$(wifi_state)" == "enabled" ]]; then
        nmcli radio wifi off
        notify "WiFi desactivado"
    else
        nmcli radio wifi on
        notify "WiFi activado"
    fi
}

show_info() {
    local state ssid ipaddr
    state=$(wifi_state)
    ssid=$(current_ssid)
    ipaddr=$(current_ip)

    if [[ "$state" != "enabled" ]]; then
        notify "Estado: apagado"
        return
    fi

    if [[ -z "$ssid" ]]; then
        notify "Estado: encendido sin conexion"
        return
    fi

    notify "Conectado: $ssid | IP: ${ipaddr:--}"
}

if ! command -v nmcli >/dev/null 2>&1; then
    notify "nmcli no esta instalado"
    exit 1
fi

if ! command -v wofi >/dev/null 2>&1; then
    notify "wofi no esta instalado"
    exit 1
fi

status="$(wifi_state)"
ssid="$(current_ssid)"
ipaddr="$(current_ip)"

if [[ "$status" == "enabled" ]]; then
    if [[ -n "$ssid" ]]; then
        header="Estado: ON | SSID: $ssid | IP: ${ipaddr:--}"
    else
        header="Estado: ON | Sin conexion"
    fi
else
    header="Estado: OFF"
fi

selection=$(printf "%s\n" \
    "$header" \
    "Conectar a red disponible" \
    "Conectar red oculta" \
    "Desconectar WiFi actual" \
    "Activar/Desactivar WiFi" \
    "Reescanear redes" \
    "Abrir nm-connection-editor" \
    "Mostrar estado" | wofi_menu "WiFi" "Control de red")

case "$selection" in
    "Conectar a red disponible")
        menu_connect_network
        ;;
    "Conectar red oculta")
        menu_hidden_network
        ;;
    "Desconectar WiFi actual")
        menu_disconnect
        ;;
    "Activar/Desactivar WiFi")
        menu_toggle_wifi
        ;;
    "Reescanear redes")
        ensure_wifi_on
        nmcli device wifi rescan >/dev/null 2>&1 || true
        notify "Escaneo completado"
        ;;
    "Abrir nm-connection-editor")
        nm-connection-editor >/dev/null 2>&1 &
        ;;
    "Mostrar estado")
        show_info
        ;;
esac
