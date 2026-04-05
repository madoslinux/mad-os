#!/usr/bin/env bash

set -euo pipefail

export WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}
export DISPLAY=${DISPLAY:-}

detect_lang() {
    local locale
    locale="${LC_ALL:-${LC_MESSAGES:-${LANG:-en_US.UTF-8}}}"
    locale="${locale%%.*}"
    locale="${locale%%@*}"

    case "$locale" in
        es* ) echo "es" ;;
        en* ) echo "en" ;;
        fr* ) echo "fr" ;;
        de* ) echo "de" ;;
        it* ) echo "it" ;;
        pt* ) echo "pt" ;;
        ru* ) echo "ru" ;;
        ja* ) echo "ja" ;;
        zh* ) echo "zh" ;;
        * ) echo "en" ;;
    esac
}

UI_LANG="$(detect_lang)"

t() {
    local key="$1"
    case "${UI_LANG}:${key}" in
        es:missing_nmcli) echo "nmcli no esta instalado" ;;
        en:missing_nmcli) echo "nmcli is not installed" ;;
        fr:missing_nmcli) echo "nmcli n'est pas installe" ;;
        de:missing_nmcli) echo "nmcli ist nicht installiert" ;;
        it:missing_nmcli) echo "nmcli non e installato" ;;
        pt:missing_nmcli) echo "nmcli nao esta instalado" ;;
        ru:missing_nmcli) echo "nmcli ne ustanovlen" ;;
        ja:missing_nmcli) echo "nmcli ga insutoru sareteimasen" ;;
        zh:missing_nmcli) echo "nmcli wei an zhuang" ;;

        es:missing_wofi) echo "wofi no esta instalado" ;;
        en:missing_wofi) echo "wofi is not installed" ;;
        fr:missing_wofi) echo "wofi n'est pas installe" ;;
        de:missing_wofi) echo "wofi ist nicht installiert" ;;
        it:missing_wofi) echo "wofi non e installato" ;;
        pt:missing_wofi) echo "wofi nao esta instalado" ;;
        ru:missing_wofi) echo "wofi ne ustanovlen" ;;
        ja:missing_wofi) echo "wofi ga insutoru sareteimasen" ;;
        zh:missing_wofi) echo "wofi wei an zhuang" ;;

        es:no_networks) echo "No se encontraron redes" ;;
        en:no_networks) echo "No networks found" ;;
        fr:no_networks) echo "Aucun reseau trouve" ;;
        de:no_networks) echo "Keine Netzwerke gefunden" ;;
        it:no_networks) echo "Nessuna rete trovata" ;;
        pt:no_networks) echo "Nenhuma rede encontrada" ;;
        ru:no_networks) echo "Seti ne naideny" ;;
        ja:no_networks) echo "Nettowaku ga mitsukarimasen" ;;
        zh:no_networks) echo "wei fa xian ke yong wang luo" ;;

        es:invalid_selection) echo "Seleccion invalida" ;;
        en:invalid_selection) echo "Invalid selection" ;;
        fr:invalid_selection) echo "Selection invalide" ;;
        de:invalid_selection) echo "Ungueltige Auswahl" ;;
        it:invalid_selection) echo "Selezione non valida" ;;
        pt:invalid_selection) echo "Selecao invalida" ;;
        ru:invalid_selection) echo "Nevernyi vybor" ;;
        ja:invalid_selection) echo "Muko na sentaku" ;;
        zh:invalid_selection) echo "xuan ze wu xiao" ;;

        es:connected) echo "Conectado a %s" ;;
        en:connected) echo "Connected to %s" ;;
        fr:connected) echo "Connecte a %s" ;;
        de:connected) echo "Verbunden mit %s" ;;
        it:connected) echo "Connesso a %s" ;;
        pt:connected) echo "Conectado a %s" ;;
        ru:connected) echo "Podkliucheno k %s" ;;
        ja:connected) echo "%s ni setsuzoku shimashita" ;;
        zh:connected) echo "yi lian jie %s" ;;

        es:connect_failed) echo "No se pudo conectar a %s" ;;
        en:connect_failed) echo "Could not connect to %s" ;;
        fr:connect_failed) echo "Impossible de se connecter a %s" ;;
        de:connect_failed) echo "Verbindung mit %s fehlgeschlagen" ;;
        it:connect_failed) echo "Impossibile connettersi a %s" ;;
        pt:connect_failed) echo "Nao foi possivel conectar a %s" ;;
        ru:connect_failed) echo "Ne udalos podkliuchitsia k %s" ;;
        ja:connect_failed) echo "%s ni setsuzoku dekimasen deshita" ;;
        zh:connect_failed) echo "wu fa lian jie %s" ;;

        es:connect_canceled) echo "Conexion cancelada" ;;
        en:connect_canceled) echo "Connection cancelled" ;;
        fr:connect_canceled) echo "Connexion annulee" ;;
        de:connect_canceled) echo "Verbindung abgebrochen" ;;
        it:connect_canceled) echo "Connessione annullata" ;;
        pt:connect_canceled) echo "Conexao cancelada" ;;
        ru:connect_canceled) echo "Podkliuchenie otmeneno" ;;
        ja:connect_canceled) echo "Setsuzoku wa kyansaru saremashita" ;;
        zh:connect_canceled) echo "lian jie yi qu xiao" ;;

        es:wifi_disconnected) echo "WiFi desconectado" ;;
        en:wifi_disconnected) echo "WiFi disconnected" ;;
        fr:wifi_disconnected) echo "WiFi deconnecte" ;;
        de:wifi_disconnected) echo "WiFi getrennt" ;;
        it:wifi_disconnected) echo "WiFi disconnesso" ;;
        pt:wifi_disconnected) echo "WiFi desconectado" ;;
        ru:wifi_disconnected) echo "WiFi otkliuchen" ;;
        ja:wifi_disconnected) echo "WiFi wa setsudan saremashita" ;;
        zh:wifi_disconnected) echo "WiFi yi duan kai" ;;

        es:no_active_wifi) echo "No hay conexion WiFi activa" ;;
        en:no_active_wifi) echo "No active WiFi connection" ;;
        fr:no_active_wifi) echo "Aucune connexion WiFi active" ;;
        de:no_active_wifi) echo "Keine aktive WiFi-Verbindung" ;;
        it:no_active_wifi) echo "Nessuna connessione WiFi attiva" ;;
        pt:no_active_wifi) echo "Nenhuma conexao WiFi ativa" ;;
        ru:no_active_wifi) echo "Net aktivnogo WiFi podkliucheniia" ;;
        ja:no_active_wifi) echo "Akutibu na WiFi setsuzoku ga arimasen" ;;
        zh:no_active_wifi) echo "mei you huo dong de WiFi lian jie" ;;

        es:disconnect_failed) echo "No se pudo desconectar" ;;
        en:disconnect_failed) echo "Could not disconnect" ;;
        fr:disconnect_failed) echo "Impossible de deconnecter" ;;
        de:disconnect_failed) echo "Trennen fehlgeschlagen" ;;
        it:disconnect_failed) echo "Impossibile disconnettere" ;;
        pt:disconnect_failed) echo "Nao foi possivel desconectar" ;;
        ru:disconnect_failed) echo "Ne udalos otkliuchit" ;;
        ja:disconnect_failed) echo "Setsudan dekimasen deshita" ;;
        zh:disconnect_failed) echo "wu fa duan kai lian jie" ;;

        es:wifi_off) echo "WiFi desactivado" ;;
        en:wifi_off) echo "WiFi disabled" ;;
        fr:wifi_off) echo "WiFi desactive" ;;
        de:wifi_off) echo "WiFi deaktiviert" ;;
        it:wifi_off) echo "WiFi disattivato" ;;
        pt:wifi_off) echo "WiFi desativado" ;;
        ru:wifi_off) echo "WiFi vykliuchen" ;;
        ja:wifi_off) echo "WiFi wa musei ni narimashita" ;;
        zh:wifi_off) echo "WiFi yi guan bi" ;;

        es:wifi_on) echo "WiFi activado" ;;
        en:wifi_on) echo "WiFi enabled" ;;
        fr:wifi_on) echo "WiFi active" ;;
        de:wifi_on) echo "WiFi aktiviert" ;;
        it:wifi_on) echo "WiFi attivato" ;;
        pt:wifi_on) echo "WiFi ativado" ;;
        ru:wifi_on) echo "WiFi vkliuchen" ;;
        ja:wifi_on) echo "WiFi wa yuko ni narimashita" ;;
        zh:wifi_on) echo "WiFi yi kai qi" ;;

        es:scan_done) echo "Escaneo completado" ;;
        en:scan_done) echo "Scan completed" ;;
        fr:scan_done) echo "Analyse terminee" ;;
        de:scan_done) echo "Scan abgeschlossen" ;;
        it:scan_done) echo "Scansione completata" ;;
        pt:scan_done) echo "Varredura concluida" ;;
        ru:scan_done) echo "Skanirovanie zaversheno" ;;
        ja:scan_done) echo "Sukyan ga kanryo shimashita" ;;
        zh:scan_done) echo "sao miao wan cheng" ;;

        es:state_off) echo "Estado: apagado" ;;
        en:state_off) echo "Status: off" ;;
        fr:state_off) echo "Etat: desactive" ;;
        de:state_off) echo "Status: aus" ;;
        it:state_off) echo "Stato: spento" ;;
        pt:state_off) echo "Estado: desligado" ;;
        ru:state_off) echo "Status: vykliuchen" ;;
        ja:state_off) echo "Jotai: ofu" ;;
        zh:state_off) echo "zhuang tai: guan bi" ;;

        es:state_on_no_conn) echo "Estado: encendido sin conexion" ;;
        en:state_on_no_conn) echo "Status: on without connection" ;;
        fr:state_on_no_conn) echo "Etat: active sans connexion" ;;
        de:state_on_no_conn) echo "Status: an ohne Verbindung" ;;
        it:state_on_no_conn) echo "Stato: acceso senza connessione" ;;
        pt:state_on_no_conn) echo "Estado: ligado sem conexao" ;;
        ru:state_on_no_conn) echo "Status: vkliuchen bez podkliucheniia" ;;
        ja:state_on_no_conn) echo "Jotai: on, massetsuzoku" ;;
        zh:state_on_no_conn) echo "zhuang tai: kai qi, wei lian jie" ;;

        es:state_connected) echo "Conectado: %s | IP: %s" ;;
        en:state_connected) echo "Connected: %s | IP: %s" ;;
        fr:state_connected) echo "Connecte: %s | IP: %s" ;;
        de:state_connected) echo "Verbunden: %s | IP: %s" ;;
        it:state_connected) echo "Connesso: %s | IP: %s" ;;
        pt:state_connected) echo "Conectado: %s | IP: %s" ;;
        ru:state_connected) echo "Podkliucheno: %s | IP: %s" ;;
        ja:state_connected) echo "Setsuzoku: %s | IP: %s" ;;
        zh:state_connected) echo "yi lian jie: %s | IP: %s" ;;

        es:header_on_connected) echo "Estado: ON | SSID: %s | IP: %s" ;;
        en:header_on_connected) echo "Status: ON | SSID: %s | IP: %s" ;;
        fr:header_on_connected) echo "Etat: ON | SSID: %s | IP: %s" ;;
        de:header_on_connected) echo "Status: ON | SSID: %s | IP: %s" ;;
        it:header_on_connected) echo "Stato: ON | SSID: %s | IP: %s" ;;
        pt:header_on_connected) echo "Estado: ON | SSID: %s | IP: %s" ;;
        ru:header_on_connected) echo "Status: ON | SSID: %s | IP: %s" ;;
        ja:header_on_connected) echo "Jotai: ON | SSID: %s | IP: %s" ;;
        zh:header_on_connected) echo "zhuang tai: ON | SSID: %s | IP: %s" ;;

        es:header_on_no_conn) echo "Estado: ON | Sin conexion" ;;
        en:header_on_no_conn) echo "Status: ON | No connection" ;;
        fr:header_on_no_conn) echo "Etat: ON | Sans connexion" ;;
        de:header_on_no_conn) echo "Status: ON | Keine Verbindung" ;;
        it:header_on_no_conn) echo "Stato: ON | Nessuna connessione" ;;
        pt:header_on_no_conn) echo "Estado: ON | Sem conexao" ;;
        ru:header_on_no_conn) echo "Status: ON | Net podkliucheniia" ;;
        ja:header_on_no_conn) echo "Jotai: ON | massetsuzoku" ;;
        zh:header_on_no_conn) echo "zhuang tai: ON | wu lian jie" ;;

        es:header_off) echo "Estado: OFF" ;;
        en:header_off) echo "Status: OFF" ;;
        fr:header_off) echo "Etat: OFF" ;;
        de:header_off) echo "Status: OFF" ;;
        it:header_off) echo "Stato: OFF" ;;
        pt:header_off) echo "Estado: OFF" ;;
        ru:header_off) echo "Status: OFF" ;;
        ja:header_off) echo "Jotai: OFF" ;;
        zh:header_off) echo "zhuang tai: OFF" ;;

        es:menu_connect) echo "Conectar a red disponible" ;;
        en:menu_connect) echo "Connect to available network" ;;
        fr:menu_connect) echo "Se connecter a un reseau disponible" ;;
        de:menu_connect) echo "Mit verfuegbarem Netzwerk verbinden" ;;
        it:menu_connect) echo "Connetti a rete disponibile" ;;
        pt:menu_connect) echo "Conectar a rede disponivel" ;;
        ru:menu_connect) echo "Podkliuchitsia k dostupnoi seti" ;;
        ja:menu_connect) echo "Riyou kanou na nettowaku ni setsuzoku" ;;
        zh:menu_connect) echo "lian jie ke yong wang luo" ;;

        es:menu_hidden) echo "Conectar red oculta" ;;
        en:menu_hidden) echo "Connect hidden network" ;;
        fr:menu_hidden) echo "Se connecter a un reseau cache" ;;
        de:menu_hidden) echo "Verstecktes Netzwerk verbinden" ;;
        it:menu_hidden) echo "Connetti rete nascosta" ;;
        pt:menu_hidden) echo "Conectar rede oculta" ;;
        ru:menu_hidden) echo "Podkliuchit skrytuiu set" ;;
        ja:menu_hidden) echo "Kakushi nettowaku ni setsuzoku" ;;
        zh:menu_hidden) echo "lian jie yin cang wang luo" ;;

        es:menu_disconnect) echo "Desconectar WiFi actual" ;;
        en:menu_disconnect) echo "Disconnect current WiFi" ;;
        fr:menu_disconnect) echo "Deconnecter le WiFi actuel" ;;
        de:menu_disconnect) echo "Aktuelles WiFi trennen" ;;
        it:menu_disconnect) echo "Disconnetti WiFi corrente" ;;
        pt:menu_disconnect) echo "Desconectar WiFi atual" ;;
        ru:menu_disconnect) echo "Otkliuchit tekushchii WiFi" ;;
        ja:menu_disconnect) echo "Genzai no WiFi o setsudan" ;;
        zh:menu_disconnect) echo "duan kai dang qian WiFi" ;;

        es:menu_toggle) echo "Activar/Desactivar WiFi" ;;
        en:menu_toggle) echo "Enable/Disable WiFi" ;;
        fr:menu_toggle) echo "Activer/Desactiver le WiFi" ;;
        de:menu_toggle) echo "WiFi ein/aus" ;;
        it:menu_toggle) echo "Attiva/Disattiva WiFi" ;;
        pt:menu_toggle) echo "Ativar/Desativar WiFi" ;;
        ru:menu_toggle) echo "Vkluchit/Otkliuchit WiFi" ;;
        ja:menu_toggle) echo "WiFi on/off" ;;
        zh:menu_toggle) echo "kai qi/guan bi WiFi" ;;

        es:menu_rescan) echo "Reescanear redes" ;;
        en:menu_rescan) echo "Rescan networks" ;;
        fr:menu_rescan) echo "Relancer la recherche" ;;
        de:menu_rescan) echo "Netzwerke neu scannen" ;;
        it:menu_rescan) echo "Riscansiona reti" ;;
        pt:menu_rescan) echo "Reescanear redes" ;;
        ru:menu_rescan) echo "Povtorno skanirovat seti" ;;
        ja:menu_rescan) echo "Nettowaku sai sukyaan" ;;
        zh:menu_rescan) echo "zhong xin sao miao wang luo" ;;

        es:menu_editor) echo "Abrir nm-connection-editor" ;;
        en:menu_editor) echo "Open nm-connection-editor" ;;
        fr:menu_editor) echo "Ouvrir nm-connection-editor" ;;
        de:menu_editor) echo "nm-connection-editor oeffnen" ;;
        it:menu_editor) echo "Apri nm-connection-editor" ;;
        pt:menu_editor) echo "Abrir nm-connection-editor" ;;
        ru:menu_editor) echo "Otkryt nm-connection-editor" ;;
        ja:menu_editor) echo "nm-connection-editor o hiraku" ;;
        zh:menu_editor) echo "da kai nm-connection-editor" ;;

        es:menu_status) echo "Mostrar estado" ;;
        en:menu_status) echo "Show status" ;;
        fr:menu_status) echo "Afficher l'etat" ;;
        de:menu_status) echo "Status anzeigen" ;;
        it:menu_status) echo "Mostra stato" ;;
        pt:menu_status) echo "Mostrar status" ;;
        ru:menu_status) echo "Pokazat status" ;;
        ja:menu_status) echo "Jotai o hyouji" ;;
        zh:menu_status) echo "xian shi zhuang tai" ;;

        es:title_main) echo "Control de red" ;;
        en:title_main) echo "Network Control" ;;
        fr:title_main) echo "Controle reseau" ;;
        de:title_main) echo "Netzwerksteuerung" ;;
        it:title_main) echo "Controllo rete" ;;
        pt:title_main) echo "Controle de rede" ;;
        ru:title_main) echo "Upravlenie setiu" ;;
        ja:title_main) echo "Nettowaku kontororu" ;;
        zh:title_main) echo "wang luo kong zhi" ;;

        es:title_networks) echo "Redes WiFi" ;;
        en:title_networks) echo "WiFi Networks" ;;
        fr:title_networks) echo "Reseaux WiFi" ;;
        de:title_networks) echo "WiFi-Netzwerke" ;;
        it:title_networks) echo "Reti WiFi" ;;
        pt:title_networks) echo "Redes WiFi" ;;
        ru:title_networks) echo "Seti WiFi" ;;
        ja:title_networks) echo "WiFi nettowaku" ;;
        zh:title_networks) echo "WiFi wang luo" ;;

        es:prompt_choose_network) echo "Selecciona red" ;;
        en:prompt_choose_network) echo "Select network" ;;
        fr:prompt_choose_network) echo "Selectionner reseau" ;;
        de:prompt_choose_network) echo "Netzwerk auswaehlen" ;;
        it:prompt_choose_network) echo "Seleziona rete" ;;
        pt:prompt_choose_network) echo "Selecionar rede" ;;
        ru:prompt_choose_network) echo "Vyberite set" ;;
        ja:prompt_choose_network) echo "Nettowaku o sentaku" ;;
        zh:prompt_choose_network) echo "xuan ze wang luo" ;;

        es:title_password) echo "Password WiFi" ;;
        en:title_password) echo "WiFi Password" ;;
        fr:title_password) echo "Mot de passe WiFi" ;;
        de:title_password) echo "WiFi-Passwort" ;;
        it:title_password) echo "Password WiFi" ;;
        pt:title_password) echo "Senha WiFi" ;;
        ru:title_password) echo "Parol WiFi" ;;
        ja:title_password) echo "WiFi pasuwaado" ;;
        zh:title_password) echo "WiFi mi ma" ;;

        es:prompt_password) echo "Clave para %s" ;;
        en:prompt_password) echo "Password for %s" ;;
        fr:prompt_password) echo "Mot de passe pour %s" ;;
        de:prompt_password) echo "Passwort fuer %s" ;;
        it:prompt_password) echo "Password per %s" ;;
        pt:prompt_password) echo "Senha para %s" ;;
        ru:prompt_password) echo "Parol dlia %s" ;;
        ja:prompt_password) echo "%s no pasuwaado" ;;
        zh:prompt_password) echo "%s de mi ma" ;;

        es:title_hidden) echo "Conectar red oculta" ;;
        en:title_hidden) echo "Connect hidden network" ;;
        fr:title_hidden) echo "Connexion reseau cache" ;;
        de:title_hidden) echo "Verstecktes Netzwerk verbinden" ;;
        it:title_hidden) echo "Connetti rete nascosta" ;;
        pt:title_hidden) echo "Conectar rede oculta" ;;
        ru:title_hidden) echo "Podkliuchit skrytuiu set" ;;
        ja:title_hidden) echo "Kakushi nettowaku ni setsuzoku" ;;
        zh:title_hidden) echo "lian jie yin cang wang luo" ;;

        es:title_hidden_ssid) echo "Conectar %s" ;;
        en:title_hidden_ssid) echo "Connect %s" ;;
        fr:title_hidden_ssid) echo "Connecter %s" ;;
        de:title_hidden_ssid) echo "%s verbinden" ;;
        it:title_hidden_ssid) echo "Connetti %s" ;;
        pt:title_hidden_ssid) echo "Conectar %s" ;;
        ru:title_hidden_ssid) echo "Podkliuchit %s" ;;
        ja:title_hidden_ssid) echo "%s ni setsuzoku" ;;
        zh:title_hidden_ssid) echo "lian jie %s" ;;

        es:prompt_hidden_ssid) echo "SSID oculta" ;;
        en:prompt_hidden_ssid) echo "Hidden SSID" ;;
        fr:prompt_hidden_ssid) echo "SSID cache" ;;
        de:prompt_hidden_ssid) echo "Versteckte SSID" ;;
        it:prompt_hidden_ssid) echo "SSID nascosto" ;;
        pt:prompt_hidden_ssid) echo "SSID oculta" ;;
        ru:prompt_hidden_ssid) echo "Skrytyi SSID" ;;
        ja:prompt_hidden_ssid) echo "Kakushi SSID" ;;
        zh:prompt_hidden_ssid) echo "yin cang SSID" ;;

        es:prompt_hidden_pass) echo "Clave (vacia = abierta)" ;;
        en:prompt_hidden_pass) echo "Password (empty = open)" ;;
        fr:prompt_hidden_pass) echo "Mot de passe (vide = ouvert)" ;;
        de:prompt_hidden_pass) echo "Passwort (leer = offen)" ;;
        it:prompt_hidden_pass) echo "Password (vuoto = aperta)" ;;
        pt:prompt_hidden_pass) echo "Senha (vazia = aberta)" ;;
        ru:prompt_hidden_pass) echo "Parol (pusto = otkryta)" ;;
        ja:prompt_hidden_pass) echo "Pasuwaado (kara = open)" ;;
        zh:prompt_hidden_pass) echo "mi ma (kong = kai fang)" ;;

        * ) echo "$key" ;;
    esac
}

tf() {
    local key="$1"
    shift
    local format
    format="$(t "$key")"
    printf "$format" "$@"
}

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
            notify "$(tf connected "$ssid")"
            return 0
        fi
    fi

    if [[ -z "$security" || "$security" == "--" ]]; then
        if nmcli device wifi connect "$ssid" >/dev/null 2>&1; then
            notify "$(tf connected "$ssid")"
            return 0
        fi
        notify "$(tf connect_failed "$ssid")"
        return 1
    fi

    pass=$(wofi_input "$(tf prompt_password "$ssid")" "$(t title_password)")
    if [[ -z "$pass" ]]; then
        notify "$(t connect_canceled)"
        return 1
    fi

    if nmcli device wifi connect "$ssid" password "$pass" >/dev/null 2>&1; then
        notify "$(tf connected "$ssid")"
        return 0
    fi

    notify "$(tf connect_failed "$ssid")"
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
        notify "$(t no_networks)"
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
        notify "$(t no_networks)"
        return 0
    fi

    choice=$(printf "%s\n" "${labels[@]}" | wofi_menu "$(t prompt_choose_network)" "$(t title_networks)")
    [[ -z "$choice" ]] && return 0

    for i in "${!labels[@]}"; do
        if [[ "${labels[$i]}" == "$choice" ]]; then
            connect_to_ssid "${ssids[$i]}" "${securities[$i]}"
            return $?
        fi
    done

    notify "$(t invalid_selection)"
    return 1
}

menu_hidden_network() {
    local ssid pass

    ensure_wifi_on

    ssid=$(wofi_input "$(t prompt_hidden_ssid)" "$(t title_hidden)")
    [[ -z "$ssid" ]] && return 0

    pass=$(wofi_input "$(t prompt_hidden_pass)" "$(tf title_hidden_ssid "$ssid")")

    if [[ -z "$pass" ]]; then
        if nmcli device wifi connect "$ssid" hidden yes >/dev/null 2>&1; then
            notify "$(tf connected "$ssid")"
            return 0
        fi
        notify "$(tf connect_failed "$ssid")"
        return 1
    fi

    if nmcli device wifi connect "$ssid" password "$pass" hidden yes >/dev/null 2>&1; then
        notify "$(tf connected "$ssid")"
        return 0
    fi

    notify "$(tf connect_failed "$ssid")"
    return 1
}

menu_disconnect() {
    local active
    active=$(nmcli -t -f NAME,TYPE connection show --active | awk -F: '$2=="802-11-wireless"{print $1; exit}')
    if [[ -z "$active" ]]; then
        notify "$(t no_active_wifi)"
        return 0
    fi

    if nmcli connection down id "$active" >/dev/null 2>&1; then
        notify "$(t wifi_disconnected)"
        return 0
    fi

    notify "$(t disconnect_failed)"
    return 1
}

menu_toggle_wifi() {
    if [[ "$(wifi_state)" == "enabled" ]]; then
        nmcli radio wifi off
        notify "$(t wifi_off)"
    else
        nmcli radio wifi on
        notify "$(t wifi_on)"
    fi
}

show_info() {
    local state ssid ipaddr
    state=$(wifi_state)
    ssid=$(current_ssid)
    ipaddr=$(current_ip)

    if [[ "$state" != "enabled" ]]; then
        notify "$(t state_off)"
        return
    fi

    if [[ -z "$ssid" ]]; then
        notify "$(t state_on_no_conn)"
        return
    fi

    notify "$(tf state_connected "$ssid" "${ipaddr:--}")"
}

if ! command -v nmcli >/dev/null 2>&1; then
    notify "$(t missing_nmcli)"
    exit 1
fi

if ! command -v wofi >/dev/null 2>&1; then
    notify "$(t missing_wofi)"
    exit 1
fi

status="$(wifi_state)"
ssid="$(current_ssid)"
ipaddr="$(current_ip)"

if [[ "$status" == "enabled" ]]; then
    if [[ -n "$ssid" ]]; then
        header="$(tf header_on_connected "$ssid" "${ipaddr:--}")"
    else
        header="$(t header_on_no_conn)"
    fi
else
    header="$(t header_off)"
fi

action_connect="$(t menu_connect)"
action_hidden="$(t menu_hidden)"
action_disconnect="$(t menu_disconnect)"
action_toggle="$(t menu_toggle)"
action_rescan="$(t menu_rescan)"
action_editor="$(t menu_editor)"
action_status="$(t menu_status)"

selection=$(printf "%s\n" \
    "$header" \
    "$action_connect" \
    "$action_hidden" \
    "$action_disconnect" \
    "$action_toggle" \
    "$action_rescan" \
    "$action_editor" \
    "$action_status" | wofi_menu "WiFi" "$(t title_main)")

case "$selection" in
    "$action_connect")
        menu_connect_network
        ;;
    "$action_hidden")
        menu_hidden_network
        ;;
    "$action_disconnect")
        menu_disconnect
        ;;
    "$action_toggle")
        menu_toggle_wifi
        ;;
    "$action_rescan")
        ensure_wifi_on
        nmcli device wifi rescan >/dev/null 2>&1 || true
        notify "$(t scan_done)"
        ;;
    "$action_editor")
        nm-connection-editor >/dev/null 2>&1 &
        ;;
    "$action_status")
        show_info
        ;;
esac
