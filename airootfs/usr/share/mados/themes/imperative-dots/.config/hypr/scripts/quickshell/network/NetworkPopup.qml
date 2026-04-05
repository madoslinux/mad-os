import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtCore
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window
    
    // 1. Give the root window focus so it actively listens for keystrokes
    focus: true

    // 2. Add the Shortcut component to listen specifically for the Tab key
    Shortcut {
        sequence: "Tab"
        onActivated: {
            window.playSfx("switch.wav");
            window.activeMode = window.activeMode === "wifi" ? "bt" : "wifi";
        }
    }

    // -------------------------------------------------------------------------
    // INSTANT CACHING ENGINE & SHARED STATE
    // -------------------------------------------------------------------------
    Settings {
        id: cache
        property string lastWifiSsid: ""
        property string lastWifiJson: ""
        property string lastBtJson: ""
    }

    property bool ignoreNextModeFileUpdate: false
    Process {
        id: modeReader
        command: ["bash", "-c", "cat /tmp/qs_network_mode 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                let mode = this.text.trim();
                if ((mode === "wifi" || mode === "bt") && window.activeMode !== mode) {
                    window.ignoreNextModeFileUpdate = true;
                    window.activeMode = mode;
                }
            }
        }
    }

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: modeReader.running = true
    }

    Component.onCompleted: {
        Quickshell.execDetached(["bash", "-c", "if [ ! -f /tmp/qs_network_mode ]; then echo '" + activeMode + "' > /tmp/qs_network_mode; fi"]);

        // Process cached JSON FIRST so the arrays populate before animations trigger
        if (cache.lastWifiJson !== "") processWifiJson(cache.lastWifiJson);
        if (cache.lastBtJson !== "") processBtJson(cache.lastBtJson);
        introState = 1.0;
    }

    function playSfx(filename) {
        try {
            let rawUrl = Qt.resolvedUrl("sounds/" + filename).toString();
            let cleanPath = rawUrl;
            if (cleanPath.indexOf("file://") === 0) {
                cleanPath = cleanPath.substring(7); 
            }
            let cmd = "pw-play '" + cleanPath + "' 2>/dev/null || paplay '" + cleanPath + "' 2>/dev/null";
            Quickshell.execDetached(["sh", "-c", cmd]);
        } catch(e) {}
    }

    MatugenColors { id: _theme }

    readonly property color base: _theme.base
    readonly property color mantle: _theme.mantle
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color overlay0: _theme.overlay0
    readonly property color overlay1: _theme.overlay1
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    
    readonly property color mauve: _theme.mauve
    readonly property color pink: _theme.pink
    readonly property color sapphire: _theme.sapphire
    readonly property color blue: _theme.blue
    readonly property color red: _theme.red
    readonly property color maroon: _theme.maroon
    readonly property color peach: _theme.peach

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/network"
    
    // Abstracted accents. Dialed down from 1.4 to 1.15 to prevent the RGB channels 
    // from blowing out to pure #FFFFFF while still staying distinct and bright.
    readonly property color wifiAccent: Qt.lighter(window.sapphire, 1.15) 
    readonly property color btAccent: window.mauve

    property string activeMode: "bt"
    readonly property color activeColor: activeMode === "wifi" ? window.wifiAccent : window.btAccent
    // Calculate a subtle, pure one-color gradient rather than mixing two distinct palette colors
    readonly property color activeGradientSecondary: Qt.darker(window.activeColor, 1.25)

    // Dictionary objects to allow multi-device simultaneous connects/disconnects without globally locking
    property var busyTasks: ({})
    property var disconnectingDevices: ({})
    
    Timer { 
        id: busyTimeout; interval: 15000; 
        onTriggered: { window.busyTasks = ({}); window.disconnectingDevices = ({}); } 
    }

    Timer { id: wifiPendingReset; interval: 8000; onTriggered: { window.wifiPowerPending = false; window.expectedWifiPower = ""; } }
    Timer { id: btPendingReset; interval: 8000; onTriggered: { window.btPowerPending = false; window.expectedBtPower = ""; } }

    property bool showInfoView: false

    // Supports up to 5 simultaneous connected cores
    property var currentCores: [null, null, null, null, null]
    property var coreVisualIndices: [0, 0, 0, 0, 0]
    property int activeCoreCount: 0
    property real smoothedActiveCoreCount: activeCoreCount
    Behavior on smoothedActiveCoreCount { NumberAnimation { duration: 1000; easing.type: Easing.InOutExpo } }

    function syncCores() {
        let list = activeMode === "wifi" ? (isWifiConn && wifiConnected ? [window.wifiConnected] : []) : window.btConnected;
        if (!currentPower) list = [];
        else {
            if (!Array.isArray(list)) list = [list];
        }

        let newCores = [window.currentCores[0], window.currentCores[1], window.currentCores[2], window.currentCores[3], window.currentCores[4]];
        let found = [false, false, false, false, false];

        // 1. Maintain existing devices in their current visual slots
        for (let i = 0; i < list.length && i < 5; i++) {
            let dev = list[i];
            let id = window.activeMode === "wifi" ? dev.ssid : dev.mac;
            for (let c = 0; c < 5; c++) {
                if (newCores[c] && (window.activeMode === "wifi" ? newCores[c].ssid : newCores[c].mac) === id) { 
                    found[c] = true; newCores[c] = dev; break; 
                }
            }
        }

        // Wipe missing devices
        for (let c = 0; c < 5; c++) { if (!found[c]) newCores[c] = null; }

        // 2. Map newcomer devices to any empty slots
        for (let i = 0; i < list.length && i < 5; i++) {
            let dev = list[i];
            let id = window.activeMode === "wifi" ? dev.ssid : dev.mac;
            let isFound = false;
            for (let c = 0; c < 5; c++) {
                if (newCores[c] && (window.activeMode === "wifi" ? newCores[c].ssid : newCores[c].mac) === id) { isFound = true; break; }
            }
            if (!isFound) {
                for (let c = 0; c < 5; c++) {
                    if (!newCores[c]) { newCores[c] = dev; break; }
                }
            }
        }

        window.currentCores = newCores;

        // 3. Assign continuous visual indexes for elegant ring spacing
        let activeCount = 0;
        let newVis = [0, 0, 0, 0, 0];
        for (let c = 0; c < 5; c++) {
            if (newCores[c]) {
                newVis[c] = activeCount;
                activeCount++;
            }
        }
        window.coreVisualIndices = newVis;
        window.activeCoreCount = activeCount;
    }

    onCurrentConnChanged: {
        showInfoView = currentConn;
        if (currentConn) updateInfoNodes();
    }

    onActiveModeChanged: {
        if (!window.ignoreNextModeFileUpdate) {
            Quickshell.execDetached(["bash", "-c", "echo '" + window.activeMode + "' > /tmp/qs_network_mode"]);
        }
        window.ignoreNextModeFileUpdate = false;

        // Complete wipe of nodes to prevent any ghost artifacts between modes
        infoListModel.clear();
        window.busyTasks = ({});
        window.disconnectingDevices = ({});
        window.currentCores = [null, null, null, null, null];
        window.coreVisualIndices = [0, 0, 0, 0, 0];
        window.activeCoreCount = 0;
        syncCores();
        window.showInfoView = window.currentConn;
        if (window.showInfoView) window.updateInfoNodes();
    }

    ListModel { id: wifiListModel }
    ListModel { id: btListModel }
    ListModel { id: infoListModel }

    function syncModel(listModel, dataArray) {
        for (let i = listModel.count - 1; i >= 0; i--) {
            let id = listModel.get(i).id;
            let found = false;
            for (let j = 0; j < dataArray.length; j++) {
                if (id === dataArray[j].id) { found = true; break; }
            }
            if (!found) { listModel.remove(i); }
        }
        
        for (let i = 0; i < dataArray.length && i < 30; i++) {
            let d = dataArray[i];
            let foundIdx = -1;
            for (let j = i; j < listModel.count; j++) {
                if (listModel.get(j).id === d.id) { foundIdx = j; break; }
            }
            
            let obj = {
                id: d.id || "", ssid: d.ssid || "", mac: d.mac || "",
                name: d.name || d.ssid || "", icon: d.icon || "", security: d.security || "", action: d.action || "",
                isInfoNode: d.isInfoNode || false, isActionable: d.isActionable !== undefined ? d.isActionable : false, 
                cmdStr: d.cmdStr || "", parentIndex: d.parentIndex !== undefined ? d.parentIndex : -1
            };

            if (foundIdx === -1) {
                listModel.insert(i, obj);
            } else {
                if (foundIdx !== i) { listModel.move(foundIdx, i, 1); }
                for (let key in obj) { 
                    if (listModel.get(i)[key] !== obj[key]) {
                        listModel.setProperty(i, key, obj[key]); 
                    }
                }
            }
        }
    }

    property int hoveredCardCount: 0
    readonly property bool isListLocked: hoveredCardCount > 0
    property var nextWifiList: null
    property var nextBtList: null
    property var nextInfoList: null

    onIsListLockedChanged: {
        if (!isListLocked) {
            if (nextWifiList !== null) { window.syncModel(wifiListModel, nextWifiList); window.wifiList = nextWifiList; nextWifiList = null; }
            if (nextBtList !== null) { window.syncModel(btListModel, nextBtList); window.btList = nextBtList; nextBtList = null; }
            if (nextInfoList !== null) { window.syncModel(infoListModel, nextInfoList); nextInfoList = null; }
        }
    }

    property bool wifiPowerPending: false
    property string expectedWifiPower: ""
    property string wifiPower: "off"
    property var wifiConnected: null
    property var wifiList: []
    property string strongestWifiSsid: ""
    readonly property bool isWifiConn: !!window.wifiConnected && window.wifiConnected.ssid !== undefined

    readonly property string targetWifiSsid: {
        let found = false;
        if (cache.lastWifiSsid !== "") {
            for (let i = 0; i < wifiList.length; i++) {
                if (wifiList[i].id === cache.lastWifiSsid) { found = true; break; }
            }
        }
        return found ? cache.lastWifiSsid : strongestWifiSsid;
    }

    onWifiConnectedChanged: {
        if (window.wifiConnected && window.wifiConnected.ssid) { cache.lastWifiSsid = window.wifiConnected.ssid; }
        syncCores();
        if (window.currentConn && window.activeMode === "wifi") updateInfoNodes();
    }

    property bool btPowerPending: false
    property string expectedBtPower: ""
    property string btPower: "off"
    property var btConnected: []
    property var btList: []
    readonly property bool isBtConn: window.btConnected.length > 0
    
    onBtConnectedChanged: { 
        syncCores();
        if (window.currentConn && window.activeMode === "bt") updateInfoNodes() 
    }

    readonly property bool currentPower: activeMode === "wifi" ? window.wifiPower === "on" : window.btPower === "on"
    onCurrentPowerChanged: { syncCores(); }

    readonly property bool currentPowerPending: activeMode === "wifi" ? window.wifiPowerPending : window.btPowerPending
    readonly property bool currentConn: activeMode === "wifi" ? window.isWifiConn : window.isBtConn
    
    readonly property var currentObjList: activeMode === "wifi" ? (window.isWifiConn ? [window.wifiConnected] : []) : window.btConnected
    
    readonly property bool isLogicMultiState: window.activeMode === "bt" && window.activeCoreCount > 1
    
    // Smooth transition properties. Drops to 0.0 immediately if power is cut.
    property real multiTransitionState: (isLogicMultiState && window.currentPower) ? 1.0 : 0.0
    Behavior on multiTransitionState { NumberAnimation { duration: 1200; easing.type: Easing.InOutExpo } }

    function updateInfoNodes() {
        let nodes = [];
        
        let wConn = window.wifiConnected;
        if (Array.isArray(wConn)) wConn = wConn[0]; 
        let cList = window.activeMode === "wifi" ? (window.isWifiConn && wConn ? [wConn] : []) : window.btConnected;
        
        if (window.currentConn && cList.length > 0) {
            for (let i = 0; i < cList.length; i++) {
                let obj = cList[i];
                let cIndex = 0;
                
                if (window.activeMode === "bt") {
                    for (let c = 0; c < 5; c++) {
                        if (window.currentCores[c] && window.currentCores[c].mac === obj.mac) { cIndex = c; break; }
                    }
                }

                if (window.activeMode === "wifi") {
                    let sigValue = obj.signal !== undefined ? obj.signal + "%" : "Calculating...";
                    nodes.push({ id: "sig_" + i, name: sigValue, icon: obj.icon || "󰤨", action: "Signal Strength", isInfoNode: true, isActionable: false, parentIndex: cIndex });
                    nodes.push({ id: "sec_" + i, name: obj.security || "Open", icon: "󰦝", action: "Security", isInfoNode: true, isActionable: false, parentIndex: cIndex });
                    if (obj.ip) nodes.push({ id: "ip_" + i, name: obj.ip, icon: "󰩟", action: "IP Address", isInfoNode: true, isActionable: false, parentIndex: cIndex });
                    if (obj.freq) nodes.push({ id: "freq_" + i, name: obj.freq, icon: "󰖧", action: "Band", isInfoNode: true, isActionable: false, parentIndex: cIndex });
                } else {
                    nodes.push({ id: "bat_" + obj.mac, name: (obj.battery || "0") + "%", icon: "󰥉", action: "Battery", isInfoNode: true, isActionable: false, parentIndex: cIndex });
                    if (obj.profile) {
                        nodes.push({ id: "prof_" + obj.mac, name: obj.profile, icon: (obj.profile === "Hi-Fi (A2DP)" ? "󰓃" : "󰋎"), action: "Audio Profile", isInfoNode: true, isActionable: false, parentIndex: cIndex });
                    }
                    nodes.push({ id: "mac_" + obj.mac, name: obj.mac || "Unknown", icon: "󰒋", action: "MAC Address", isInfoNode: true, isActionable: false, parentIndex: cIndex });
                }
            }
            // Always bind to -1 to prevent index jump 'pops'. We'll control its layout via pure math.
            nodes.push({ id: "action_scan", name: "Scan Devices", icon: "󰍉", action: "Switch View", isInfoNode: true, isActionable: true, cmdStr: "TOGGLE_VIEW", parentIndex: -1 });
        }
        
        if (window.isListLocked) window.nextInfoList = nodes;
        else { window.syncModel(infoListModel, nodes); window.nextInfoList = null; }
    }

    function processWifiJson(textData) {
        if (textData === "") return;
        try {
            let data = JSON.parse(textData);
            let fetchedPower = data.power || "off";
            
            if (window.wifiPowerPending) {
                window.wifiPower = window.expectedWifiPower; 
                if (fetchedPower === window.expectedWifiPower) {
                    window.wifiPowerPending = false; 
                    wifiPendingReset.stop();
                }
            } else {
                window.wifiPower = fetchedPower;
                window.expectedWifiPower = "";
            }

            let wasWifiConn = window.isWifiConn;
            let newConnected = data.connected;
            if (JSON.stringify(window.wifiConnected) !== JSON.stringify(newConnected)) {
                window.wifiConnected = newConnected;
            }
            
            let newNetworks = data.networks ? data.networks : [];
            if (newNetworks.length > 0) {
                let maxSig = -1; let bestSsid = newNetworks[0].id;
                for (let i = 0; i < newNetworks.length; i++) {
                    let sig = parseInt(newNetworks[i].signal || 0);
                    if (sig > maxSig) { maxSig = sig; bestSsid = newNetworks[i].id; }
                }
                window.strongestWifiSsid = bestSsid;
            } else { window.strongestWifiSsid = ""; }

            newNetworks.sort((a, b) => a.id.localeCompare(b.id));

            if (window.isWifiConn && window.activeMode === "wifi") {
                newNetworks.push({ id: "action_settings", ssid: "Current Device", mac: "", name: "Current Device", icon: "󰒓", security: "", action: "View Info", isInfoNode: false, isActionable: true, cmdStr: "TOGGLE_VIEW", parentIndex: -1 });
            }

            if (JSON.stringify(window.wifiList) !== JSON.stringify(newNetworks)) {
                if (window.isListLocked) window.nextWifiList = newNetworks;
                else { window.syncModel(wifiListModel, newNetworks); window.wifiList = newNetworks; window.nextWifiList = null; }
            }

            if (window.activeMode === "wifi") {
                if (!wasWifiConn && window.isWifiConn) {
                    window.showInfoView = true;
                }
                
                let dd = window.disconnectingDevices;
                let ddChanged = false;
                for (let ssid in dd) {
                    if (!window.isWifiConn || (window.wifiConnected && window.wifiConnected.ssid !== ssid)) {
                        delete dd[ssid];
                        ddChanged = true;
                    }
                }
                if (ddChanged) {
                    window.disconnectingDevices = Object.assign({}, dd);
                    if (Object.keys(window.disconnectingDevices).length === 0 && Object.keys(window.busyTasks).length === 0) busyTimeout.stop();
                }
                
                let newlyConnected = false;
                let bt = window.busyTasks;
                if (window.isWifiConn && window.wifiConnected && bt[window.wifiConnected.ssid]) {
                    newlyConnected = true;
                    delete bt[window.wifiConnected.ssid];
                }
                if (newlyConnected) {
                    window.playSfx("connect.wav");
                    window.busyTasks = Object.assign({}, bt);
                    if (Object.keys(window.busyTasks).length === 0 && Object.keys(window.disconnectingDevices).length === 0) busyTimeout.stop();
                }

                if (window.currentConn) window.updateInfoNodes();
            }
        } catch(e) {}
    }

    function processBtJson(textData) {
        if (textData === "") return;
        try {
            let data = JSON.parse(textData);
            let fetchedPower = data.power || "off";
            
            if (window.btPowerPending) {
                window.btPower = window.expectedBtPower; 
                if (fetchedPower === window.expectedBtPower) {
                    window.btPowerPending = false; 
                    btPendingReset.stop();
                }
            } else {
                window.btPower = fetchedPower;
                window.expectedBtPower = "";
            }

            let oldBtLen = window.btConnected.length;
            let newBtConnected = data.connected || [];
            if (!Array.isArray(newBtConnected)) newBtConnected = [newBtConnected];

            if (JSON.stringify(window.btConnected) !== JSON.stringify(newBtConnected)) {
                window.btConnected = newBtConnected;
            }

            let newDevices = data.devices ? data.devices : [];
            newDevices.sort((a, b) => a.id.localeCompare(b.id));

            if (window.isBtConn && window.activeMode === "bt") {
                newDevices.push({ id: "action_settings", ssid: "", mac: "action_settings", name: "Current Device", icon: "󰒓", action: "View Info", isInfoNode: false, isActionable: true, cmdStr: "TOGGLE_VIEW", parentIndex: -1 });
            }

            if (JSON.stringify(window.btList) !== JSON.stringify(newDevices)) {
                if (window.isListLocked) window.nextBtList = newDevices;
                else { window.syncModel(btListModel, newDevices); window.btList = newDevices; window.nextBtList = null; }
            }

            if (window.activeMode === "bt") {
                if (window.btConnected.length > oldBtLen) {
                    window.showInfoView = true;
                }

                let dd = window.disconnectingDevices;
                let ddChanged = false;
                for (let mac in dd) {
                    let stillConnected = false;
                    for (let i = 0; i < window.btConnected.length; i++) {
                        if (window.btConnected[i].mac === mac) { stillConnected = true; break; }
                    }
                    if (!stillConnected) {
                        delete dd[mac];
                        ddChanged = true;
                    }
                }
                if (ddChanged) {
                    window.disconnectingDevices = Object.assign({}, dd);
                    if (Object.keys(window.disconnectingDevices).length === 0 && Object.keys(window.busyTasks).length === 0) busyTimeout.stop();
                }
                
                let newlyConnected = false;
                let bt = window.busyTasks;
                for (let i = 0; i < window.btConnected.length; i++) {
                    let mac = window.btConnected[i].mac;
                    if (bt[mac]) {
                        newlyConnected = true;
                        delete bt[mac];
                    }
                }
                if (newlyConnected) {
                    window.playSfx("connect.wav");
                    window.busyTasks = Object.assign({}, bt);
                    if (Object.keys(window.busyTasks).length === 0 && Object.keys(window.disconnectingDevices).length === 0) busyTimeout.stop();
                }

                if (window.currentConn) window.updateInfoNodes();
            }
        } catch(e) {}
    }

    Process {
        id: wifiPoller
        command: ["bash", window.scriptsDir + "/wifi_panel_logic.sh"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                cache.lastWifiJson = this.text.trim();
                processWifiJson(cache.lastWifiJson);
            }
        }
    }

    Process {
        id: btPoller
        command: ["bash", window.scriptsDir + "/bluetooth_panel_logic.sh", "--status"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                cache.lastBtJson = this.text.trim();
                processBtJson(cache.lastBtJson);
            }
        }
    }
    
    Timer {
        interval: (Object.keys(window.busyTasks).length > 0 || Object.keys(window.disconnectingDevices).length > 0) ? 1000 : 3000
        running: true; repeat: true
        onTriggered: { 
            if (!wifiPoller.running) wifiPoller.running = true; 
            if (!btPoller.running) btPoller.running = true; 
        }
    }

    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 200000; loops: Animation.Infinite; running: true
    }

    property real introState: 0.0
    Behavior on introState { NumberAnimation { duration: 1500; easing.type: Easing.OutCubic } }

    component LoadingDots : Row {
        spacing: 5
        property color dotCol: window.text
        Repeater {
            model: 3
            Rectangle {
                width: 6; height: 6; radius: 3; color: dotCol
                SequentialAnimation on y {
                    loops: Animation.Infinite
                    PauseAnimation { duration: index * 100 }
                    NumberAnimation { from: 0; to: -6; duration: 250; easing.type: Easing.OutSine }
                    NumberAnimation { from: -6; to: 0; duration: 250; easing.type: Easing.InSine }
                    PauseAnimation { duration: (2 - index) * 100 }
                }
            }
        }
    }

    Item {
        anchors.fill: parent

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: window.base
            border.color: window.surface0
            border.width: 1
            clip: true
            Rectangle {
                width: parent.width * 0.8; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * 150
                y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * 100
                opacity: window.currentPower ? 0.08 : 0.02
                color: window.currentConn ? window.activeColor : window.surface2
                Behavior on color { ColorAnimation { duration: 1000 } }
                Behavior on opacity { NumberAnimation { duration: 1000 } }
            }
            
            Rectangle {
                width: parent.width * 0.9; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * -150
                y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * -100
                opacity: window.currentPower ? 0.06 : 0.01
                color: window.currentConn ? window.activeGradientSecondary : window.surface1
                Behavior on color { ColorAnimation { duration: 1000 } }
                Behavior on opacity { NumberAnimation { duration: 1000 } }
            }

            Item {
                id: radarItem
                anchors.fill: parent
                anchors.bottomMargin: 80 
                opacity: window.currentPower ? 1.0 : 0.0
                scale: window.currentPower ? 1.0 : 1.05
                Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutQuad } }
                Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                
                Repeater {
                    model: 3
                    Rectangle {
                        anchors.centerIn: parent
                        width: 280 + (index * 170)
                        height: width
                        radius: width / 2
                        color: "transparent"
                        
                        border.color: Object.keys(window.disconnectingDevices).length > 0 ? window.red : window.activeColor
                        border.width: Object.keys(window.disconnectingDevices).length > 0 ? 2 : 1
                        
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Behavior on border.width { NumberAnimation { duration: 150 } }

                        opacity: Object.keys(window.disconnectingDevices).length > 0 ? 0.2 : (window.currentConn ? 0.08 - (index * 0.02) : 0.03)
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                }
            }

            Canvas {
                id: nodeLinesCanvas
                anchors.fill: parent
                anchors.bottomMargin: 80
                z: 0 
                opacity: (window.currentConn && window.showInfoView && window.currentPower) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 500 } }
                
                Timer {
                    id: lightningTimer
                    interval: 45
                    running: nodeLinesCanvas.opacity > 0.01 && window.currentPower 
                    repeat: true
                    onTriggered: nodeLinesCanvas.requestPaint()
                }

                Connections {
                    target: window
                    function onGlobalOrbitAngleChanged() { 
                        if (window.currentConn && window.showInfoView && window.currentPower) nodeLinesCanvas.requestPaint() 
                    }
                }
                
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    if (!window.currentConn || !window.showInfoView || !window.currentPower) return;
                    
                    var time = Date.now() / 1000;
                    ctx.lineJoin = "round";
                    ctx.lineCap = "round";

                    var tWave1 = time * 2.5;
                    var tWave2 = time * -1.5;

                    for (var i = 0; i < orbitRepeater.count; i++) {
                        var item = orbitRepeater.itemAt(i);
                        if (!item || !item.isLoaded) continue;

                        var targetX = item.x + item.width / 2;
                        var targetY = item.y + item.height / 2;

                        function drawStrands(startX, startY, parentFade, parentWidth) {
                            var dx = targetX - startX;
                            var dy = targetY - startY;
                            var fullDist = Math.sqrt(dx * dx + dy * dy);
                            
                            if (fullDist < 10) return;

                            var alpha = Math.atan2(dy, dx);
                            var cosA = Math.cos(alpha);
                            var sinA = Math.sin(alpha);
                            
                            var coreVisualRadius = parentWidth / 2;
                            var startOffset = coreVisualRadius + 5; 
                            var endOffset = 35; 
                            
                            var drawDist = fullDist - startOffset - endOffset;
                            if (drawDist <= 0) return;
                            
                            var steps = 8;
                            var perpX = -sinA;
                            var perpY = cosA;

                            var sX = startX + cosA * startOffset;
                            var sY = startY + sinA * startOffset;

                            var distanceFactor = Math.max(0, 1.0 - (fullDist / 400.0));
                            var dynamicLineWidthCore = 1.0 + (distanceFactor * 2.0);
                            var dynamicLineWidthGlow = 4.0 + (distanceFactor * 4.0);
                            var dynamicAlpha = (0.2 + (distanceFactor * 0.7)) * parentFade;

                            ctx.beginPath();
                            ctx.moveTo(sX, sY);
                            for (var j = 1; j <= steps; j++) {
                                var t = j / steps;
                                var currentDist = drawDist * t;
                                var envelope = Math.sin(t * Math.PI);
                                var offset = Math.sin(tWave1 + t * 6) * 6 * envelope + ((Math.random() - 0.5) * 5.0 * distanceFactor);
                                ctx.lineTo(sX + cosA * currentDist + perpX * offset, sY + sinA * currentDist + perpY * offset);
                            }
                            ctx.lineWidth = dynamicLineWidthGlow;
                            ctx.strokeStyle = window.activeColor;
                            ctx.globalAlpha = dynamicAlpha * 0.15;
                            ctx.stroke();

                            ctx.lineWidth = dynamicLineWidthCore;
                            ctx.strokeStyle = "#ffffff";
                            ctx.globalAlpha = dynamicAlpha;
                            ctx.stroke();

                            ctx.beginPath();
                            ctx.moveTo(sX, sY);
                            for (var k = 1; k <= steps; k++) {
                                var tk = k / steps;
                                var currentDistK = drawDist * tk;
                                var envelopeK = Math.sin(tk * Math.PI);
                                var offsetK = Math.cos(tWave2 + tk * 8) * 12 * envelopeK + ((Math.random() - 0.5) * 3.0 * distanceFactor);
                                ctx.lineTo(sX + cosA * currentDistK + perpX * offsetK, sY + sinA * currentDistK + perpY * offsetK);
                            }
                            ctx.lineWidth = dynamicLineWidthCore * 1.5;
                            ctx.strokeStyle = window.activeColor;
                            ctx.globalAlpha = dynamicAlpha * 0.3;
                            ctx.stroke();
                        }

                        if (item.myParentIdx === -1) {
                            for (var c = 0; c < coreRepeater.count; c++) {
                                var cItem = coreRepeater.itemAt(c);
                                if (cItem && cItem.activeTransition > 0.01) {
                                    drawStrands(cItem.x + cItem.width/2, cItem.y + cItem.height/2, cItem.activeTransition, cItem.width);
                                }
                            }
                        } else {
                            var pItem = coreRepeater.itemAt(item.myParentIdx);
                            if (pItem && pItem.activeTransition > 0.01) {
                                drawStrands(pItem.x + pItem.width/2, pItem.y + pItem.height/2, pItem.activeTransition, pItem.width);
                            }
                        }
                    }
                }
            }

            Item {
                id: orbitContainer
                anchors.fill: parent
                anchors.bottomMargin: 80 
                z: 1

                // =========================================================
                // 1. DYNAMIC CENTRAL CORES (N-Device Supported)
                // =========================================================
                Repeater {
                    id: coreRepeater
                    model: 5

                    delegate: Item {
                        id: coreContainer
                        
                        property var myDevice: window.currentCores[index]
                        
                        property bool isPrimary: index === 0
                        property bool hasDevice: myDevice !== null
                        property bool isReallyActive: hasDevice || (isPrimary && window.activeCoreCount === 0)

                        property real activeTransition: isReallyActive ? 1.0 : 0.0
                        
                        Behavior on activeTransition { 
                            enabled: window.introState >= 1.0; 
                            NumberAnimation { duration: 1400; easing.type: Easing.OutExpo } 
                        }

                        property real multiShift: window.activeMode === "wifi" ? 0.0 : window.multiTransitionState

                        // Automatically scales down core sizes as more devices fill the ring
                        width: window.currentPower ? (200 - (30 * multiShift) - (15 * Math.max(0, window.smoothedActiveCoreCount - 2))) : 160
                        height: width
                        
                        property real myBaseAngle: (window.coreVisualIndices[index] / Math.max(1, window.activeCoreCount)) * Math.PI * 2
                        property real animatedBaseAngle: myBaseAngle
                        Behavior on animatedBaseAngle { NumberAnimation { duration: 1000; easing.type: Easing.InOutExpo } }
                        
                        property real coreOrbitAngle: window.globalOrbitAngle * 1.5 + animatedBaseAngle
                        
                        property real myOrbitRadiusX: 180 + (window.activeCoreCount > 2 ? 20 : 0)
                        property real myOrbitRadiusY: 110 + (window.activeCoreCount > 2 ? 15 : 0)

                        x: (orbitContainer.width / 2 - width / 2) + (Math.cos(coreOrbitAngle) * myOrbitRadiusX * multiShift * activeTransition)
                        y: (orbitContainer.height / 2 - height / 2) + (Math.sin(coreOrbitAngle) * myOrbitRadiusY * multiShift * activeTransition)
                        
                        opacity: activeTransition
                        scale: bumpScale * (0.8 + 0.2 * activeTransition)
                        visible: opacity > 0.01

                        property string myId: myDevice ? (window.activeMode === "wifi" ? myDevice.ssid : myDevice.mac) : "unknown"
                        property bool isMyDisconnecting: !!window.disconnectingDevices[myId]

                        MultiEffect {
                            source: centralCore
                            anchors.fill: centralCore
                            shadowEnabled: true
                            shadowColor: "#000000"
                            shadowOpacity: window.currentPower ? 0.5 : 0.0
                            shadowBlur: 1.2
                            shadowVerticalOffset: 6
                            z: -1
                            Behavior on shadowOpacity { NumberAnimation { duration: 600 } }
                        }

                        Rectangle {
                            id: centralCore
                            anchors.fill: parent
                            radius: width / 2
                            
                            property real disconnectFill: 0.0
                            property bool disconnectTriggered: false
                            property real flashOpacity: 0.0
                            property real bumpScale: 1.0
                            property bool isDangerState: coreMa.containsMouse || disconnectFill > 0 || isMyDisconnecting
                            
                            scale: bumpScale

                            SequentialAnimation on bumpScale {
                                id: coreBumpAnim
                                running: false
                                NumberAnimation { to: 1.15; duration: 200; easing.type: Easing.OutBack }
                                NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.OutQuint }
                            }

                            // A pure, mathematically subtle gradient rather than a dual-color mash
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop {
                                    position: 0.0
                                    color: {
                                        if (!window.currentPower) return window.mantle;
                                        if (isMyDisconnecting) return window.surface0; 
                                        if (centralCore.isDangerState && window.currentConn) return Qt.lighter(window.red, 1.15);
                                        return window.currentConn ? Qt.lighter(window.activeColor, 1.15) : window.surface0;
                                    }
                                    Behavior on color { ColorAnimation { duration: 300 } }
                                }
                                GradientStop {
                                    position: 1.0
                                    color: {
                                        if (!window.currentPower) return window.crust;
                                        if (isMyDisconnecting) return window.base; 
                                        if (centralCore.isDangerState && window.currentConn) return window.red;
                                        return window.currentConn ? window.activeColor : window.base;
                                    }
                                    Behavior on color { ColorAnimation { duration: 300 } }
                                }
                            }

                            border.color: {
                                if (!window.currentPower) return window.crust;
                                if (isMyDisconnecting) return window.surface0;
                                if (centralCore.isDangerState && window.currentConn) return window.maroon;
                                return window.currentConn ? Qt.lighter(window.activeColor, 1.1) : window.surface1;
                            }
                            Behavior on border.color { ColorAnimation { duration: 300 } }
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: "#ffffff"
                                opacity: centralCore.flashOpacity
                                PropertyAnimation on opacity { id: coreFlashAnim; to: 0; duration: 500; easing.type: Easing.OutExpo }
                            }

                            Canvas {
                                id: coreWave
                                anchors.fill: parent
                                visible: centralCore.disconnectFill > 0
                                opacity: 0.95

                                property real wavePhase: 0.0
                                NumberAnimation on wavePhase {
                                    running: centralCore.disconnectFill > 0.0 && centralCore.disconnectFill < 1.0
                                    loops: Animation.Infinite
                                    from: 0; to: Math.PI * 2; duration: 800
                                }
                                onWavePhaseChanged: requestPaint()
                                Connections { target: centralCore; function onDisconnectFillChanged() { coreWave.requestPaint() } }

                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.clearRect(0, 0, width, height);
                                    if (centralCore.disconnectFill <= 0.001) return;

                                    var r = width / 2;
                                    var fillY = height * (1.0 - centralCore.disconnectFill);

                                    ctx.save();
                                    ctx.beginPath();
                                    ctx.arc(r, r, r, 0, 2 * Math.PI);
                                    ctx.clip(); 

                                    ctx.beginPath();
                                    ctx.moveTo(0, fillY);
                                    if (centralCore.disconnectFill < 0.99) {
                                        var waveAmp = 10 * Math.sin(centralCore.disconnectFill * Math.PI);
                                        var cp1y = fillY + Math.sin(wavePhase) * waveAmp;
                                        var cp2y = fillY + Math.cos(wavePhase + Math.PI) * waveAmp;
                                        ctx.bezierCurveTo(width * 0.33, cp2y, width * 0.66, cp1y, width, fillY);
                                        ctx.lineTo(width, height);
                                        ctx.lineTo(0, height);
                                    } else {
                                        ctx.lineTo(width, 0);
                                        ctx.lineTo(width, height);
                                        ctx.lineTo(0, height);
                                    }
                                    ctx.closePath();
                                    
                                    // Matugen wash-out drain effect against the red danger orb
                                    var grad = ctx.createLinearGradient(0, 0, 0, height);
                                    grad.addColorStop(0, window.surface1.toString()); 
                                    grad.addColorStop(1, window.crust.toString());
                                    ctx.fillStyle = grad;
                                    ctx.fill();
                                    ctx.restore();
                                }
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + 40
                                height: width
                                radius: width / 2
                                color: centralCore.isDangerState && window.currentConn ? window.red : window.activeColor
                                opacity: window.currentConn && !isMyDisconnecting ? (centralCore.isDangerState ? 0.3 : 0.15) : 0.0
                                z: -1
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on opacity { NumberAnimation { duration: 300 } }
                                
                                SequentialAnimation on scale {
                                    loops: Animation.Infinite; running: window.currentConn
                                    NumberAnimation { to: coreMa.containsMouse ? 1.15 : 1.1; duration: coreMa.containsMouse ? 800 : 2000; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 1.0; duration: coreMa.containsMouse ? 800 : 2000; easing.type: Easing.InOutSine }
                                }
                            }
                            
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width + 15
                                height: width
                                radius: width / 2
                                color: "transparent"
                                border.color: centralCore.isDangerState ? window.red : window.activeColor
                                border.width: 3
                                z: -2
                                
                                property real pulseOp: 0.0
                                property real pulseSc: 1.0
                                opacity: (window.currentConn && window.showInfoView && window.currentPower && !isMyDisconnecting) ? pulseOp : 0.0
                                scale: pulseSc
                                
                                Timer {
                                    interval: 45
                                    running: parent.opacity > 0.01
                                    repeat: true
                                    onTriggered: {
                                        var time = Date.now() / 1000;
                                        parent.pulseOp = 0.3 + Math.sin(time * 2.5) * 0.15;
                                        parent.pulseSc = 1.02 + Math.cos(time * 3.0) * 0.02;
                                    }
                                }
                            }

                            // OFFLINE TEXT
                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 10
                                visible: !window.currentConn || !window.currentPower
                                opacity: visible ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 300 } }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    font.family: "Iosevka Nerd Font"
                                    font.pixelSize: 48 - (16 * coreContainer.multiShift)
                                    color: window.currentPower ? window.overlay0 : window.surface2
                                    text: window.activeMode === "wifi" ? "󰤮" : "󰂲"
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    font.family: "Michroma"; font.weight: Font.Bold
                                    font.pixelSize: 14 - (3 * coreContainer.multiShift)
                                    color: window.overlay0
                                    text: window.currentPowerPending 
                                        ? ((window.activeMode === "wifi" ? window.expectedWifiPower : window.expectedBtPower) === "on" ? "Powering On..." : "Powering Off...") 
                                        : (!window.currentPower ? "Radio Offline" : "Scanning...")
                                }
                            }

                            // ONLINE TEXT (Base + Clipped Mask)
                            Item {
                                anchors.fill: parent
                                visible: window.currentConn && window.currentPower
                                opacity: visible ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 300 } }

                                // 1. Base Uncovered Text
                                ColumnLayout {
                                    id: baseCoreText
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 48 - (16 * coreContainer.multiShift)
                                        color: isMyDisconnecting ? window.overlay1 : window.crust
                                        text: isMyDisconnecting ? "" : (coreMa.containsMouse ? (window.activeMode === "wifi" ? "󰖪" : "󰂲") : (coreContainer.myDevice ? coreContainer.myDevice.icon : ""))
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                    LoadingDots { Layout.alignment: Qt.AlignHCenter; visible: isMyDisconnecting; dotCol: window.overlay1 }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.maximumWidth: 150 - (50 * coreContainer.multiShift)
                                        horizontalAlignment: Text.AlignHCenter
                                        font.family: "Michroma"; font.weight: Font.Black
                                        font.pixelSize: 16 - (4 * coreContainer.multiShift)
                                        color: isMyDisconnecting ? window.overlay1 : window.crust
                                        text: coreContainer.myDevice ? (window.activeMode === "wifi" ? coreContainer.myDevice.ssid : coreContainer.myDevice.name) : ""
                                        elide: Text.ElideRight
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        font.family: "Michroma"; font.weight: Font.Bold; font.pixelSize: 11
                                        color: isMyDisconnecting ? window.overlay1 : (coreMa.containsMouse ? window.crust : "#99000000")
                                        text: isMyDisconnecting ? "Disconnecting..." : (centralCore.disconnectFill > 0.01 ? "Hold..." : "Connected")
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                }

                                // 2. Covered Clipped Text (Dynamically masks the text over the filling wave)
                                Item {
                                    id: waveClipItem
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: Math.min(parent.height, Math.max(0, parent.height * centralCore.disconnectFill + 8))
                                    clip: true
                                    visible: centralCore.disconnectFill > 0

                                    ColumnLayout {
                                        spacing: 4
                                        x: waveClipItem.width / 2 - width / 2
                                        y: (centralCore.height / 2) - (height / 2) - (centralCore.height - waveClipItem.height)

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            font.family: "Iosevka Nerd Font"
                                            font.pixelSize: 48 - (16 * coreContainer.multiShift)
                                            color: window.text
                                            text: isMyDisconnecting ? "" : (coreMa.containsMouse ? (window.activeMode === "wifi" ? "󰖪" : "󰂲") : (coreContainer.myDevice ? coreContainer.myDevice.icon : ""))
                                        }
                                        LoadingDots { Layout.alignment: Qt.AlignHCenter; visible: isMyDisconnecting; dotCol: window.text }
                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            Layout.maximumWidth: 150 - (50 * coreContainer.multiShift)
                                            horizontalAlignment: Text.AlignHCenter
                                            font.family: "Michroma"; font.weight: Font.Black
                                            font.pixelSize: 16 - (4 * coreContainer.multiShift)
                                            color: window.text
                                            text: coreContainer.myDevice ? (window.activeMode === "wifi" ? coreContainer.myDevice.ssid : coreContainer.myDevice.name) : ""
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            font.family: "Michroma"; font.weight: Font.Bold; font.pixelSize: 11
                                            color: window.text
                                            text: isMyDisconnecting ? "Disconnecting..." : (centralCore.disconnectFill > 0.01 ? "Hold..." : "Connected")
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: coreMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: window.currentConn && !isMyDisconnecting ? Qt.PointingHandCursor : Qt.ArrowCursor
                                
                                onPressed: {
                                    if (window.currentConn && !isMyDisconnecting && !centralCore.disconnectTriggered) {
                                        coreDrainAnim.stop();
                                        coreFillAnim.start();
                                    }
                                }
                                onReleased: {
                                    if (!centralCore.disconnectTriggered && !isMyDisconnecting) {
                                        coreFillAnim.stop();
                                        coreDrainAnim.start();
                                    }
                                }
                            }

                            NumberAnimation {
                                id: coreFillAnim
                                target: centralCore
                                property: "disconnectFill"
                                to: 1.0
                                duration: 700 * (1.0 - centralCore.disconnectFill) 
                                easing.type: Easing.InSine
                                onFinished: {
                                    centralCore.disconnectTriggered = true;
                                    centralCore.flashOpacity = 0.6;
                                    coreFlashAnim.start();
                                    coreBumpAnim.start();
                                    
                                    window.playSfx("disconnect.wav");
                                    
                                    let dd = window.disconnectingDevices;
                                    dd[coreContainer.myId] = true;
                                    window.disconnectingDevices = Object.assign({}, dd);
                                    busyTimeout.restart();
                                    
                                    let cmd = window.activeMode === "wifi" 
                                        ? "nmcli device disconnect $(nmcli -t -f DEVICE,TYPE d | grep wifi | cut -d: -f1 | head -n1)"
                                        : "bash " + window.scriptsDir + "/bluetooth_panel_logic.sh --disconnect '" + coreContainer.myDevice.mac + "'"
                                    Quickshell.execDetached(["sh", "-c", cmd])
                                    
                                    centralCore.disconnectFill = 0.0;
                                    centralCore.disconnectTriggered = false;
                                    
                                    if (window.activeMode === "wifi") wifiPoller.running = true; else btPoller.running = true;
                                }
                            }
                            
                            NumberAnimation {
                                id: coreDrainAnim
                                target: centralCore
                                property: "disconnectFill"
                                to: 0.0
                                duration: 1000 * centralCore.disconnectFill 
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }

                // =========================================================
                // 2. THE SWARM (Pure Mathematical Interpolation)
                // =========================================================
                Item {
                    anchors.fill: parent
                    opacity: window.currentPower ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.InOutQuad } }

                    Repeater {
                        id: orbitRepeater
                        model: (window.currentConn && window.showInfoView) ? infoListModel : (window.activeMode === "wifi" ? wifiListModel : btListModel)
                        
                        delegate: Item {
                            id: floatCardDelegateContainer
                            width: 170; height: 60

                            property bool isLoaded: false
                            opacity: isLoaded ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

                            property real entryAnim: isLoaded ? 1.0 : 0.0
                            Behavior on entryAnim { NumberAnimation { duration: 600; easing.type: Easing.OutBack } }

                            Timer {
                                running: true
                                interval: 40 + (index * 30) 
                                onTriggered: floatCardDelegateContainer.isLoaded = true
                            }

                            property int myParentIdx: model.parentIndex !== undefined ? model.parentIndex : -1
                            
                            property int siblingsCount: {
                                let c = 0;
                                let m = orbitRepeater.model;
                                if (m && m.count !== undefined) {
                                    for (let i = 0; i < m.count; i++) {
                                        let d = m.get(i);
                                        if (d && (d.parentIndex !== undefined ? d.parentIndex : -1) === myParentIdx) c++;
                                    }
                                }
                                return Math.max(1, c);
                            }
                            property int localIndex: {
                                let idx = 0;
                                let m = orbitRepeater.model;
                                if (m && m.count !== undefined) {
                                    for (let i = 0; i < index; i++) {
                                        let d = m.get(i);
                                        if (d && (d.parentIndex !== undefined ? d.parentIndex : -1) === myParentIdx) idx++;
                                    }
                                }
                                return idx;
                            }

                            property real unifiedRatio: window.activeMode === "wifi" ? 0.0 : window.multiTransitionState

                            property real activeCount: (unifiedRatio > 0.5 && myParentIdx !== -1) ? siblingsCount : orbitRepeater.count
                            property real dynamicScale: activeCount > 10 ? Math.max(0.6, 12.0 / activeCount) : (unifiedRatio > 0.5 ? (window.activeCoreCount > 2 ? 0.7 : 0.8) : 1.0)
                            
                            property real safeMultiShift: window.activeMode === "wifi" ? 0.0 : window.multiTransitionState
                            property var pItem: myParentIdx !== -1 ? coreRepeater.itemAt(myParentIdx) : null
                            
                            property real parentX: pItem ? (orbitContainer.width / 2) + (Math.cos(parentCoreAngle) * pItem.myOrbitRadiusX * safeMultiShift * pItem.activeTransition) : (orbitContainer.width / 2)
                            property real parentY: pItem ? (orbitContainer.height / 2) + (Math.sin(parentCoreAngle) * pItem.myOrbitRadiusY * safeMultiShift * pItem.activeTransition) : (orbitContainer.height / 2)

                            property real parentBaseAngle: pItem ? pItem.animatedBaseAngle : 0
                            
                            // To prevent list updating "jumps", we smoothly interpolate the layout properties while leaving the global rotation constant
                            property real targetSingleBaseAngle: (index / Math.max(1, orbitRepeater.count)) * Math.PI * 2
                            property real singleBaseAngle: targetSingleBaseAngle
                            Behavior on singleBaseAngle { NumberAnimation { duration: 800; easing.type: Easing.OutExpo } }

                            property real singleLiveAngle: (window.globalOrbitAngle * 1.5) + singleBaseAngle
                            
                            property real arcSpread: Math.PI * 0.8 
                            property real targetNodeOffset: (siblingsCount > 1) ? ((localIndex / (siblingsCount - 1)) - 0.5) * arcSpread : 0
                            property real nodeOffset: targetNodeOffset
                            Behavior on nodeOffset { NumberAnimation { duration: 800; easing.type: Easing.OutExpo } }

                            property real parentCoreAngle: (window.globalOrbitAngle * 1.5) + parentBaseAngle
                            property real multiLiveAngle: myParentIdx === -1 ? singleLiveAngle : (parentCoreAngle + nodeOffset)

                            property int ringIndex: isInfoNode ? 0 : index % 2
                            property real targetRingOffset: ringIndex * 40
                            property real ringOffset: targetRingOffset
                            Behavior on ringOffset { NumberAnimation { duration: 800; easing.type: Easing.OutExpo } }

                            property real singleRadX: isInfoNode ? 280 : 320 + ringOffset
                            property real singleRadY: isInfoNode ? 180 : 200 + ringOffset
                            
                            // Scan node (-1) perfectly snaps to dead center (0,0) so it avoids crossing paths with Cores
                            property real multiRadX: isInfoNode ? (myParentIdx === -1 ? 0 : (window.activeCoreCount > 2 ? 180 : 160)) : 340 + ringOffset
                            property real multiRadY: isInfoNode ? (myParentIdx === -1 ? 0 : (window.activeCoreCount > 2 ? 180 : 160)) : 240 + ringOffset

                            property real currentRadX: (singleRadX * (1 - unifiedRatio)) + (multiRadX * unifiedRatio)
                            property real currentRadY: (singleRadY * (1 - unifiedRatio)) + (multiRadY * unifiedRatio)
                            property real currentAngle: (singleLiveAngle * (1 - unifiedRatio)) + (multiLiveAngle * unifiedRatio)
                            
                            property real pwrDrift: window.currentPower ? 0 : 40
                            Behavior on pwrDrift { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }

                            // Make the pop out start from 25% of the radius (outside the core) so it floats nicely
                            property real animRadX: (currentRadX + pwrDrift) * (0.25 + 0.75 * entryAnim)
                            property real animRadY: (currentRadY + pwrDrift) * (0.25 + 0.75 * entryAnim)

                            property real targetX: myParentIdx === -1 
                                ? (orbitContainer.width / 2) - (width / 2) + Math.cos(currentAngle) * animRadX
                                : parentX - (width / 2) + Math.cos(currentAngle) * animRadX
                                
                            property real targetY: myParentIdx === -1 
                                ? (orbitContainer.height / 2) - (height / 2) + Math.sin(currentAngle) * animRadY
                                : parentY - (height / 2) + Math.sin(currentAngle) * animRadY

                            property real liveBob: myParentIdx === -1 && isInfoNode 
                                ? Math.sin(window.globalOrbitAngle * 6) * 12 * (1 - unifiedRatio) 
                                : 0

                            x: targetX
                            y: targetY + liveBob

                            scale: (!isLoaded ? 0.0 : (floatMa.pressed ? dynamicScale * 0.95 : (floatCard.locksList ? dynamicScale * 1.08 : dynamicScale))) * floatCard.bumpScale
                            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
                            z: floatCard.locksList ? 10 : index

                            MultiEffect {
                                source: floatCard
                                anchors.fill: floatCard
                                shadowEnabled: window.currentPower && floatCardDelegateContainer.opacity > 0.05
                                shadowColor: "#000000"
                                shadowOpacity: 0.3
                                shadowBlur: 0.8
                                shadowVerticalOffset: 4
                                z: -1
                            }

                            Rectangle {
                                id: floatCard
                                anchors.fill: parent
                                radius: 14
                                
                                property string itemId: id
                                property string itemName: name
                                
                                property bool isMyBusy: !!window.busyTasks[itemId]
                                
                                property bool isPairedBT: window.activeMode === "bt" && action === "Connect"
                                property bool isTargetWifi: window.activeMode === "wifi" && !window.isWifiConn && itemId === window.targetWifiSsid
                                property bool isSpecialAction: itemId === "action_scan" || itemId === "action_settings"
                                property bool isHighlighted: isPairedBT || isTargetWifi || isSpecialAction
                                
                                property bool isCurrentlyConnected: {
                                    if (window.activeMode === "wifi") return (window.wifiConnected && window.wifiConnected.ssid === itemId);
                                    for (let i = 0; i < window.btConnected.length; i++) {
                                        if (window.btConnected[i].mac === itemId) return true;
                                    }
                                    return false;
                                }
                                
                                property bool isInteractable: !isInfoNode || isActionable
                                property bool locksList: isInteractable && (floatMa.containsMouse || floatMa.pressed)
                                onLocksListChanged: { if (locksList) window.hoveredCardCount++; else window.hoveredCardCount--; }
                                Component.onDestruction: { if (locksList) window.hoveredCardCount--; }
                                
                                property real bumpScale: 1.0
                                SequentialAnimation on bumpScale {
                                    id: cardBumpAnim
                                    running: false
                                    NumberAnimation { to: 1.2; duration: 200; easing.type: Easing.OutBack }
                                    NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.OutQuint }
                                }

                                property real nameImplicitWidth: baseNameText.implicitWidth
                                property real nameContainerWidth: nameContainerBase.width
                                property bool doMarquee: floatMa.containsMouse && nameImplicitWidth > nameContainerWidth
                                property real textOffset: 0

                                SequentialAnimation on textOffset {
                                    running: floatCard.doMarquee
                                    loops: Animation.Infinite
                                    PauseAnimation { duration: 600 } 
                                    NumberAnimation {
                                        from: 0
                                        to: -(floatCard.nameImplicitWidth + 30)
                                        duration: (floatCard.nameImplicitWidth + 30) * 35
                                    }
                                }
                                onDoMarqueeChanged: if (!doMarquee) textOffset = 0;

                                property real fillLevel: 0.0
                                property bool triggered: false
                                property real flashOpacity: 0.0
                                
                                property real renderFill: (isCurrentlyConnected) ? 1.0 : fillLevel
                                
                                onIsMyBusyChanged: {
                                    if (!isMyBusy && triggered) {
                                        triggered = false;
                                        if (!floatCard.isCurrentlyConnected) drainAnim.start();
                                    }
                                }
                                
                                onIsCurrentlyConnectedChanged: {
                                    if (!isCurrentlyConnected && fillLevel > 0) drainAnim.start();
                                }

                                color: locksList ? "#2affffff" : "#0effffff"
                                Behavior on color { ColorAnimation { duration: 200 } }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 14
                                    color: "transparent"
                                    border.width: 1
                                    border.color: window.surface2
                                    visible: !isHighlighted && !locksList
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 14
                                    opacity: locksList || isHighlighted ? 1.0 : 0.0
                                    color: "transparent"
                                    border.width: isHighlighted && !locksList ? 1 : 2
                                    Behavior on opacity { NumberAnimation { duration: 250 } }
                                    
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.margins: isHighlighted && !locksList ? 1 : 2
                                        radius: 12
                                        color: window.base
                                        opacity: locksList ? 0.9 : 1.0
                                    }
                                    
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: Qt.lighter(window.activeColor, 1.15) }
                                        GradientStop { position: 1.0; color: window.activeColor }
                                    }
                                    z: -1
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 14
                                    color: "#ffffff"
                                    opacity: floatCard.flashOpacity
                                    PropertyAnimation on opacity { id: cardFlashAnim; to: 0; duration: 500; easing.type: Easing.OutExpo }
                                    z: 5
                                }

                                Canvas {
                                    id: waveCanvas
                                    anchors.fill: parent
                                    
                                    property real wavePhase: 0.0
                                    
                                    NumberAnimation on wavePhase {
                                        running: floatCard.renderFill > 0.0 && floatCard.renderFill < 1.0
                                        loops: Animation.Infinite
                                        from: 0; to: Math.PI * 2
                                        duration: 800
                                    }

                                    onWavePhaseChanged: requestPaint()
                                    Connections { target: floatCard; function onRenderFillChanged() { waveCanvas.requestPaint() } }

                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height);
                                        if (floatCard.renderFill <= 0.001) return;

                                        var currentW = width * floatCard.renderFill;
                                        var r = 14; 

                                        ctx.save();
                                        ctx.beginPath();
                                        ctx.moveTo(0, 0);
                                        
                                        if (floatCard.renderFill < 0.99) {
                                            var waveAmp = 12 * Math.sin(floatCard.renderFill * Math.PI); 
                                            if (currentW - waveAmp < 0) waveAmp = currentW;
                                            var cp1x = currentW + Math.sin(wavePhase) * waveAmp;
                                            var cp2x = currentW + Math.cos(wavePhase + Math.PI) * waveAmp;

                                            ctx.lineTo(currentW, 0);
                                            ctx.bezierCurveTo(cp2x, height * 0.33, cp1x, height * 0.66, currentW, height);
                                            ctx.lineTo(0, height);
                                        } else {
                                            ctx.lineTo(width, 0);
                                            ctx.lineTo(width, height);
                                            ctx.lineTo(0, height);
                                        }
                                        ctx.closePath();
                                        ctx.clip(); 

                                        ctx.beginPath();
                                        ctx.moveTo(r, 0);
                                        ctx.lineTo(width - r, 0);
                                        ctx.arcTo(width, 0, width, r, r);
                                        ctx.lineTo(width, height - r);
                                        ctx.arcTo(width, height, width - r, height, r);
                                        ctx.lineTo(r, height);
                                        ctx.arcTo(0, height, 0, height - r, r);
                                        ctx.lineTo(0, r);
                                        ctx.arcTo(0, 0, r, 0, r);
                                        ctx.closePath();

                                        var grad = ctx.createLinearGradient(0, 0, currentW, 0);
                                        grad.addColorStop(0, Qt.lighter(window.activeColor, 1.15).toString());
                                        grad.addColorStop(1, window.activeColor.toString());
                                        ctx.fillStyle = grad;
                                        ctx.fill();

                                        ctx.restore();
                                    }
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: "transparent"
                                    border.color: window.activeColor
                                    border.width: 2
                                    visible: parent.isHighlighted && !parent.isMyBusy && !parent.isCurrentlyConnected
                                    
                                    SequentialAnimation on scale {
                                        loops: Animation.Infinite; running: parent.visible
                                        NumberAnimation { to: 1.15; duration: 1200; easing.type: Easing.InOutSine }
                                        NumberAnimation { to: 1.0; duration: 1200; easing.type: Easing.InOutSine }
                                    }
                                    SequentialAnimation on opacity {
                                        loops: Animation.Infinite; running: parent.visible
                                        NumberAnimation { to: 0.0; duration: 1200; easing.type: Easing.InOutSine }
                                        NumberAnimation { to: 0.8; duration: 1200; easing.type: Easing.InOutSine }
                                    }
                                }

                                RowLayout {
                                    id: baseTextRow
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 10
                                    
                                    Text {
                                        font.family: "Michroma"
                                        font.pixelSize: 20
                                        color: floatCard.isMyBusy ? window.text : window.activeColor
                                        text: icon
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                    
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        
                                        Item {
                                            id: nameContainerBase
                                            Layout.fillWidth: true
                                            height: 18
                                            clip: true

                                            Text {
                                                id: baseNameText
                                                anchors.left: parent.left
                                                anchors.leftMargin: floatCard.textOffset
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: floatCard.itemName
                                                font.family: "Michroma"
                                                font.weight: Font.Bold
                                                font.pixelSize: 13
                                                color: floatCard.isHighlighted ? window.activeColor : window.text
                                            }
                                            Text {
                                                anchors.left: baseNameText.right
                                                anchors.leftMargin: 30
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: floatCard.doMarquee
                                                text: floatCard.itemName
                                                font.family: "Michroma"
                                                font.weight: Font.Bold
                                                font.pixelSize: 13
                                                color: floatCard.isHighlighted ? window.activeColor : window.text
                                            }
                                        }
                                        
                                        Text {
                                            font.family: "Michroma"
                                            font.pixelSize: 10
                                            color: floatCard.isMyBusy ? window.activeColor : window.overlay0
                                            text: floatCard.isMyBusy ? "Connecting..." : (floatCard.renderFill > 0.1 && floatCard.renderFill < 1.0 ? "Hold..." : action)
                                            Behavior on color { ColorAnimation { duration: 200 } }
                                        }
                                    }
                                }

                                Item {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: floatCard.width * floatCard.renderFill
                                    clip: true
                                    
                                    RowLayout {
                                        x: baseTextRow.x; y: baseTextRow.y
                                        width: baseTextRow.width; height: baseTextRow.height
                                        spacing: 10
                                        
                                        Text { font.family: "Iosevka Nerd Font"; font.pixelSize: 20; color: window.crust; text: icon }
                                        
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2

                                            Item {
                                                Layout.fillWidth: true
                                                height: 18
                                                clip: true
                                                
                                                Text {
                                                    id: filledNameText
                                                    anchors.left: parent.left
                                                    anchors.leftMargin: floatCard.textOffset
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: floatCard.itemName
                                                    font.family: "Michroma"; font.weight: Font.Bold; font.pixelSize: 13; color: window.crust 
                                                }
                                                Text { 
                                                    anchors.left: filledNameText.right
                                                    anchors.leftMargin: 30
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    visible: floatCard.doMarquee
                                                    text: floatCard.itemName
                                                    font.family: "Michroma"; font.weight: Font.Bold; font.pixelSize: 13; color: window.crust 
                                                }
                                            }
                                            Text {
                                                font.family: "Michroma"; font.pixelSize: 10; color: window.crust
                                                text: floatCard.isMyBusy ? "Connecting..." : (floatCard.renderFill > 0.1 && floatCard.renderFill < 1.0 ? "Hold..." : action)
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    id: floatMa
                                    anchors.fill: parent
                                    hoverEnabled: floatCard.isInteractable
                                    
                                    cursorShape: (floatCard.triggered || floatCard.isMyBusy || floatCard.renderFill === 1.0 || !floatCard.isInteractable) ? Qt.ArrowCursor : Qt.PointingHandCursor
                                    
                                    onPressed: { 
                                        if (floatCard.isInteractable && !floatCard.triggered && !floatCard.isMyBusy && floatCard.fillLevel === 0.0) {
                                            drainAnim.stop()
                                            fillAnim.start()
                                        }
                                    }
                                    onReleased: {
                                        if (floatCard.isInteractable && !floatCard.triggered && !floatCard.isMyBusy && floatCard.fillLevel < 1.0) {
                                            fillAnim.stop()
                                            drainAnim.start()
                                        }
                                    }
                                }

                                NumberAnimation {
                                    id: fillAnim
                                    target: floatCard
                                    property: "fillLevel"
                                    to: 1.0
                                    duration: 600 * (1.0 - floatCard.fillLevel) 
                                    easing.type: Easing.InSine
                                    onFinished: {
                                        floatCard.triggered = true;
                                        floatCard.flashOpacity = 0.6;
                                        cardFlashAnim.start();
                                        cardBumpAnim.start();
                                        
                                        if (cmdStr === "TOGGLE_VIEW") {
                                            window.playSfx("switch.wav");
                                            window.showInfoView = !window.showInfoView;
                                            floatCard.triggered = false;
                                            drainAnim.start();
                                        } else if (isInfoNode && cmdStr) {
                                            Quickshell.execDetached(["sh", "-c", cmdStr]);
                                            if (window.activeMode === "bt") btPoller.running = true;
                                            floatCard.triggered = false;
                                            drainAnim.start(); 
                                        } else {
                                            let bt = window.busyTasks;
                                            bt[floatCard.itemId] = true;
                                            window.busyTasks = Object.assign({}, bt);
                                            busyTimeout.restart();
                                            
                                            let cmd = window.activeMode === "wifi"
                                                ? "nmcli device wifi connect '" + ssid + "'"
                                                : "bash " + window.scriptsDir + "/bluetooth_panel_logic.sh --connect " + mac
                                            
                                            Quickshell.execDetached(["sh", "-c", cmd]);
                                            if (window.activeMode === "wifi") wifiPoller.running = true; else btPoller.running = true;
                                        }
                                    }
                                }
                                
                                NumberAnimation {
                                    id: drainAnim
                                    target: floatCard
                                    property: "fillLevel"
                                    to: 0.0
                                    duration: 1500 * floatCard.fillLevel 
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    }
                }
            }

            // =========================================================
            // BOTTOM DOCK (Mode Switcher & Power)
            // =========================================================
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 25
                width: 360
                height: 54
                radius: 14
                color: "#1affffff" 
                border.color: "#1affffff"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 6

                    // Wi-Fi Mode Button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 10
                        
                        color: window.activeMode === "wifi" ? "transparent" : (wifiTabMa.containsMouse ? window.surface1 : "transparent")
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            opacity: window.activeMode === "wifi" ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Qt.lighter(window.wifiAccent, 1.15) }
                                GradientStop { position: 1.0; color: window.wifiAccent }
                            }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { font.family: "Iosevka Nerd Font"; font.pixelSize: 18; color: window.activeMode === "wifi" ? window.crust : window.text; text: "󰤨"; Behavior on color { ColorAnimation{duration:200} } }
                            Text { font.family: "Michroma"; font.weight: Font.Black; font.pixelSize: 13; color: window.activeMode === "wifi" ? window.crust : window.text; text: "Wi-Fi"; Behavior on color { ColorAnimation{duration:200} } }
                        }
                        MouseArea {
                            id: wifiTabMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (window.activeMode !== "wifi") window.playSfx("switch.wav");
                                window.activeMode = "wifi";
                            }
                        }
                    }

                    Rectangle { width: 1; Layout.fillHeight: true; Layout.margins: 5; color: "#33ffffff" }

                    // Bluetooth Mode Button
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 10
                        color: window.activeMode === "bt" ? "transparent" : (btTabMa.containsMouse ? window.surface1 : "transparent")
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            opacity: window.activeMode === "bt" ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 300 } }
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Qt.lighter(window.btAccent, 1.15) }
                                GradientStop { position: 1.0; color: window.btAccent }
                            }
                        }

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            Text { font.family: "Iosevka Nerd Font"; font.pixelSize: 18; color: window.activeMode === "bt" ? window.crust : window.text; text: "󰂯"; Behavior on color { ColorAnimation{duration:200} } }
                            Text { font.family: "Michroma"; font.weight: Font.Black; font.pixelSize: 13; color: window.activeMode === "bt" ? window.crust : window.text; text: "Bluetooth"; Behavior on color { ColorAnimation{duration:200} } }
                        }
                        MouseArea {
                            id: btTabMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (window.activeMode !== "bt") window.playSfx("switch.wav");
                                window.activeMode = "bt";
                            }
                        }
                    }
                }
            }

            // Power Toggle 
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 30
                width: 48; height: 48; radius: 24
                
                color: "transparent"
                border.color: window.currentPowerPending ? window.activeColor : (window.currentPower ? "transparent" : window.surface2)
                border.width: 2
                Behavior on border.color { ColorAnimation { duration: 300 } }

                Rectangle {
                    anchors.fill: parent
                    radius: 24
                    opacity: window.currentPower ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.lighter(window.activeColor, 1.15); Behavior on color { ColorAnimation {duration: 300} } }
                        GradientStop { position: 1.0; color: window.activeColor; Behavior on color { ColorAnimation {duration: 300} } }
                    }
                }
                
                scale: pwrMa.pressed ? 0.9 : (pwrMa.containsMouse ? 1.1 : 1.0)
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                Text {
                    id: pwrIcon
                    anchors.centerIn: parent
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 22
                    color: window.currentPower ? window.crust : window.text
                    text: window.currentPowerPending ? "󰑮" : "" 
                    Behavior on color { ColorAnimation { duration: 300 } }

                    RotationAnimation {
                        target: pwrIcon
                        property: "rotation"
                        from: 0; to: 360
                        duration: 800
                        loops: Animation.Infinite
                        running: window.currentPowerPending
                        onRunningChanged: {
                            if (!running) pwrIcon.rotation = 0;
                        }
                    }
                }

                MouseArea {
                    id: pwrMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (window.activeMode === "wifi") {
                            if (window.wifiPowerPending) return;
                            window.expectedWifiPower = window.wifiPower === "on" ? "off" : "on";
                            window.wifiPowerPending = true;
                            
                            if (window.expectedWifiPower === "on") window.playSfx("power_on.wav"); else window.playSfx("power_off.wav");
                            
                            wifiPendingReset.restart();
                            window.wifiPower = window.expectedWifiPower; // Optimistic
                            Quickshell.execDetached(["nmcli", "radio", "wifi", window.wifiPower]);
                            wifiPoller.running = true;
                        } else {
                            if (window.btPowerPending) return;
                            window.expectedBtPower = window.btPower === "on" ? "off" : "on";
                            window.btPowerPending = true;
                            
                            if (window.expectedBtPower === "on") window.playSfx("power_on.wav"); else window.playSfx("power_off.wav");
                            
                            btPendingReset.restart();
                            window.btPower = window.expectedBtPower; // Optimistic
                            Quickshell.execDetached(["bash", window.scriptsDir + "/bluetooth_panel_logic.sh", "--toggle"]);
                            btPoller.running = true;
                        }
                    }
                }
            }
        }
    }
}
