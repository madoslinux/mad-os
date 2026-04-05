import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root
    focus: true

    // -------------------------------------------------------------------------
    // KEYBOARD SHORTCUTS
    // -------------------------------------------------------------------------
    Keys.onEscapePressed: {
        closeSequence.start();
        event.accepted = true;
    }
    Keys.onTabPressed: {
        currentTab = (currentTab + 1) % tabNames.length;
        event.accepted = true;
    }
    Keys.onBacktabPressed: {
        currentTab = (currentTab - 1 + tabNames.length) % tabNames.length;
        event.accepted = true;
    }

    MatugenColors { id: _theme }
    
    // -------------------------------------------------------------------------
    // COLORS
    // -------------------------------------------------------------------------
    readonly property color base: _theme.base
    readonly property color mantle: _theme.mantle
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color subtext1: _theme.subtext1
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color overlay0: _theme.overlay0
    
    readonly property color mauve: _theme.mauve
    readonly property color pink: _theme.pink
    readonly property color blue: _theme.blue
    readonly property color sapphire: _theme.sapphire
    readonly property color green: _theme.green
    readonly property color peach: _theme.peach
    readonly property color yellow: _theme.yellow
    readonly property color red: _theme.red

    property real colorBlend: 0.0
    SequentialAnimation on colorBlend {
        loops: Animation.Infinite; running: true
        NumberAnimation { to: 1.0; duration: 15000; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.0; duration: 15000; easing.type: Easing.InOutSine }
    }
    property color ambientPurple: Qt.tint(root.mauve, Qt.rgba(root.pink.r, root.pink.g, root.pink.b, colorBlend))
    property color ambientBlue: Qt.tint(root.blue, Qt.rgba(root.sapphire.r, root.sapphire.g, root.sapphire.b, colorBlend))

    // -------------------------------------------------------------------------
    // STATE MANAGEMENT & FAST ANIMATIONS
    // -------------------------------------------------------------------------
    property int currentTab: 0
    property var tabNames: ["About", "Modules", "Keybinds", "Matugen"]
    property var tabIcons: ["", "󰣆", "󰌌", "󰏘"]

    property real introBase: 0.0
    property real introSidebar: 0.0
    property real introContent: 0.0

    ListModel { id: dynamicKeybindsModel }
                
    function buildKeybinds() {
        dynamicKeybindsModel.clear();
        
        let binds = [
            { k1: "SUPER", k2: "RETURN", action: "Open Terminal (Kitty)", cmd: "kitty" },
            { k1: "SUPER", k2: "D", action: "App Launcher (Drun)", cmd: "bash ~/.config/hypr/scripts/rofi_show.sh drun" },
            { k1: "ALT", k2: "TAB", action: "Window Switcher", cmd: "bash ~/.config/hypr/scripts/rofi_show.sh window" },
            { k1: "SUPER", k2: "C", action: "Clipboard History", cmd: "bash ~/.config/hypr/scripts/rofi_clipboard.sh" },
            { k1: "SUPER", k2: "F", action: "Open Firefox", cmd: "firefox" },
            { k1: "SUPER", k2: "E", action: "Open Nautilus", cmd: "nautilus" },
            { k1: "SUPER", k2: "Q", action: "Close Active Window/Widget", cmd: "bash -c 'if hyprctl activewindow | grep -q \"title: qs-master\"; then ~/.config/hypr/scripts/qs_manager.sh close; else hyprctl dispatch killactive; fi'" },
            { k1: "SUPER+SHIFT", k2: "F", action: "Toggle Floating", cmd: "hyprctl dispatch togglefloating" },
            { k1: "SUPER", k2: "L", action: "Lock Screen", cmd: "bash ~/.config/hypr/scripts/lock.sh" },
            { k1: "PRINT", k2: "", action: "Screenshot", cmd: "bash ~/.config/hypr/scripts/screenshot.sh" },
            { k1: "SHIFT", k2: "PRINT", action: "Screenshot (Edit)", cmd: "bash ~/.config/hypr/scripts/screenshot.sh --edit" },
            { k1: "ALT+SHIFT", k2: "", action: "Switch Keyboard Layout", cmd: "hyprctl switchxkblayout main next" },
            
            { k1: "SUPER", k2: "W", action: "Toggle Wallpaper Picker", cmd: "bash ~/.config/hypr/scripts/qs_manager.sh toggle wallpaper" },
            { k1: "SUPER", k2: "R", action: "Toggle Music Widget", cmd: "bash ~/.config/hypr/scripts/qs_manager.sh toggle music" },
            { k1: "SUPER", k2: "B", action: "Toggle Battery Widget", cmd: "bash ~/.config/hypr/scripts/qs_manager.sh toggle battery" },
            { k1: "SUPER", k2: "S", action: "Toggle Calendar Widget", cmd: "bash ~/.config/hypr/scripts/qs_manager.sh toggle calendar" },
            { k1: "SUPER", k2: "N", action: "Toggle Network Widget", cmd: "bash ~/.config/hypr/scripts/qs_manager.sh toggle network" },
            { k1: "SUPER", k2: "V", action: "Toggle Volume Widget", cmd: "bash ~/.config/hypr/scripts/qs_manager.sh toggle volume" },
            { k1: "SUPER", k2: "M", action: "Toggle Monitors Widget", cmd: "bash ~/.config/hypr/scripts/qs_manager.sh toggle monitors" },
            { k1: "SUPER+SHIFT", k2: "T", action: "Toggle FocusTime", cmd: "bash ~/.config/hypr/scripts/qs_manager.sh toggle focustime" },
            { k1: "SUPER+SHIFT", k2: "S", action: "Toggle Stewart AI", cmd: "bash ~/.config/hypr/scripts/qs_manager.sh toggle stewart" },
            { k1: "SUPER", k2: "A", action: "Toggle SwayNC Panel", cmd: "swaync-client -t -sw" },

            { k1: "SUPER", k2: "SPACE", action: "Play/Pause Media", cmd: "playerctl play-pause" },
            { k1: "Media", k2: "Play/Pause", action: "Play/Pause Media", cmd: "playerctl play-pause" },
            { k1: "Media", k2: "Vol Up/Down", action: "Adjust Volume", cmd: "swayosd-client --output-volume raise" },
            { k1: "Media", k2: "Mute", action: "Mute Volume", cmd: "swayosd-client --output-volume mute-toggle" },
            { k1: "Media", k2: "Mic Mute", action: "Mute Microphone", cmd: "swayosd-client --input-volume mute-toggle" },
            { k1: "Media", k2: "Brightness", action: "Adjust Brightness", cmd: "swayosd-client --brightness raise" },
            { k1: "CAPS", k2: "LOCK", action: "Caps Lock OSD", cmd: "swayosd-client --caps-lock" },

            { k1: "SUPER", k2: "ARROWS", action: "Move Focus", cmd: "hyprctl dispatch movefocus r" },
            { k1: "SUPER+CTRL", k2: "ARROWS", action: "Move Window", cmd: "hyprctl dispatch movewindow r" },
            { k1: "SUPER+SHIFT", k2: "ARROWS", action: "Resize Window", cmd: "hyprctl dispatch resizeactive 50 0" }
        ];

        for (let item of binds) {
            dynamicKeybindsModel.append(item);
        }
    }

    Component.onCompleted: {
        startupSequence.start();
        buildKeybinds();
    }

    SequentialAnimation {
        id: startupSequence
        PauseAnimation { duration: 50 }
        NumberAnimation { target: root; property: "introBase"; to: 1.0; duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        NumberAnimation { target: root; property: "introSidebar"; to: 1.0; duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
        NumberAnimation { target: root; property: "introContent"; to: 1.0; duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
    }

    SequentialAnimation {
        id: closeSequence
        ParallelAnimation {
            NumberAnimation { target: root; property: "introContent"; to: 0.0; duration: 150; easing.type: Easing.InExpo }
            NumberAnimation { target: root; property: "introSidebar"; to: 0.0; duration: 150; easing.type: Easing.InExpo }
        }
        NumberAnimation { target: root; property: "introBase"; to: 0.0; duration: 200; easing.type: Easing.InQuart }
        ScriptAction { script: Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]) }
    }

    // -------------------------------------------------------------------------
    // BACKGROUND AMBIENCE
    // -------------------------------------------------------------------------
    Item {
        anchors.fill: parent
        opacity: introBase
        scale: 0.95 + (0.05 * introBase)

        Rectangle {
            anchors.fill: parent
            radius: 16
            color: root.base
            border.color: root.surface0
            border.width: 1
            clip: true

            property real time: 0
            NumberAnimation on time { from: 0; to: Math.PI * 2; duration: 20000; loops: Animation.Infinite; running: true }

            Rectangle {
                width: 600; height: 600; radius: 300
                x: parent.width * 0.6 + Math.cos(parent.time) * 100
                y: parent.height * 0.1 + Math.sin(parent.time * 1.5) * 100
                color: root.ambientPurple
                opacity: 0.04
                layer.enabled: true; layer.effect: MultiEffect { blurEnabled: true; blurMax: 80; blur: 1.0 }
            }

            Rectangle {
                width: 700; height: 700; radius: 350
                x: parent.width * 0.1 + Math.sin(parent.time * 0.8) * 150
                y: parent.height * 0.4 + Math.cos(parent.time * 1.2) * 100
                color: root.ambientBlue
                opacity: 0.03
                layer.enabled: true; layer.effect: MultiEffect { blurEnabled: true; blurMax: 90; blur: 1.0 }
            }
        }
    }

    // -------------------------------------------------------------------------
    // MAIN LAYOUT
    // -------------------------------------------------------------------------
    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // ==========================================
        // SIDEBAR
        // ==========================================
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 220
            radius: 12
            color: Qt.alpha(root.surface0, 0.4)
            border.color: root.surface1; border.width: 1
            
            opacity: introSidebar
            transform: Translate { x: -30 * (1.0 - introSidebar) }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 10

                // Header
                Item {
                    Layout.fillWidth: true; Layout.preferredHeight: 60
                    RowLayout {
                        anchors.fill: parent
                        spacing: 12
                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            width: 36; height: 36; radius: 10
                            color: root.ambientPurple
                            Text { anchors.centerIn: parent; text: "󰣇"; font.family: "Iosevka Nerd Font"; font.pixelSize: 20; color: root.base }
                        }
                        ColumnLayout {
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2
                            Text { text: "Imperative"; font.family: "Michroma"; font.weight: Font.Black; font.pixelSize: 15; color: root.text; Layout.alignment: Qt.AlignLeft }
                            Text { text: "v1.0.4"; font.family: "Michroma"; font.pixelSize: 11; color: root.subtext0; Layout.alignment: Qt.AlignLeft }
                        }
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.alpha(root.surface1, 0.5); Layout.bottomMargin: 10 }

                // Tabs
                Repeater {
                    model: root.tabNames.length
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: 8
                        
                        property bool isActive: root.currentTab === index
                        color: isActive ? root.surface1 : (tabMa.containsMouse ? Qt.alpha(root.surface1, 0.5) : "transparent")
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 15; spacing: 12
                            Item {
                                Layout.preferredWidth: 24; Layout.alignment: Qt.AlignVCenter
                                Text { anchors.centerIn: parent; text: root.tabIcons[index]; font.family: "Iosevka Nerd Font"; font.pixelSize: 18; color: parent.parent.parent.isActive ? root.ambientPurple : root.subtext0; Behavior on color { ColorAnimation{duration:150} } }
                            }
                            Text { text: root.tabNames[index]; font.family: "Michroma"; font.weight: parent.parent.isActive ? Font.Bold : Font.Medium; font.pixelSize: 13; color: parent.parent.isActive ? root.text : root.subtext0; Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter; Behavior on color { ColorAnimation{duration:150} } }
                        }
                        
                        Rectangle {
                            anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                            width: 3; height: parent.isActive ? 20 : 0; radius: 2
                            color: root.ambientPurple
                            Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                        }

                        MouseArea {
                            id: tabMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentTab = index
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Close Button
                Rectangle {
                    Layout.fillWidth: true; Layout.preferredHeight: 44; radius: 8
                    color: closeHover.containsMouse ? Qt.alpha(root.red, 0.1) : "transparent"
                    border.color: closeHover.containsMouse ? root.red : root.surface1
                    border.width: 1
                    scale: closeHover.pressed ? 0.95 : (closeHover.containsMouse ? 1.02 : 1.0)
                    
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Item {
                        anchors.centerIn: parent
                        width: arrowText.implicitWidth; height: arrowText.implicitHeight
                        Text { 
                            id: arrowText
                            text: "" 
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 16
                            color: closeHover.containsMouse ? root.red : root.subtext0
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                    MouseArea { id: closeHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: closeSequence.start() }
                }
            }
        }

        // ==========================================
        // CONTENT AREA
        // ==========================================
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            opacity: introContent
            scale: 0.95 + (0.05 * introContent)
            transform: Translate { y: 20 * (1.0 - introContent) }

            // ------------------------------------------
            // TAB 0: SYSTEM OVERVIEW
            // ------------------------------------------
            Item {
                anchors.fill: parent
                visible: root.currentTab === 0
                opacity: visible ? 1.0 : 0.0
                property real slideY: visible ? 0 : 10
                Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                transform: Translate { y: slideY }
                Behavior on opacity { NumberAnimation { duration: 250 } }

                ListModel {
                    id: systemDataModel
                    ListElement { pkg: "Hyprland"; role: "Wayland Compositor"; icon: ""; clr: "blue"; link: "https://hyprland.org/" }
                    ListElement { pkg: "Quickshell"; role: "UI Framework"; icon: "󰣆"; clr: "mauve"; link: "https://git.outfoxxed.me/outfoxxed/quickshell" }
                    ListElement { pkg: "Matugen"; role: "Theme Engine"; icon: "󰏘"; clr: "peach"; link: "https://github.com/InioX/matugen" }
                    ListElement { pkg: "Rofi Wayland"; role: "App Launcher"; icon: ""; clr: "green"; link: "https://github.com/lbonn/rofi" }
                    ListElement { pkg: "Kitty"; role: "Terminal Emulator"; icon: "󰄛"; clr: "yellow"; link: "https://sw.kovidgoyal.net/kitty/" }
                    ListElement { pkg: "SwayOSD / NC"; role: "Overlays & Notifs"; icon: "󰂚"; clr: "pink"; link: "https://github.com/ErikReider/SwayOSD" }
                }

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 20; spacing: 20

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 182
                        radius: 12
                        color: Qt.alpha(root.surface0, 0.35)
                        border.color: root.surface1
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            Text {
                                text: "About"
                                font.family: "Michroma"
                                font.weight: Font.Black
                                font.pixelSize: 16
                                color: root.text
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 64
                                radius: 10
                                color: authorMa.containsMouse ? Qt.alpha(root.surface1, 0.6) : Qt.alpha(root.surface0, 0.4)
                                border.color: authorMa.containsMouse ? root.blue : root.surface1
                                border.width: 1
                                scale: authorMa.pressed ? 0.98 : (authorMa.containsMouse ? 1.01 : 1.0)

                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    Rectangle {
                                        Layout.alignment: Qt.AlignVCenter
                                        width: 38; height: 38; radius: 8
                                        color: root.surface0
                                        border.color: root.surface2; border.width: 1
                                        Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: 20; color: root.text }
                                    }

                                    ColumnLayout {
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 1
                                        Text { text: "madOS Distro Author"; font.family: "Michroma"; font.pixelSize: 10; color: root.subtext0; font.weight: Font.Medium }
                                        Text { text: "madkoding"; font.family: "Michroma"; font.pixelSize: 16; font.weight: Font.Black; color: root.blue }
                                    }

                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        Layout.alignment: Qt.AlignVCenter
                                        width: 28; height: 28; radius: 8
                                        color: authorMa.containsMouse ? root.surface1 : "transparent"
                                        Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: 16; color: authorMa.containsMouse ? root.blue : root.subtext0; Behavior on color { ColorAnimation { duration: 150 } } }
                                    }
                                }

                                MouseArea {
                                    id: authorMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/madkoding"])
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 64
                                radius: 10
                                color: distroMa.containsMouse ? Qt.alpha(root.surface1, 0.6) : Qt.alpha(root.surface0, 0.4)
                                border.color: distroMa.containsMouse ? root.mauve : root.surface1
                                border.width: 1
                                scale: distroMa.pressed ? 0.98 : (distroMa.containsMouse ? 1.01 : 1.0)

                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 12

                                    Rectangle {
                                        Layout.alignment: Qt.AlignVCenter
                                        width: 38; height: 38; radius: 8
                                        color: root.surface0
                                        border.color: root.surface2; border.width: 1
                                        Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: 22; color: root.text }
                                    }

                                    ColumnLayout {
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 1
                                        Text { text: "System Configuration Author"; font.family: "Michroma"; font.pixelSize: 10; color: root.subtext0; font.weight: Font.Medium }
                                        Text { text: "ilyamiro"; font.family: "Michroma"; font.pixelSize: 16; font.weight: Font.Black; color: root.mauve }
                                    }

                                    Item { Layout.fillWidth: true }
                                    Rectangle {
                                        Layout.alignment: Qt.AlignVCenter
                                        width: 28; height: 28; radius: 8
                                        color: distroMa.containsMouse ? root.surface1 : "transparent"
                                        Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: 16; color: distroMa.containsMouse ? root.mauve : root.subtext0; Behavior on color { ColorAnimation { duration: 150 } } }
                                    }
                                }

                                MouseArea {
                                    id: distroMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Quickshell.execDetached(["xdg-open", "https://github.com/ilyamiro/nixos-configuration"])
                                }
                            }
                        }
                    }

                    Text { text: "System Architecture"; font.family: "Michroma"; font.weight: Font.Black; font.pixelSize: 28; color: root.text; Layout.alignment: Qt.AlignVCenter; Layout.topMargin: 5 }
                    
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 15; columnSpacing: 15

                        Repeater {
                            model: systemDataModel
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 70; radius: 10
                                color: sysCardMa.containsMouse ? Qt.alpha(root[model.clr], 0.1) : Qt.alpha(root.surface0, 0.4)
                                border.color: sysCardMa.containsMouse ? root[model.clr] : root.surface1; border.width: 1
                                scale: sysCardMa.pressed ? 0.98 : 1.0
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuart } }
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }
                                
                                // COMPLETELY REWRITTEN LAYOUT: Absolute anchors bypass implicit spacing errors
                                Item {
                                    anchors.fill: parent
                                    anchors.margins: 15
                                    
                                    // 1. Icon strictly anchored to the exact left wall
                                    Item {
                                        id: sysIconBox
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 40; height: 40
                                        Text { anchors.centerIn: parent; text: model.icon; font.family: "Iosevka Nerd Font"; font.pixelSize: 24; color: root[model.clr] }
                                    }
                                    
                                    // 2. Text mathematically forced 15px from the icon box right edge
                                    Column {
                                        anchors.left: sysIconBox.right
                                        anchors.leftMargin: 15
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2
                                        Text { text: model.pkg; font.family: "Michroma"; font.weight: Font.Bold; font.pixelSize: 15; color: root.text }
                                        Text { text: model.role; font.family: "Michroma"; font.pixelSize: 12; color: root.subtext0 }
                                    }
                                }
                                MouseArea { 
                                    id: sysCardMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor 
                                    onClicked: Quickshell.execDetached(["xdg-open", model.link])
                                }
                            }
                        }
                    }
                    Item { Layout.fillHeight: true }
                }
            }

            // ------------------------------------------
            // TAB 1: MODULES
            // ------------------------------------------
            Item {
                anchors.fill: parent
                visible: root.currentTab === 1
                opacity: visible ? 1.0 : 0.0
                property real slideY: visible ? 0 : 10
                Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                transform: Translate { y: slideY }
                Behavior on opacity { NumberAnimation { duration: 250 } }

                ListModel {
                    id: modulesDataModel
                    ListElement { title: "Calendar & Weather"; target: "calendar"; icon: ""; desc: "Dual-sync calendar with live \nOpenWeatherMap integration." }
                    ListElement { title: "Media & Lyrics"; target: "music"; icon: "󰎆"; desc: "PlayerCtl integration, Cava \nvisualizer, and live lyrics." }
                    ListElement { title: "Battery & Power"; target: "battery"; icon: "󰁹"; desc: "Uptime tracking, power profiles, \nand battery health metrics." }
                    ListElement { title: "Network Hub"; target: "network"; icon: "󰤨"; desc: "Wi-Fi and Bluetooth connection \nmanagement via nmcli/bluez." }
                    ListElement { title: "FocusTime"; target: "focustime"; icon: "󰄉"; desc: "Built-in Pomodoro timer daemon \nwith session tracking." }
                    ListElement { title: "Volume Mixer"; target: "volume"; icon: "󰕾"; desc: "Pipewire integration for I/O \nvolume and stream routing." }
                    ListElement { title: "Wallpaper Picker"; target: "wallpaper"; icon: ""; desc: "Live awww backend rendering \nwith Matugen color generation." }
                    ListElement { title: "Monitors"; target: "monitors"; icon: "󰍹"; desc: "Quick display management." }
                    ListElement { title: "Stewart AI"; target: "stewart"; icon: "󰚩"; desc: "Voice assistant integration.\n(Reserved for future, currently disabled)" }
                }

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 20; spacing: 20

                    Text { text: "Interactive Modules"; font.family: "Michroma"; font.weight: Font.Black; font.pixelSize: 28; color: root.text; Layout.alignment: Qt.AlignVCenter }
                    Text { text: "Click any card to toggle the live module overlay."; font.family: "Michroma"; font.pixelSize: 14; color: root.subtext0; Layout.alignment: Qt.AlignVCenter }
                    
                    ScrollView {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        contentWidth: availableWidth
                        clip: true; ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        
                        GridLayout {
                            width: parent.width
                            columns: 2
                            columnSpacing: 15
                            rowSpacing: 15
                            
                            Repeater {
                                model: modulesDataModel
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 100
                                    radius: 12
                                    color: modMa.containsMouse ? root.surface1 : Qt.alpha(root.surface0, 0.4)
                                    border.color: modMa.containsMouse ? root.ambientBlue : root.surface1; border.width: 1
                                    clip: true
                                    
                                    scale: modMa.pressed ? 0.96 : (modMa.containsMouse ? 1.02 : 1.0)
                                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    Behavior on border.color { ColorAnimation { duration: 200 } }

                                    ColumnLayout {
                                        anchors.fill: parent; anchors.margins: 15; spacing: 8
                                        RowLayout {
                                            spacing: 10
                                            Rectangle {
                                                Layout.alignment: Qt.AlignVCenter
                                                width: 32; height: 32; radius: 8; color: Qt.alpha(root.base, 0.5)
                                                Text { anchors.centerIn: parent; text: model.icon; font.family: "Iosevka Nerd Font"; font.pixelSize: 16; color: modMa.containsMouse ? root.ambientBlue : root.text }
                                            }
                                            Text { text: model.title; font.family: "Michroma"; font.weight: Font.Bold; font.pixelSize: 13; color: root.text; Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter }
                                        }
                                        Text {
                                            text: model.desc; font.family: "Michroma"; font.pixelSize: 11; color: root.subtext0; Layout.alignment: Qt.AlignLeft
                                            opacity: 1.0
                                        }
                                    }
                                    MouseArea { 
                                        id: modMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor 
                                        onClicked: Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "toggle", model.target])
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ------------------------------------------
            // TAB 2: KEYBINDS
            // ------------------------------------------
            Item {
                anchors.fill: parent
                visible: root.currentTab === 2
                opacity: visible ? 1.0 : 0.0
                property real slideY: visible ? 0 : 10
                Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                transform: Translate { y: slideY }
                Behavior on opacity { NumberAnimation { duration: 250 } }

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 20; spacing: 20

                    Text { text: "Navigation & Control"; font.family: "Michroma"; font.weight: Font.Black; font.pixelSize: 28; color: root.text; Layout.alignment: Qt.AlignVCenter }
                    Text { text: "Click any row below to instantly execute the keybind command."; font.family: "Michroma"; font.pixelSize: 14; color: root.subtext0; Layout.alignment: Qt.AlignVCenter }
                    
                    ScrollView {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        contentWidth: availableWidth
                        clip: true; ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                        
                        GridLayout {
                            width: parent.width; columns: 2; rowSpacing: 10; columnSpacing: 15
                            
                            Rectangle {
                                Layout.columnSpan: 2
                                Layout.fillWidth: true; Layout.preferredHeight: 60; radius: 8
                                color: Qt.alpha(root.surface0, 0.4)
                                border.color: root.surface1; border.width: 1

                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 10; spacing: 10
                                    
                                    Text { text: "Workspaces (SUPER + 1-9)"; font.family: "Michroma"; font.weight: Font.Bold; font.pixelSize: 13; color: root.text; Layout.alignment: Qt.AlignVCenter }
                                    Item { Layout.fillWidth: true }
                                    
                                    Repeater {
                                        model: 9
                                        Rectangle {
                                            property int wsNum: index + 1
                                            Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 6
                                            color: wsMa.containsMouse ? root.surface1 : root.surface0
                                            border.color: wsMa.containsMouse ? root.peach : "transparent"; border.width: 1
                                            Text { anchors.centerIn: parent; text: parent.wsNum; font.family: "Michroma"; font.weight: Font.Bold; font.pixelSize: 12; color: root.peach }
                                            
                                            MouseArea {
                                                id: wsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                onClicked: Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", wsNum.toString()])
                                            }
                                        }
                                    }
                                }
                            }

                            Repeater {
                                model: dynamicKeybindsModel
                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 46; radius: 8
                                    color: bindMa.containsMouse ? root.surface1 : Qt.alpha(root.surface0, 0.4)
                                    border.color: bindMa.containsMouse ? root.peach : "transparent"
                                    border.width: 1
                                    scale: bindMa.pressed ? 0.98 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuart } }
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    Behavior on border.color { ColorAnimation { duration: 150 } }

                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 10; spacing: 15
                                        
                                        Item {
                                            Layout.preferredWidth: 220
                                            Layout.minimumWidth: 220
                                            Layout.maximumWidth: 220
                                            Layout.fillHeight: true
                                            Row {
                                                anchors.verticalCenter: parent.verticalCenter; spacing: 8
                                                Rectangle { 
                                                    width: k1Text.implicitWidth + 16; height: 26; radius: 4; color: root.surface0; border.color: root.surface2; border.width: 1
                                                    Text { id: k1Text; anchors.centerIn: parent; text: model.k1; font.family: "Michroma"; font.weight: Font.Bold; font.pixelSize: 11; color: root.peach }
                                                }
                                                Text { text: "+"; font.family: "Michroma"; font.pixelSize: 12; color: root.overlay0; visible: model.k2 !== ""; anchors.verticalCenter: parent.verticalCenter }
                                                Rectangle { 
                                                    width: k2Text.implicitWidth + 16; height: 26; radius: 4; color: root.surface0; border.color: root.surface2; border.width: 1; visible: model.k2 !== ""
                                                    Text { id: k2Text; anchors.centerIn: parent; text: model.k2; font.family: "Michroma"; font.weight: Font.Bold; font.pixelSize: 11; color: root.peach }
                                                }
                                            }
                                        }
                                        
                                        Text { 
                                            text: model.action
                                            font.family: "Michroma"
                                            font.pixelSize: 13
                                            color: root.text
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            horizontalAlignment: Text.AlignLeft
                                            elide: Text.ElideRight
                                            clip: true
                                        }
                                    }
                                    MouseArea {
                                        id: bindMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: Quickshell.execDetached(["bash", "-c", model.cmd])
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ------------------------------------------
            // TAB 3: MATUGEN ENGINE
            // ------------------------------------------
            Item {
                anchors.fill: parent
                visible: root.currentTab === 3
                opacity: visible ? 1.0 : 0.0
                property real slideY: visible ? 0 : 10
                Behavior on slideY { NumberAnimation { duration: 250; easing.type: Easing.OutQuart } }
                transform: Translate { y: slideY }
                Behavior on opacity { NumberAnimation { duration: 250 } }

                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 20; spacing: 20

                    Text { text: "Theming Engine"; font.family: "Michroma"; font.weight: Font.Black; font.pixelSize: 28; color: root.text; Layout.alignment: Qt.AlignVCenter }
                    
                    // Diagram Area
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 160; radius: 12
                        color: Qt.alpha(root.surface0, 0.4); border.color: root.ambientPurple; border.width: 1
                        
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 20; spacing: 20
                            
                            Item { Layout.fillWidth: true } // Left spacer for perfect centering

                            // 1. Wallpaper
                            ColumnLayout {
                                Layout.alignment: Qt.AlignVCenter; spacing: 8
                                Rectangle { Layout.alignment: Qt.AlignHCenter; width: 60; height: 60; radius: 10; color: root.surface1; Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: 28; color: root.text } }
                                Text { text: "Wallpaper"; font.family: "Michroma"; font.weight: Font.Bold; font.pixelSize: 12; color: root.text; Layout.alignment: Qt.AlignHCenter }
                            }
                            
                            // Arrow 1
                            Canvas {
                                Layout.alignment: Qt.AlignVCenter
                                width: 40; height: 24
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.strokeStyle = root.overlay0;
                                    ctx.lineWidth = 2;
                                    ctx.lineCap = "round";
                                    ctx.lineJoin = "round";
                                    ctx.beginPath();
                                    ctx.moveTo(4, 12);
                                    ctx.lineTo(36, 12);
                                    ctx.moveTo(26, 4);
                                    ctx.lineTo(36, 12);
                                    ctx.lineTo(26, 20);
                                    ctx.stroke();
                                }
                            }
                            
                            // 2. Matugen Core
                            Rectangle {
                                width: 180; height: 90; radius: 12; color: root.base; border.color: root.ambientPurple; border.width: 2; Layout.alignment: Qt.AlignVCenter
                                ColumnLayout {
                                    anchors.centerIn: parent; spacing: 8
                                    Text { text: "Matugen Core"; font.family: "Michroma"; font.weight: Font.Black; font.pixelSize: 15; color: root.ambientPurple; Layout.alignment: Qt.AlignHCenter }
                                    RowLayout {
                                        spacing: 4; Layout.alignment: Qt.AlignHCenter
                                        Repeater {
                                            model: [root.red, root.peach, root.yellow, root.green, root.blue, root.mauve]
                                            Rectangle { Layout.alignment: Qt.AlignVCenter; width: 12; height: 12; radius: 6; color: modelData }
                                        }
                                    }
                                }
                            }

                            // Arrow 2
                            Canvas {
                                Layout.alignment: Qt.AlignVCenter
                                width: 40; height: 24
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.strokeStyle = root.overlay0;
                                    ctx.lineWidth = 2;
                                    ctx.lineCap = "round";
                                    ctx.lineJoin = "round";
                                    ctx.beginPath();
                                    ctx.moveTo(4, 12);
                                    ctx.lineTo(36, 12);
                                    ctx.moveTo(26, 4);
                                    ctx.lineTo(36, 12);
                                    ctx.lineTo(26, 20);
                                    ctx.stroke();
                                }
                            }

                            // 3. Output
                            ColumnLayout {
                                Layout.alignment: Qt.AlignVCenter; spacing: 8
                                Rectangle { Layout.alignment: Qt.AlignHCenter; width: 60; height: 60; radius: 10; color: root.surface1; Text { anchors.centerIn: parent; text: "󰏘"; font.family: "Iosevka Nerd Font"; font.pixelSize: 28; color: root.text } }
                                Text { text: "Templates"; font.family: "Michroma"; font.weight: Font.Bold; font.pixelSize: 12; color: root.text; Layout.alignment: Qt.AlignHCenter }
                            }

                            Item { Layout.fillWidth: true } // Right spacer for perfect centering
                        }
                    }

                    Text { text: "When you change wallpapers, Matugen extracts the dominant colors and injects them directly into these configuration files in real-time:"; font.family: "Michroma"; font.pixelSize: 13; color: root.subtext0; Layout.fillWidth: true; wrapMode: Text.WordWrap; Layout.alignment: Qt.AlignVCenter }

                    // Template Files Grid
                    GridLayout {
                        Layout.fillWidth: true; Layout.fillHeight: true
                        columns: 3; rowSpacing: 10; columnSpacing: 10
                        
                        Repeater {
                            model: [
                                { f: "kitty-colors.conf", i: "󰄛", c: "yellow" },
                                { f: "nvim-colors.lua", i: "", c: "green" },
                                { f: "rofi.rasi", i: "", c: "blue" },
                                { f: "cava-colors.ini", i: "󰎆", c: "mauve" },
                                { f: "sddm-colors.qml", i: "󰍃", c: "peach" },
                                { f: "swaync/osd.css", i: "󰂚", c: "pink" }
                            ]
                            Rectangle {
                                Layout.fillWidth: true; Layout.preferredHeight: 45; radius: 8
                                color: tplMa.containsMouse ? Qt.alpha(root[modelData.c], 0.1) : root.surface0
                                border.color: tplMa.containsMouse ? root[modelData.c] : "transparent"
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 10; spacing: 10
                                    Item {
                                        Layout.preferredWidth: 24; Layout.alignment: Qt.AlignVCenter
                                        Text { anchors.centerIn: parent; text: modelData.i; font.family: "Michroma"; font.pixelSize: 16; color: root[modelData.c] }
                                    }
                                    Text { text: modelData.f; font.family: "Michroma"; font.weight: Font.Medium; font.pixelSize: 12; color: root.text; Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter }
                                }
                                MouseArea { id: tplMa; anchors.fill: parent; hoverEnabled: true }
                            }
                        }
                    }
                }
            }
        }
    }
}
