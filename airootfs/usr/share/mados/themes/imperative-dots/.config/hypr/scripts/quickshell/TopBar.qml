import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray

PanelWindow {
    id: barWindow
    property real uiScale: 0.75
    
    anchors {
        top: true
        left: true
        right: true
    }
    
    // Scaled bar dimensions
    height: Math.max(32, Math.round(48 * uiScale))
    margins {
        top: Math.max(4, Math.round(8 * uiScale))
        bottom: 0
        left: Math.max(2, Math.round(4 * uiScale))
        right: Math.max(2, Math.round(4 * uiScale))
    }
    
    // exclusiveZone = bar height + top margin
    exclusiveZone: height + margins.top
    color: "transparent"

    // Dynamic Matugen Palette
    MatugenColors {
        id: mocha
    }

    // --- State Variables ---
    
    // Triggers layout animations immediately to feel fast
    property bool isStartupReady: false
    Timer { interval: 10; running: true; onTriggered: barWindow.isStartupReady = true }
    
    // Prevents repeaters (Workspaces/Tray) from flickering on data updates
    property bool startupCascadeFinished: false
    Timer { interval: 1000; running: true; onTriggered: barWindow.startupCascadeFinished = true }
    
    // Data gating to prevent startup layout jumping
    property bool sysPollerLoaded: false
    property bool fastPollerLoaded: false
    
    // FIXED: Only wait for the instant data to load the UI. 
    // The slow network scripts will populate smoothly when they finish.
    property bool isDataReady: fastPollerLoaded
    // Failsafe: Force the layout to show after 600ms even if fast poller hangs
    Timer { interval: 600; running: true; onTriggered: barWindow.isDataReady = true }
    
    property string timeStr: ""
    property string fullDateStr: ""
    property int typeInIndex: 0
    property string dateStr: fullDateStr.substring(0, typeInIndex)

    property string weatherIcon: ""
    property string weatherTemp: "--°"
    property string weatherHex: mocha.yellow
    property bool showWeatherInTopBar: false
    
    property string wifiStatus: "Off"
    property string wifiIcon: "󰤮"
    property string wifiSsid: ""
    
    property string btStatus: "Off"
    property string btIcon: "󰂲"
    property string btDevice: ""
    
    property string volPercent: "0%"
    property string volIcon: "󰕾"
    property bool isMuted: false
    
    property string batPercent: "100%"
    property string batIcon: "󰁹"
    property string batStatus: "Unknown"
    
    property string kbLayout: "us"
    
    ListModel { id: workspacesModel }

    function ensureWorkspaceDefaults() {
        if (workspacesModel.count === 4) {
            return;
        }
        workspacesModel.clear();
        for (let i = 1; i <= 4; i++) {
            workspacesModel.append({ "wsId": i.toString(), "wsState": "empty" });
        }
    }

    Component.onCompleted: ensureWorkspaceDefaults()
    
    property var musicData: { "status": "Stopped", "title": "", "artUrl": "", "timeStr": "" }

    // Derived properties for UI logic
    property bool isMediaActive: barWindow.musicData.status !== "Stopped" && barWindow.musicData.title !== ""
    property bool isWifiOn: barWindow.wifiStatus.toLowerCase() === "enabled" || barWindow.wifiStatus.toLowerCase() === "on"
    property bool isBtOn: barWindow.btStatus.toLowerCase() === "enabled" || barWindow.btStatus.toLowerCase() === "on"
    
    property bool isSoundActive: !barWindow.isMuted && parseInt(barWindow.volPercent) > 0
    property int batCap: parseInt(barWindow.batPercent) || 0
    property bool isCharging: barWindow.batStatus === "Charging" || barWindow.batStatus === "Full"
    property color batDynamicColor: {
        if (isCharging) return mocha.green;
        if (batCap >= 70) return mocha.blue;
        if (batCap >= 30) return mocha.yellow;
        return mocha.red;
    }

    // ==========================================
    // DATA FETCHING 
    // ==========================================

    // Workspaces --------------------------------
    // 1. The continuous background daemon
    Process {
        id: wsDaemon
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/workspaces.sh > /tmp/qs_workspaces.json"]
        running: true
    }

    // 2. The lightweight reader
    Process {
        id: wsReader
        command: ["bash", "-c", "tail -n 1 /tmp/qs_workspaces.json 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try { 
                        let newData = JSON.parse(txt);
                        if (!Array.isArray(newData) || newData.length === 0) {
                            ensureWorkspaceDefaults();
                            return;
                        }
                        if (workspacesModel.count !== newData.length) {
                            workspacesModel.clear();
                            for (let i = 0; i < newData.length; i++) {
                                workspacesModel.append({ "wsId": newData[i].id.toString(), "wsState": newData[i].state });
                            }
                        } else {
                            for (let i = 0; i < newData.length; i++) {
                                if (workspacesModel.get(i).wsState !== newData[i].state) {
                                    workspacesModel.setProperty(i, "wsState", newData[i].state);
                                }
                                if (workspacesModel.get(i).wsId !== newData[i].id.toString()) {
                                    workspacesModel.setProperty(i, "wsId", newData[i].id.toString());
                                }
                            }
                        }
                    } catch(e) {}
                }
            }
        }
    }

    // 3. Ultra-fast 50ms loop.
    Timer { 
        interval: 50 
        running: true 
        repeat: true 
        onTriggered: wsReader.running = true 
    }

    // Music -------------------------------------
    // 1. Fast cache reader to smoothly update the timestamp 
    Process {
        id: musicPoller
        command: ["bash", "-c", "cat /tmp/music_info.json 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try { barWindow.musicData = JSON.parse(txt); } catch(e) {}
                }
            }
        }
    }

    // 2. Direct executor for zero-latency UI state changes (play/pause skips)
    Process {
        id: musicForceRefresh
        running: true
        command: ["bash", "-c", "bash ~/.config/hypr/scripts/quickshell/music/music_info.sh | tee /tmp/music_info.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try { barWindow.musicData = JSON.parse(txt); } catch(e) {}
                }
            }
        }
    }

    // 3. Lightweight timer to update the progress clock without freezing
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: musicPoller.running = true
    }

    // Unified System Info ------------------------
    Process {
        id: sysPoller
        running: true
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/sys_info.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        let data = JSON.parse(txt);
                        
                        // Targeted Updates
                        if (barWindow.wifiStatus !== data.wifi.status) barWindow.wifiStatus = data.wifi.status;
                        if (barWindow.wifiIcon !== data.wifi.icon) barWindow.wifiIcon = data.wifi.icon;
                        if (barWindow.wifiSsid !== data.wifi.ssid) barWindow.wifiSsid = data.wifi.ssid;

                        if (barWindow.btStatus !== data.bt.status) barWindow.btStatus = data.bt.status;
                        if (barWindow.btIcon !== data.bt.icon) barWindow.btIcon = data.bt.icon;
                        if (barWindow.btDevice !== data.bt.connected) barWindow.btDevice = data.bt.connected;

                        let newVol = data.audio.volume.toString() + "%";
                        if (barWindow.volPercent !== newVol) barWindow.volPercent = newVol;
                        if (barWindow.volIcon !== data.audio.icon) barWindow.volIcon = data.audio.icon;
                        
                        let newMuted = (data.audio.is_muted === "true");
                        if (barWindow.isMuted !== newMuted) barWindow.isMuted = newMuted;

                        let newBat = data.battery.percent.toString() + "%";
                        if (barWindow.batPercent !== newBat) barWindow.batPercent = newBat;
                        if (barWindow.batIcon !== data.battery.icon) barWindow.batIcon = data.battery.icon;
                        if (barWindow.batStatus !== data.battery.status) barWindow.batStatus = data.battery.status;

                        if (barWindow.kbLayout !== data.keyboard.layout) barWindow.kbLayout = data.keyboard.layout;

                        barWindow.sysPollerLoaded = true;
                        barWindow.fastPollerLoaded = true;
                    } catch(e) {}
                }
                sysWaiter.running = true;
                musicForceRefresh.running = true; // Instantly grab the fresh music data if triggered by DBus
            }
        }
    }
    Process {
        id: sysWaiter
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/sys_waiter.sh"]
        stdout: StdioCollector {
            onStreamFinished: sysPoller.running = true
        }
    }

    // Weather remains a slow poll since it fetches from web
    Process {
        id: weatherPoller
        command: ["bash", "-c", `
            echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-icon)"
            echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-temp)"
            echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-hex)"
        `]
        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 3) {
                    barWindow.weatherIcon = lines[0];
                    barWindow.weatherTemp = lines[1];
                    barWindow.weatherHex = lines[2] || mocha.yellow;
                }
            }
        }
    }

    Process {
        id: weatherRefreshPoller
        command: ["bash", "-c", `
            ~/.config/hypr/scripts/quickshell/calendar/weather.sh --refresh >/dev/null 2>&1
            echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-icon)"
            echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-temp)"
            echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-hex)"
        `]
        stdout: SplitParser {
            onRead: data => {
                let lines = data.trim().split("\n");
                if (lines.length >= 3) {
                    barWindow.weatherIcon = lines[0];
                    barWindow.weatherTemp = lines[1];
                    barWindow.weatherHex = lines[2] || mocha.yellow;
                }
            }
        }
    }

    Process {
        id: weatherConfigTopBarPoller
        command: ["bash", "-c", "~/.config/hypr/scripts/quickshell/calendar/weather.sh --get-config"]
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt === "") return;
                try {
                    let cfg = JSON.parse(txt);
                    let key = (cfg.key || "").trim();
                    barWindow.showWeatherInTopBar = key !== "" && key !== "Skipped" && key !== "OPENWEATHER_KEY";
                } catch (e) {}
            }
        }
    }

    Timer {
        interval: 150000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            weatherConfigTopBarPoller.running = true;
            if (barWindow.showWeatherInTopBar) {
                weatherPoller.running = true;
            }
        }
    }

    // Native Qt Time Formatting
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            let d = new Date();
            barWindow.timeStr = Qt.formatDateTime(d, "hh:mm:ss AP");
            barWindow.fullDateStr = Qt.formatDateTime(d, "dddd, MMMM dd");
            if (barWindow.typeInIndex >= barWindow.fullDateStr.length) {
                barWindow.typeInIndex = barWindow.fullDateStr.length;
            }
        }
    }

    // Typewriter effect timer for the date
    Timer {
        id: typewriterTimer
        interval: 40
        running: barWindow.isStartupReady && barWindow.typeInIndex < barWindow.fullDateStr.length
        repeat: true
        onTriggered: barWindow.typeInIndex += 1
    }

    // ==========================================
    // UI LAYOUT
    // ==========================================
    Item {
        anchors.centerIn: parent
        width: Math.max(1, Math.round(parent.width / barWindow.uiScale))
        height: Math.max(1, Math.round(parent.height / barWindow.uiScale))
        scale: barWindow.uiScale
        transformOrigin: Item.Center

        // ---------------- LEFT ----------------
        RowLayout {
            id: leftLayout
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4 

            // Staggered Main Transition
            property bool showLayout: false
            opacity: showLayout ? 1 : 0
            transform: Translate {
                x: leftLayout.showLayout ? 0 : -30
                Behavior on x { NumberAnimation { duration: 800; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
            }
            
            Timer {
                running: barWindow.isStartupReady
                interval: 10
                onTriggered: leftLayout.showLayout = true
            }

            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

            property int moduleHeight: 48

            // Search 
            Rectangle {
                property bool isHovered: searchMouse.containsMouse
                color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.95) : Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                radius: 14; border.width: 1; border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, isHovered ? 0.15 : 0.05)
                Layout.preferredHeight: parent.moduleHeight; Layout.preferredWidth: 48
                
                scale: isHovered ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                Behavior on color { ColorAnimation { duration: 200 } }
                
                Text {
                    anchors.centerIn: parent
                    text: "󰍉"
                    font.family: "Iosevka Nerd Font"; font.pixelSize: 24
                    color: parent.isHovered ? mocha.blue : mocha.text
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                MouseArea {
                    id: searchMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle launcher"])
                }
            }

            // Notifications
            Rectangle {
                property bool isHovered: notifMouse.containsMouse
                color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.95) : Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                radius: 14
                border.width: 1
                border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, isHovered ? 0.15 : 0.05)
                Layout.preferredHeight: parent.moduleHeight
                Layout.preferredWidth: 48

                scale: isHovered ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                Behavior on color { ColorAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    text: ""
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 18
                    color: parent.isHovered ? mocha.yellow : mocha.text
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                MouseArea {
                    id: notifMouse
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle notifications"])
                        if (mouse.button === Qt.RightButton) Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh open notifications dismiss"])
                    }
                }
            }

            // Workspaces 
            Rectangle {
                color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                radius: 14; border.width: 1; border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.05)
                Layout.preferredHeight: parent.moduleHeight
                clip: true
                
                property real targetWidth: workspacesModel.count > 0 ? wsLayout.implicitWidth + 20 : 0
                Layout.preferredWidth: targetWidth
                visible: targetWidth > 0
                opacity: workspacesModel.count > 0 ? 1 : 0
                
                Behavior on opacity { NumberAnimation { duration: 300 } }

                RowLayout {
                    id: wsLayout
                    anchors.centerIn: parent
                    spacing: 6
                    
                    Repeater {
                        model: workspacesModel
                        delegate: Rectangle {
                            id: wsPill
                            property bool isHovered: wsPillMouse.containsMouse
                            
                            // Mapped dynamically from the ListModel (Qt version-safe)
                            property string stateLabel: (typeof wsState !== "undefined") ? wsState : ((modelData && modelData.wsState) ? modelData.wsState : "empty")
                            property string wsName: (typeof wsId !== "undefined") ? wsId : ((modelData && modelData.wsId) ? modelData.wsId : (index + 1).toString())
                            
                            property real targetWidth: 32
                            Layout.preferredWidth: targetWidth
                            Behavior on targetWidth { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            
                            Layout.preferredHeight: 32; radius: 10
                            
                            color: stateLabel === "active" 
                                    ? mocha.mauve 
                                    : (isHovered 
                                        ? Qt.rgba(mocha.overlay0.r, mocha.overlay0.g, mocha.overlay0.b, 0.9) 
                                        : (stateLabel === "occupied" 
                                            ? Qt.rgba(mocha.surface2.r, mocha.surface2.g, mocha.surface2.b, 0.9) 
                                            : "transparent"))
                            border.width: stateLabel === "empty" ? 1 : 0
                            border.color: Qt.rgba(mocha.overlay2.r, mocha.overlay2.g, mocha.overlay2.b, 0.35)

                            scale: isHovered && stateLabel !== "active" ? 1.08 : 1.0
                            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            
                            property bool initAnimTrigger: false
                            opacity: initAnimTrigger ? 1 : 0
                            transform: Translate {
                                y: wsPill.initAnimTrigger ? 0 : 15
                                Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } }
                            }

                            Component.onCompleted: {
                                if (!barWindow.startupCascadeFinished) {
                                    animTimer.interval = index * 60;
                                    animTimer.start();
                                } else {
                                    initAnimTrigger = true;
                                }
                            }

                            Timer {
                                id: animTimer
                                running: false
                                repeat: false
                                onTriggered: wsPill.initAnimTrigger = true
                            }
                            
                            Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 250 } }

                            Text {
                                anchors.centerIn: parent
                                text: wsName
                                font.family: "Michroma"
                                font.pixelSize: 14
                                font.weight: stateLabel === "active" ? Font.Black : (stateLabel === "occupied" ? Font.Bold : Font.Medium)
                                
                                color: stateLabel === "active" 
                                        ? mocha.crust 
                                        : (isHovered 
                                            ? mocha.crust 
                                            : (stateLabel === "occupied" ? mocha.text : mocha.subtext1))
                                        
                                Behavior on color { ColorAnimation { duration: 250 } }
                            }
                            MouseArea {
                                id: wsPillMouse
                                hoverEnabled: true
                                anchors.fill: parent
                                onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh " + wsName])
                            }
                        }
                    }
                }
            }            

            // Media Player 
            Rectangle {
                id: mediaBox
                color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                radius: 14; border.width: 1; border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.05)
                Layout.preferredHeight: parent.moduleHeight
                clip: true 
                
                property real targetWidth: barWindow.isMediaActive ? mediaLayoutContainer.width + 24 : 0
                Layout.preferredWidth: targetWidth
                visible: targetWidth > 0 || opacity > 0
                opacity: barWindow.isMediaActive ? 1.0 : 0.0

                Behavior on targetWidth { NumberAnimation { duration: 700; easing.type: Easing.OutQuint } }
                Behavior on opacity { NumberAnimation { duration: 400 } }
                
                Item {
                    id: mediaLayoutContainer
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    height: parent.height
                    width: innerMediaLayout.implicitWidth
                    
                    opacity: barWindow.isMediaActive ? 1.0 : 0.0
                    transform: Translate { 
                        x: barWindow.isMediaActive ? 0 : -20 
                        Behavior on x { NumberAnimation { duration: 700; easing.type: Easing.OutQuint } }
                    }
                    Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

                    RowLayout {
                        id: innerMediaLayout
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 16
                        
                        MouseArea {
                            id: mediaInfoMouse
                            Layout.preferredWidth: infoLayout.implicitWidth
                            Layout.fillHeight: true
                            hoverEnabled: true
                            onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle music"])
                            
                            RowLayout {
                                id: infoLayout
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10
                                
                                scale: mediaInfoMouse.containsMouse ? 1.02 : 1.0
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }

                                Rectangle {
                                    Layout.preferredWidth: 32; Layout.preferredHeight: 32; radius: 8; color: mocha.surface1
                                    border.width: barWindow.musicData.status === "Playing" ? 1 : 0
                                    border.color: mocha.mauve
                                    clip: true
                                    Image { 
                                        anchors.fill: parent; 
                                        source: barWindow.musicData.artUrl || ""; 
                                        fillMode: Image.PreserveAspectCrop 
                                    }
                                    
                                    Rectangle {
                                        anchors.fill: parent
                                        color: Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.2)
                                    }
                                }
                                ColumnLayout {
                                    spacing: -2
                                    Layout.preferredWidth: 180 
                                    
                                    Text { 
                                        text: barWindow.musicData.title; 
                                        font.family: "Michroma"; 
                                        font.weight: Font.Black; 
                                        font.pixelSize: 13; 
                                        color: mocha.text;
                                        elide: Text.ElideRight; 
                                        Layout.fillWidth: true
                                    }
                                    Text { 
                                        text: barWindow.musicData.timeStr; 
                                        font.family: "Michroma"; 
                                        font.weight: Font.Black; 
                                        font.pixelSize: 10; 
                                        color: mocha.subtext0;
                                        elide: Text.ElideRight;
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }

                        RowLayout {
                            spacing: 8
                            Item { 
                                Layout.preferredWidth: 24; Layout.preferredHeight: 24; 
                                Text { 
                                    anchors.centerIn: parent; text: "󰒮"; font.family: "Iosevka Nerd Font"; font.pixelSize: 26; 
                                    color: prevMouse.containsMouse ? mocha.text : mocha.overlay2; 
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    scale: prevMouse.containsMouse ? 1.1 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                }
                                MouseArea { id: prevMouse; hoverEnabled: true; anchors.fill: parent; onClicked: { Quickshell.execDetached(["playerctl", "previous"]); musicForceRefresh.running = true; } } 
                            }
                            Item { 
                                Layout.preferredWidth: 28; Layout.preferredHeight: 28; 
                                Text { 
                                    anchors.centerIn: parent; text: barWindow.musicData.status === "Playing" ? "󰏤" : "󰐊"; font.family: "Iosevka Nerd Font"; font.pixelSize: 30; 
                                    color: playMouse.containsMouse ? mocha.green : mocha.text; 
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    scale: playMouse.containsMouse ? 1.15 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                }
                                MouseArea { id: playMouse; hoverEnabled: true; anchors.fill: parent; onClicked: { Quickshell.execDetached(["playerctl", "play-pause"]); musicForceRefresh.running = true; } } 
                            }
                            Item { 
                                Layout.preferredWidth: 24; Layout.preferredHeight: 24; 
                                Text { 
                                    anchors.centerIn: parent; text: "󰒭"; font.family: "Iosevka Nerd Font"; font.pixelSize: 26; 
                                    color: nextMouse.containsMouse ? mocha.text : mocha.overlay2; 
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    scale: nextMouse.containsMouse ? 1.1 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                }
                                MouseArea { id: nextMouse; hoverEnabled: true; anchors.fill: parent; onClicked: { Quickshell.execDetached(["playerctl", "next"]); musicForceRefresh.running = true; } } 
                            }
                        }
                    }
                }
            }
        }

        // ---------------- CENTER ----------------
        Rectangle {
            id: centerBox
            anchors.centerIn: parent
            property bool isHovered: centerMouse.containsMouse
            color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.95) : Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
            radius: 14; border.width: 1; border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, isHovered ? 0.15 : 0.05)
            height: 48
            
            width: centerLayout.implicitWidth + 36
            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
            
            // Staggered Center Transition
            property bool showLayout: false
            opacity: showLayout ? 1 : 0
            transform: Translate {
                y: centerBox.showLayout ? 0 : -30
                Behavior on y { NumberAnimation { duration: 800; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
            }

            Timer {
                running: barWindow.isStartupReady
                interval: 150
                onTriggered: centerBox.showLayout = true
            }

            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

            // Hover Scaling
            scale: isHovered ? 1.03 : 1.0
            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
            Behavior on color { ColorAnimation { duration: 250 } }
            
            MouseArea {
                id: centerMouse
                anchors.fill: parent
                hoverEnabled: true
                onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle calendar"])
            }

            RowLayout {
                id: centerLayout
                anchors.centerIn: parent
                spacing: 24

                // Clockbox
                ColumnLayout {
                    spacing: -2
                    Text { text: barWindow.timeStr; font.family: "Michroma"; font.pixelSize: 16; font.weight: Font.Black; color: mocha.blue }
                    Text { text: barWindow.dateStr; font.family: "Michroma"; font.pixelSize: 11; font.weight: Font.Bold; color: mocha.subtext0 }
                }

                // Weatherbox
                RowLayout {
                    visible: barWindow.showWeatherInTopBar
                    opacity: barWindow.showWeatherInTopBar ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    spacing: 8
                    Text { 
                        text: barWindow.weatherIcon; 
                        font.family: "Iosevka Nerd Font"; 
                        font.pixelSize: 24; 
                        color: Qt.tint(barWindow.weatherHex, Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.4)) 
                    }
                    Text { text: barWindow.weatherTemp; font.family: "Michroma"; font.pixelSize: 17; font.weight: Font.Black; color: mocha.peach }
                }
            }
        }

        // ---------------- RIGHT ----------------
        RowLayout {
            id: rightLayout
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            // Staggered Right Transition
            property bool showLayout: false
            opacity: showLayout ? 1 : 0
            transform: Translate {
                x: rightLayout.showLayout ? 0 : 30
                Behavior on x { NumberAnimation { duration: 800; easing.type: Easing.OutBack; easing.overshoot: 1.1 } }
            }
            
            Timer {
                running: barWindow.isStartupReady && barWindow.isDataReady
                interval: 250
                onTriggered: rightLayout.showLayout = true
            }

            Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

            // Dedicated System Tray Pill
            Rectangle {
                height: 48
                radius: 14
                border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.08)
                border.width: 1
                color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                
                property real targetWidth: trayRepeater.count > 0 ? trayLayout.implicitWidth + 24 : 0
                Layout.preferredWidth: targetWidth
                Behavior on targetWidth { NumberAnimation { duration: 400; easing.type: Easing.OutExpo } }
                
                visible: targetWidth > 0
                opacity: targetWidth > 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 300 } }

                RowLayout {
                    id: trayLayout
                    anchors.centerIn: parent
                    spacing: 10

                    Repeater {
                        id: trayRepeater
                        model: SystemTray.items
                        delegate: Image {
                            id: trayIcon
                            source: modelData.icon || ""
                            fillMode: Image.PreserveAspectFit
                            
                            sourceSize: Qt.size(18, 18)
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            Layout.alignment: Qt.AlignVCenter
                            
                            property bool isHovered: trayMouse.containsMouse
                            property bool initAnimTrigger: false
                            opacity: initAnimTrigger ? (isHovered ? 1.0 : 0.8) : 0.0
                            scale: initAnimTrigger ? (isHovered ? 1.15 : 1.0) : 0.0

                            Component.onCompleted: {
                                if (!barWindow.startupCascadeFinished) {
                                    trayAnimTimer.interval = index * 50;
                                    trayAnimTimer.start();
                                } else {
                                    initAnimTrigger = true;
                                }
                            }
                            Timer {
                                id: trayAnimTimer
                                running: false
                                repeat: false
                                onTriggered: trayIcon.initAnimTrigger = true
                            }

                            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                            Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                            QsMenuAnchor {
                                id: menuAnchor
                                anchor.window: barWindow
                                anchor.item: trayIcon
                                menu: modelData.menu
                            }

                            MouseArea {
                                id: trayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton) {
                                        modelData.activate();
                                    } else if (mouse.button === Qt.MiddleButton) {
                                        modelData.secondaryActivate();
                                    } else if (mouse.button === Qt.RightButton) {
                                        if (modelData.menu) {
                                            menuAnchor.open();
                                        } else if (typeof modelData.contextMenu === "function") {
                                            modelData.contextMenu(mouse.x, mouse.y);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // System Elements Pill
            Rectangle {
                height: 48
                radius: 14
                border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.08)
                border.width: 1
                color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                clip: true
                
                property real targetWidth: sysLayout.implicitWidth + 20
                Layout.preferredWidth: targetWidth

                RowLayout {
                    id: sysLayout
                    anchors.centerIn: parent
                    spacing: 8 

                    property int pillHeight: 34

                    // Help (keybinds)
                    Rectangle {
                        property bool isHovered: helpMouse.containsMouse
                        color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
                        radius: 10; Layout.preferredHeight: sysLayout.pillHeight;
                        clip: true
                        
                        property real targetWidth: helpLayoutRow.implicitWidth + 24
                        Layout.preferredWidth: targetWidth
                        Behavior on targetWidth { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                        
                        scale: isHovered ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        property bool initAnimTrigger: false
                        Timer { running: rightLayout.showLayout && !parent.initAnimTrigger; interval: 0; onTriggered: parent.initAnimTrigger = true }
                        opacity: initAnimTrigger ? 1 : 0
                        transform: Translate { y: parent.initAnimTrigger ? 0 : 15; Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                        RowLayout { id: helpLayoutRow; anchors.centerIn: parent; spacing: 6
                            Text { text: "?"; font.family: "Michroma"; font.pixelSize: 14; font.weight: Font.Black; color: parent.parent.isHovered ? mocha.blue : mocha.text }
                            Text { text: "Help"; font.family: "Michroma"; font.pixelSize: 11; font.weight: Font.Bold; color: parent.parent.isHovered ? mocha.blue : mocha.subtext0 }
                        }
                        MouseArea {
                            id: helpMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle guide"])
                        }
                    }

                    // WiFi 
                    Rectangle {
                        id: wifiPill
                        property bool isHovered: wifiMouse.containsMouse
                        radius: 10; Layout.preferredHeight: sysLayout.pillHeight; 
                        color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
                        clip: true
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            opacity: barWindow.isWifiOn ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: mocha.blue }
                                GradientStop { position: 1.0; color: Qt.lighter(mocha.blue, 1.3) }
                            }
                        }

                        property real targetWidth: wifiLayoutRow.implicitWidth + 24
                        Layout.preferredWidth: targetWidth
                        Behavior on targetWidth { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                        
                        scale: isHovered ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        property bool initAnimTrigger: false
                        Timer { running: rightLayout.showLayout && !parent.initAnimTrigger; interval: 50; onTriggered: parent.initAnimTrigger = true }
                        opacity: initAnimTrigger ? 1 : 0
                        transform: Translate { y: parent.initAnimTrigger ? 0 : 15; Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                        RowLayout { id: wifiLayoutRow; anchors.centerIn: parent; spacing: wifiText.visible ? 8 : 0
                            Text { text: barWindow.wifiIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: 16; color: barWindow.isWifiOn ? mocha.base : mocha.subtext0 }
                            Text { 
                                id: wifiText
                                text: barWindow.sysPollerLoaded ? (barWindow.isWifiOn ? (barWindow.wifiSsid !== "" ? barWindow.wifiSsid : "On") : "Off") : ""
                                visible: text !== ""
                                font.family: "Michroma"; font.pixelSize: 13; font.weight: Font.Black; 
                                color: barWindow.isWifiOn ? mocha.base : mocha.text; 
                                Layout.maximumWidth: 100; elide: Text.ElideRight 
                            }
                        }
                        MouseArea { id: wifiMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle network wifi"]) }
                    }

                    // Bluetooth 
                    Rectangle {
                        id: btPill
                        property bool isHovered: btMouse.containsMouse
                        radius: 10; Layout.preferredHeight: sysLayout.pillHeight
                        clip: true
                        color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            opacity: barWindow.isBtOn ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: mocha.mauve }
                                GradientStop { position: 1.0; color: Qt.lighter(mocha.mauve, 1.3) }
                            }
                        }

                        property real targetWidth: btLayoutRow.implicitWidth + 24
                        Layout.preferredWidth: targetWidth
                        Behavior on targetWidth { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }

                        scale: isHovered ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        property bool initAnimTrigger: false
                        Timer { running: rightLayout.showLayout && !parent.initAnimTrigger; interval: 100; onTriggered: parent.initAnimTrigger = true }
                        opacity: initAnimTrigger ? 1 : 0
                        transform: Translate { y: parent.initAnimTrigger ? 0 : 15; Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                        RowLayout { id: btLayoutRow; anchors.centerIn: parent; spacing: btText.visible ? 8 : 0
                            Text { text: barWindow.btIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: 16; color: barWindow.isBtOn ? mocha.base : mocha.subtext0 }
                            Text { 
                                id: btText
                                visible: text !== ""; 
                                text: barWindow.sysPollerLoaded ? barWindow.btDevice : ""
                                font.family: "Michroma"; font.pixelSize: 13; font.weight: Font.Black; 
                                color: barWindow.isBtOn ? mocha.base : mocha.text; 
                                Layout.maximumWidth: 100; elide: Text.ElideRight 
                            }
                        }
                        MouseArea { id: btMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle network bt"]) }
                    }

                    // Volume
                    Rectangle {
                        property bool isHovered: volMouse.containsMouse
                        color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
                        radius: 10; Layout.preferredHeight: sysLayout.pillHeight;
                        clip: true

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            opacity: barWindow.isSoundActive ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: mocha.peach }
                                GradientStop { position: 1.0; color: Qt.lighter(mocha.peach, 1.3) }
                            }
                        }
                        
                        property real targetWidth: volLayoutRow.implicitWidth + 24
                        Layout.preferredWidth: targetWidth
                        Behavior on targetWidth { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                        
                        scale: isHovered ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        property bool initAnimTrigger: false
                        Timer { running: rightLayout.showLayout && !parent.initAnimTrigger; interval: 150; onTriggered: parent.initAnimTrigger = true }
                        opacity: initAnimTrigger ? 1 : 0
                        transform: Translate { y: parent.initAnimTrigger ? 0 : 15; Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                        RowLayout { id: volLayoutRow; anchors.centerIn: parent; spacing: 8
                            Text { 
                                text: barWindow.volIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: 16; 
                                color: barWindow.isSoundActive ? mocha.base : mocha.subtext0 
                            }
                            Text { 
                                text: barWindow.volPercent; 
                                font.family: "Michroma"; font.pixelSize: 13; font.weight: Font.Black; 
                                color: barWindow.isSoundActive ? mocha.base : mocha.text; 
                            }
                        }
                        MouseArea {
                            id: volMouse
                            hoverEnabled: true
                            anchors.fill: parent
                            onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle volume"])
                            onWheel: function(wheel) {
                                if (wheel.angleDelta.y > 0) {
                                    Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"])
                                    Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%+"])
                                } else if (wheel.angleDelta.y < 0) {
                                    Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", "5%-"])
                                }
                                wheel.accepted = true
                            }
                        }
                    }

                    // Battery
                    Rectangle {
                        property bool isHovered: batMouse.containsMouse
                        color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4); 
                        radius: 10; Layout.preferredHeight: sysLayout.pillHeight;
                        clip: true

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            opacity: (barWindow.isCharging || barWindow.batCap <= 20) ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: barWindow.batDynamicColor; Behavior on color { ColorAnimation { duration: 300 } } }
                                GradientStop { position: 1.0; color: Qt.lighter(barWindow.batDynamicColor, 1.3); Behavior on color { ColorAnimation { duration: 300 } } }
                            }
                        }
                        
                        property real targetWidth: batLayoutRow.implicitWidth + 24
                        Layout.preferredWidth: targetWidth
                        Behavior on targetWidth { NumberAnimation { duration: 500; easing.type: Easing.OutQuint } }
                        
                        scale: isHovered ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutExpo } }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        property bool initAnimTrigger: false
                        Timer { running: rightLayout.showLayout && !parent.initAnimTrigger; interval: 200; onTriggered: parent.initAnimTrigger = true }
                        opacity: initAnimTrigger ? 1 : 0
                        transform: Translate { y: parent.initAnimTrigger ? 0 : 15; Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack } } }
                        Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }

                        RowLayout { id: batLayoutRow; anchors.centerIn: parent; spacing: 8
                            Text { 
                                text: barWindow.batIcon; font.family: "Iosevka Nerd Font"; font.pixelSize: 16; 
                                color: (barWindow.isCharging || barWindow.batCap <= 20) ? mocha.base : barWindow.batDynamicColor
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                            Text { 
                                text: barWindow.batPercent; font.family: "Michroma"; font.pixelSize: 13; font.weight: Font.Black; 
                                color: (barWindow.isCharging || barWindow.batCap <= 20) ? mocha.base : barWindow.batDynamicColor
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }
                        MouseArea { id: batMouse; hoverEnabled: true; anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle battery"]) }
                    }
                }
            }
        }
    }
}
