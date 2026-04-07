import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtCore
import Quickshell
import Quickshell.Io
import "../"
import "../i18n"

Item {
    id: window
   // -------------------------------------------------------------------------
    // COLORS (Dynamic Matugen Palette)
    // -------------------------------------------------------------------------
    MatugenColors { id: _theme }
    readonly property color base: _theme.base
    readonly property color mantle: _theme.mantle
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext0: _theme.subtext0
    readonly property color overlay0: _theme.overlay0
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    
    readonly property color mauve: _theme.mauve
    readonly property color pink: _theme.pink
    readonly property color red: _theme.red
    readonly property color peach: _theme.peach
    readonly property color yellow: _theme.yellow
    readonly property color green: _theme.green
    readonly property color sapphire: _theme.sapphire
    readonly property color blue: _theme.blue

    readonly property var monthNames: [
        I18n.s("January"), I18n.s("February"), I18n.s("March"), I18n.s("April"),
        I18n.s("May"), I18n.s("June"), I18n.s("July"), I18n.s("August"),
        I18n.s("September"), I18n.s("October"), I18n.s("November"), I18n.s("December")
    ]

    // -------------------------------------------------------------------------
    // STATE & POLLING PATHS
    // -------------------------------------------------------------------------
    property var globalDate: new Date()
    property var appDate: new Date()
    readonly property var activeDate: window.selectedAppClass === "" ? window.globalDate : window.appDate

    property string selectedDateStr: ""
    property string selectedAppClass: "" 
    property string selectedAppName: ""
    property string selectedAppIcon: ""
    property int totalSeconds: 0
    property int averageSeconds: 0
    property int yesterdaySeconds: 0
    property string weekRangeStr: ""
    property string liveActiveApp: I18n.s("Desktop")
    
    // UI State for Week Overview
    property bool isWeekView: false
    
    property var topApps: []
    property var weekData: []
    property real maxWeekTotal: 1 
    property var monthData: []
    property real maxMonthTotal: 1
    
    // Week Overview specific data
    property var weekAppsData: []
    property var weekHeatmapData: [[],[],[],[],[],[],[]]
    property real maxWeekHour: 1
    property string peakUsageHours: I18n.s("N/A")

    // 48 blocks for 30-minute intervals (2 bars per hour)
    property var hourlyData: new Array(48).fill(0)
    property real maxHourlyTotal: 1
    
    // Animation properties
    property real animatedTotalSeconds: 0
    Behavior on animatedTotalSeconds {
        NumberAnimation { duration: 850; easing.type: Easing.OutQuint }
    }
    onTotalSecondsChanged: {
        animatedTotalSeconds = totalSeconds;
    }

    // --- ENHANCED UI NAVIGATION FOCUS STATES ---
    property real weekViewFocus: window.isWeekView ? 1.0 : 0.0
    Behavior on weekViewFocus {
        NumberAnimation { duration: 550; easing.type: Easing.OutExpo }
    }

    property real appViewFocus: window.selectedAppClass !== "" ? 1.0 : 0.0
    Behavior on appViewFocus {
        NumberAnimation { duration: 550; easing.type: Easing.OutExpo }
    }

    property bool isFirstLoad: true
    readonly property bool isTodaySelected: window.selectedDateStr === getIsoDate(new Date())

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/focustime"
    readonly property string xdgRuntime: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property string stateFilePath: window.xdgRuntime + "/focustime_state.json"

    // --- ENHANCED CHOREOGRAPHED STARTUP STATES ---
    property real introMain: 0.0
    property real introHeader: 0.0
    property real introStats: 0.0
    property real introMidLeft: 0.0
    property real introMidRight: 0.0
    property real introBottom: 0.0
    property real introAppBars: 0.0

    ParallelAnimation {
        running: true

        // Base window fades, scales slightly
        NumberAnimation { target: window; property: "introMain"; from: 0; to: 1.0; duration: 900; easing.type: Easing.OutQuart }

        // Header drops down
        SequentialAnimation {
            PauseAnimation { duration: 100 }
            NumberAnimation { target: window; property: "introHeader"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutBack; easing.overshoot: 1.0 }
        }

        // Stats Row scales and springs up
        SequentialAnimation {
            PauseAnimation { duration: 250 }
            NumberAnimation { target: window; property: "introStats"; from: 0; to: 1.0; duration: 900; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        }

        // Mid Charts slide in from opposite sides
        SequentialAnimation {
            PauseAnimation { duration: 350 }
            NumberAnimation { target: window; property: "introMidLeft"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutQuart }
        }
        
        // Universal Bar Fill starts early, runs slow and smooth
        SequentialAnimation {
            PauseAnimation { duration: 300 } // Starts slightly before the charts finish entering
            NumberAnimation { target: window; property: "introAppBars"; from: 0; to: 1.0; duration: 1300; easing.type: Easing.OutQuart }
        }
        
        SequentialAnimation {
            PauseAnimation { duration: 450 }
            NumberAnimation { target: window; property: "introMidRight"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutQuart }
        }

        // Bottom List / Chart sweeps up with internal cascading
        SequentialAnimation {
            PauseAnimation { duration: 550 }
            NumberAnimation { target: window; property: "introBottom"; from: 0; to: 1.0; duration: 1000; easing.type: Easing.OutExpo }
        }
    }

    Component.onCompleted: {
        requestDataUpdate();
    }

    // Clean, unified exit animation for when an action is clicked
    ParallelAnimation {
        id: exitAnim
        NumberAnimation { target: window; property: "introMain"; to: 0; duration: 400; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introHeader"; to: 0; duration: 300; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introStats"; to: 0; duration: 350; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introMidLeft"; to: 0; duration: 250; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introMidRight"; to: 0; duration: 200; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introBottom"; to: 0; duration: 150; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introAppBars"; to: 0; duration: 250; easing.type: Easing.InQuart }
    }

    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 120000; loops: Animation.Infinite; running: true
    }

    // --- SHARED DATA INGESTION ---
    function updateFromData(data) {
        window.selectedDateStr = data.selected_date;
        window.totalSeconds = data.total || 0;
        window.averageSeconds = data.average || 0;
        window.yesterdaySeconds = data.yesterday || 0;
        window.weekRangeStr = data.week_range || "";
        window.liveActiveApp = data.current || I18n.s("Unknown");

        if (window.isFirstLoad) firstLoadTimer.start();

        window.topApps = data.apps || [];
        syncAppsModel();

        window.weekAppsData = data.week_apps || [];
        syncWeekAppsModel();

        // Calculate maximum hourly segment and Peak Usage for the week heatmap
        window.weekHeatmapData = data.week_heatmap || [[],[],[],[],[],[],[]];
        let mwh = 1;
        let hourSums = new Array(24).fill(0);
        
        for (let i = 0; i < 7; i++) {
            if (!window.weekHeatmapData[i]) continue;
            for (let j = 0; j < 24; j++) {
                if (window.weekHeatmapData[i][j] > mwh) mwh = window.weekHeatmapData[i][j];
                hourSums[j] += window.weekHeatmapData[i][j];
            }
        }
        window.maxWeekHour = mwh;

        // Custom Peak Hours Block Calculation (One UI Style)
        let max2HourVal = -1;
        let peakStart = 0;
        for (let h = 0; h < 23; h++) {
            let current2H = hourSums[h] + hourSums[h+1];
            if (current2H > max2HourVal) {
                max2HourVal = current2H;
                peakStart = h;
            }
        }
        
        function formatAMPM(hour) {
            let ampm = hour >= 12 ? 'PM' : 'AM';
            let h12 = hour % 12;
            h12 = h12 ? h12 : 12;
            return h12 + ' ' + ampm;
        }
        
        if (max2HourVal > 0) {
            window.peakUsageHours = formatAMPM(peakStart) + " - " + formatAMPM(peakStart + 2);
        } else {
            window.peakUsageHours = I18n.s("N/A");
        }

        let parsedWeek = data.week || [];
        if (JSON.stringify(window.weekData) !== JSON.stringify(parsedWeek)) {
            window.weekData = parsedWeek;
            syncWeekModel();
        }

        let parsedMonth = data.month || [];
        if (JSON.stringify(window.monthData) !== JSON.stringify(parsedMonth)) {
            window.monthData = parsedMonth;
            syncMonthModel();
        }

        window.hourlyData = data.hourly || new Array(48).fill(0);
        let currentMaxHour = 1;
        for(let i=0; i<48; i++) {
            if (window.hourlyData[i] > currentMaxHour) currentMaxHour = window.hourlyData[i];
        }
        window.maxHourlyTotal = currentMaxHour;
    }

    // --- DATA FETCHING ROUTING ---
    function requestDataUpdate() {
        if (window.selectedAppClass === "" && getIsoDate(window.activeDate) === getIsoDate(new Date())) {
            liveFileReader.running = true;
        } else {
            let cmd = ["python3", window.scriptsDir + "/get_stats.py", getIsoDate(window.activeDate)];
            if (window.selectedAppClass !== "") {
                cmd.push("--app");
                cmd.push(window.selectedAppClass);
            }
            statsPoller.command = cmd;
            statsPoller.running = true;
        }
    }

    // --- LIVE FILE READER (For Global Today) ---
    Process {
        id: liveFileReader
        command: ["cat", window.stateFilePath]
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = this.text.trim();
                if (raw === "") return;
                try {
                    let data = JSON.parse(raw);
                    window.updateFromData(data);
                } catch(e) {}
            }
        }
    }

    Timer { 
        interval: 1000
        running: window.isTodaySelected 
        repeat: true
        onTriggered: window.requestDataUpdate()
    }

    // --- PYTHON STATS FETCHER (For History & Specific Apps) ---
    Process {
        id: statsPoller
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = this.text.trim();
                if (raw === "") return;
                try {
                    let data = JSON.parse(raw);
                    window.updateFromData(data);
                } catch(e) {}
            }
        }
    }

    // --- DATE HELPERS ---
    function getIsoDate(d) {
        let z = d.getTimezoneOffset() * 60000;
        return (new Date(d - z)).toISOString().slice(0, 10);
    }

    function getFancyDate(d) {
        let monthName = window.monthNames[d.getMonth()];
        let dateNum = d.getDate();
        let isToday = getIsoDate(d) === getIsoDate(new Date());
        return isToday ? I18n.s("Today") : `${monthName} ${dateNum}`;
    }

    function changeDay(offsetDays) {
        let d = new Date(window.activeDate);
        d.setDate(d.getDate() + offsetDays);
        if (window.selectedAppClass === "") {
            window.globalDate = d;
        } else {
            window.appDate = d;
        }
        window.isFirstLoad = true; 
        window.requestDataUpdate();
    }
    
    function changeToDate(clickedDateStr) {
        if (!clickedDateStr) return;
        let currentIso = getIsoDate(window.activeDate);
        if (clickedDateStr === currentIso) return;
        let dCurrent = new Date(currentIso + "T12:00:00");
        let dClicked = new Date(clickedDateStr + "T12:00:00");
        let diffDays = Math.round((dClicked - dCurrent) / (1000 * 60 * 60 * 24));
        if (diffDays !== 0) changeDay(diffDays);
    }

    Timer {
        id: firstLoadTimer
        interval: 1000
        onTriggered: window.isFirstLoad = false
    }

    ListModel { id: appListModel }
    ListModel { id: weekAppListModel }
    ListModel { id: weekListModel }
    ListModel { id: monthListModel }

    function syncAppsModel() {
        for (let i = 0; i < window.topApps.length; i++) {
            let app = window.topApps[i];
            if (i < appListModel.count) {
                appListModel.setProperty(i, "name", app.name);
                appListModel.setProperty(i, "appClass", app.class);
                appListModel.setProperty(i, "icon", app.icon || "");
                appListModel.setProperty(i, "seconds", app.seconds);
                appListModel.setProperty(i, "percent", app.percent);
            } else {
                appListModel.append({
                    name: app.name,
                    appClass: app.class,
                    icon: app.icon || "",
                    seconds: app.seconds,
                    percent: app.percent,
                    idx: i
                });
            }
        }
        while (appListModel.count > window.topApps.length) {
            appListModel.remove(appListModel.count - 1);
        }
    }

    function syncWeekAppsModel() {
        for (let i = 0; i < window.weekAppsData.length; i++) {
            let app = window.weekAppsData[i];
            if (i < weekAppListModel.count) {
                weekAppListModel.setProperty(i, "name", app.name);
                weekAppListModel.setProperty(i, "appClass", app.class);
                weekAppListModel.setProperty(i, "icon", app.icon || "");
                weekAppListModel.setProperty(i, "seconds", app.seconds);
                weekAppListModel.setProperty(i, "percent", app.percent);
            } else {
                weekAppListModel.append({
                    name: app.name,
                    appClass: app.class,
                    icon: app.icon || "",
                    seconds: app.seconds,
                    percent: app.percent,
                    idx: i
                });
            }
        }
        while (weekAppListModel.count > window.weekAppsData.length) {
            weekAppListModel.remove(weekAppListModel.count - 1);
        }
    }

    function syncWeekModel() {
        let currentMax = 1;
        for (let i = 0; i < window.weekData.length; i++) {
            if (window.weekData[i].total > currentMax) currentMax = window.weekData[i].total;
        }
        window.maxWeekTotal = currentMax;

        for (let i = 0; i < window.weekData.length; i++) {
            let w = window.weekData[i];
            if (i < weekListModel.count) {
                weekListModel.setProperty(i, "dateStr", w.date);
                weekListModel.setProperty(i, "dayName", w.day);
                weekListModel.setProperty(i, "total", w.total);
                weekListModel.setProperty(i, "isTarget", w.is_target);
            } else {
                weekListModel.append({
                    dateStr: w.date,
                    dayName: w.day,
                    total: w.total,
                    isTarget: w.is_target
                });
            }
        }
        while (weekListModel.count > window.weekData.length) {
            weekListModel.remove(weekListModel.count - 1);
        }
    }

    function syncMonthModel() {
        let currentMax = 1;
        for (let i = 0; i < window.monthData.length; i++) {
            if (window.monthData[i].total > currentMax) currentMax = window.monthData[i].total;
        }
        window.maxMonthTotal = currentMax;

        for (let i = 0; i < window.monthData.length; i++) {
            let m = window.monthData[i];
            if (i < monthListModel.count) {
                monthListModel.setProperty(i, "dateStr", m.date);
                monthListModel.setProperty(i, "total", m.total);
                monthListModel.setProperty(i, "isTarget", m.is_target);
            } else {
                monthListModel.append({
                    dateStr: m.date,
                    total: m.total,
                    isTarget: m.is_target
                });
            }
        }
        while (monthListModel.count > window.monthData.length) {
            monthListModel.remove(monthListModel.count - 1);
        }
    }

    function formatTimeLarge(secs) {
        let h = Math.floor(secs / 3600);
        let m = Math.floor((secs % 3600) / 60);
        if (h > 0) return h + "h " + m + "m";
        return m + "m";
    }

    function formatTimeList(secs) {
        let h = Math.floor(secs / 3600);
        let m = Math.floor((secs % 3600) / 60);
        if (h > 0) return h + "h " + m.toString().padStart(2, '0') + "m";
        return m + "m";
    }

    // -------------------------------------------------------------------------
    // KEYBOARD SHORTCUTS
    // -------------------------------------------------------------------------
    Shortcut { sequence: "Left"; onActivated: changeDay(-1) }
    Shortcut { sequence: "Right"; onActivated: changeDay(1) }
    Shortcut { sequence: "Home"; onActivated: changeDay(-7) }
    Shortcut { sequence: "End"; onActivated: changeDay(7) }
    
    // Escape key handling: Only intercepts if we are in a sub-view
    Shortcut { 
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: window.selectedAppClass !== "" || window.isWeekView
        onActivated: {
            if (window.selectedAppClass !== "") {
                window.selectedAppClass = ""; 
                window.selectedAppName = ""; 
                window.selectedAppIcon = ""; 
                window.requestDataUpdate(); 
            } else if (window.isWeekView) {
                window.isWeekView = false;
            }
        }
    }

    // -------------------------------------------------------------------------
    // UI LAYOUT
    // -------------------------------------------------------------------------
    Item {
        anchors.fill: parent
        scale: 0.97 + (0.03 * introMain)
        opacity: introMain

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: window.crust
            border.color: Qt.alpha(window.surface1, 0.2)
            border.width: 1
            clip: true

            Rectangle {
                width: parent.width * 1.2; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * 150
                y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * 100
                opacity: 0.015
                color: window.mauve
            }
            Rectangle {
                width: parent.width * 1.1; height: width; radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * -150
                y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * -100
                opacity: 0.010
                color: window.blue
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                // ==========================================
                // 1. HEADER
                // ==========================================
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Layout.preferredHeight: 40

                    opacity: introHeader
                    transform: Translate { y: -20 * (1 - introHeader) }
                    
                    // Left Buttons (Overlapped to prevent layout shifting)
                    RowLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        // Wrapper to hold Back and Week buttons in the exact same 40x40 footprint
                        Item {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40

                            // Universal Return Arrow (Back to Daily / App List)
                            Rectangle {
                                anchors.fill: parent
                                radius: 20
                                color: backMa.containsMouse ? window.surface0 : "transparent"
                                opacity: (window.selectedAppClass !== "" || window.isWeekView) ? 1.0 : 0.0
                                visible: opacity > 0
                                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Text { anchors.centerIn: parent; font.family: "Iosevka Nerd Font"; text: "󰁍"; color: window.text; font.pixelSize: 18 }
                                MouseArea { 
                                    id: backMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; 
                                    onClicked: { 
                                        if (window.selectedAppClass !== "") {
                                            window.selectedAppClass = ""; 
                                            window.selectedAppName = ""; 
                                            window.selectedAppIcon = ""; 
                                            window.requestDataUpdate(); 
                                        } else if (window.isWeekView) {
                                            window.isWeekView = false;
                                        }
                                    } 
                                }
                            }

                            // Week View Open Button
                            Rectangle {
                                anchors.fill: parent
                                radius: 20
                                color: weekMa.containsMouse ? window.surface0 : "transparent"
                                opacity: (window.selectedAppClass === "" && !window.isWeekView) ? 1.0 : 0.0
                                visible: opacity > 0
                                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Text { anchors.centerIn: parent; font.family: "Iosevka Nerd Font"; text: "󰃭"; color: window.text; font.pixelSize: 18 }
                                MouseArea { 
                                    id: weekMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; 
                                    onClicked: window.isWeekView = true 
                                }
                            }
                        }

                        // Prev Week/Day Arrow
                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: 20
                            color: prevWeekMa.containsMouse ? window.surface0 : "transparent"
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text { anchors.centerIn: parent; font.family: "Iosevka Nerd Font"; text: "󰅁"; color: window.text; font.pixelSize: 18 }
                            MouseArea { id: prevWeekMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: changeDay(-1) }
                        }
                    }                    
                    // Title Area
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8
                        
                        Item { Layout.fillWidth: true } // Left Spacer

                        Image {
                            property bool active: window.selectedAppClass !== "" && window.selectedAppIcon !== "" && !window.isWeekView
                            property real animWidth: active ? 20 : 0
                            Behavior on animWidth { NumberAnimation { duration: 350; easing.type: Easing.OutQuint } }

                            source: window.selectedAppIcon.startsWith("/") ? "file://" + window.selectedAppIcon : "image://icon/" + window.selectedAppIcon
                            sourceSize: Qt.size(20, 20)
                            Layout.preferredWidth: animWidth
                            Layout.preferredHeight: 20
                            Layout.alignment: Qt.AlignVCenter
                            Layout.rightMargin: active ? 8 : 0
                            opacity: animWidth / 20.0
                            visible: animWidth > 0
                            fillMode: Image.PreserveAspectFit
                            clip: true
                        }

                        Text {
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: "Michroma"
                            font.weight: Font.DemiBold
                            font.pixelSize: 18
                            color: window.text
                            text: window.isWeekView ? (window.weekRangeStr !== "" ? window.weekRangeStr : I18n.s("Week Overview")) : (window.selectedAppClass !== "" ? `${window.selectedAppName} - ${window.getFancyDate(window.activeDate)}` : window.getFancyDate(window.activeDate))
                        }

                        Item { Layout.fillWidth: true } // Right Spacer
                    }

                    // Next Week/Day Arrow
                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 20
                        color: nextWeekMa.containsMouse ? window.surface0 : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Text { anchors.centerIn: parent; font.family: "Iosevka Nerd Font"; text: "󰅂"; color: window.text; font.pixelSize: 18 }
                        MouseArea { id: nextWeekMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: changeDay(1) }
                    }
                }

                // ==========================================
                // MASTER VIEW CONTAINER
                // Smoothly handles Daily vs Week layout transitions
                // ==========================================
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // ==========================================
                    // NORMAL DAILY & APP VIEW WRAPPER
                    // ==========================================
                    ColumnLayout {
                        id: dailyViewWrapper
                        anchors.fill: parent
                        spacing: 16
                        
                        opacity: 1.0 - window.weekViewFocus
                        visible: opacity > 0
                        transform: Translate { x: -40 * window.weekViewFocus }
                        scale: 0.95 + (0.05 * (1.0 - window.weekViewFocus)) // Smooth fluid scale backward

                        // ==========================================
                        // 1.5 TOTAL TIME DISPLAY + AVERAGES (3 BOXES)
                        // ==========================================
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 90
                            Layout.maximumHeight: 90 
                            Layout.minimumHeight: 90
                            spacing: 16

                            opacity: introStats
                            transform: Translate { y: 30 * (1 - introStats) }

                            // LEFT: Daily Average (2/7 weight = 200)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 200
                                radius: 14
                                color: window.base
                                border.color: Qt.alpha(window.surface1, 0.3)
                                border.width: 1

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 2
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        font.family: "Michroma"
                                        font.weight: Font.DemiBold
                                        font.pixelSize: 14
                                        color: window.subtext0
                                        text: I18n.s("Daily average")
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        font.family: "Michroma"
                                        font.weight: Font.Bold
                                        font.pixelSize: 20
                                        color: window.text
                                        text: window.formatTimeList(window.averageSeconds)
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        font.family: "Michroma"
                                        font.weight: Font.Medium
                                        font.pixelSize: 12
                                        color: window.overlay0
                                        text: window.weekRangeStr
                                        visible: window.weekRangeStr !== ""
                                    }
                                }
                            }

                            // CENTER: Usage Time (3/7 weight = 300)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 300
                                radius: 14
                                color: window.base
                                border.color: Qt.alpha(window.surface1, 0.3)
                                border.width: 1

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 0
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        font.family: "Michroma"
                                        font.weight: Font.Black
                                        font.pixelSize: 36
                                        color: window.text
                                        text: window.formatTimeLarge(window.animatedTotalSeconds)
                                    }
                                }
                            }

                            // RIGHT: vs Yesterday Increase (2/7 weight = 200)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 200
                                radius: 14
                                color: window.base
                                border.color: Qt.alpha(window.surface1, 0.3)
                                border.width: 1

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    
                                    // Trend Row
                                    RowLayout {
                                        Layout.alignment: Qt.AlignHCenter
                                        spacing: 8
                                        visible: !(window.totalSeconds === 0 && window.yesterdaySeconds === 0) && window.totalSeconds !== window.yesterdaySeconds
                                        
                                        Text {
                                            font.family: "Michroma"
                                            font.weight: Font.Black
                                            font.pixelSize: 28
                                            color: {
                                                let diff = window.totalSeconds - window.yesterdaySeconds;
                                                return diff > 0 ? window.peach : window.green;
                                            }
                                            text: (window.totalSeconds - window.yesterdaySeconds) > 0 ? "↑" : "↓"
                                        }
                                        
                                        Text {
                                            font.family: "Michroma"
                                            font.weight: Font.Bold
                                            font.pixelSize: 28
                                            color: {
                                                let diff = window.totalSeconds - window.yesterdaySeconds;
                                                return diff > 0 ? window.peach : window.green;
                                            }
                                            text: {
                                                let diff = window.totalSeconds - window.yesterdaySeconds;
                                                return window.formatTimeList(Math.abs(diff));
                                            }
                                        }
                                    }

                                    // No Data / Same fallback
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        font.family: "Michroma"
                                        font.weight: Font.DemiBold
                                        font.pixelSize: 15
                                        color: window.overlay0
                                        text: (window.totalSeconds === 0 && window.yesterdaySeconds === 0) ? I18n.s("No data") : I18n.s("Same time")
                                        visible: (window.totalSeconds === 0 && window.yesterdaySeconds === 0) || window.totalSeconds === window.yesterdaySeconds
                                    }
                                }
                            }
                        }

                        // ==========================================
                        // 2. MIDDLE CHARTS (Week + Heatmap)
                        // ==========================================
                        RowLayout {
                            id: middleSection
                            Layout.fillWidth: true
                            Layout.preferredHeight: 160
                            Layout.fillHeight: false
                            spacing: 16

                            // LEFT: Weekly Close-Knit Bar Chart
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 400 
                                radius: 14
                                color: window.base
                                border.color: Qt.alpha(window.surface1, 0.3)
                                border.width: 1

                                opacity: introMidLeft
                                transform: Translate { x: -30 * (1 - introMidLeft) }

                                RowLayout {
                                    anchors.centerIn: parent
                                    height: parent.height - 32
                                    spacing: 12 

                                    Repeater {
                                        model: weekListModel
                                        delegate: Item {
                                            Layout.fillHeight: true
                                            Layout.preferredWidth: 45 

                                            MouseArea {
                                                id: barMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    window.changeToDate(model.dateStr);
                                                }
                                            }

                                            Item {
                                                anchors.bottom: dayLbl.top
                                                anchors.bottomMargin: 8
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: 45 
                                                // Tied strictly to the introAppBars multiplier for fluid simultaneous fill
                                                height: Math.max(4, (parent.height - 25) * (model.total / Math.max(window.maxWeekTotal, 1)) * window.introAppBars)
                                                Behavior on height { 
                                                    // ONLY enable reactive behavior after the startup cascade is fully complete
                                                    enabled: window.introAppBars === 1.0 
                                                    NumberAnimation { duration: 600; easing.type: Easing.OutQuint } 
                                                }

                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: 4 
                                                    color: window.surface0
                                                    visible: !model.isTarget
                                                    opacity: barMa.containsMouse ? 0.7 : 1.0
                                                    Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.OutCubic } }
                                                }

                                                Rectangle {
                                                    anchors.fill: parent
                                                    radius: 4 
                                                    visible: model.isTarget
                                                    opacity: barMa.containsMouse ? 0.7 : 1.0
                                                    gradient: Gradient {
                                                        GradientStop { position: 0.0; color: window.mauve }
                                                        GradientStop { position: 1.0; color: window.blue }
                                                    }
                                                }
                                            }

                                            Text {
                                                id: dayLbl
                                                anchors.bottom: parent.bottom
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                font.family: "Michroma"
                                                font.weight: Font.DemiBold
                                                font.pixelSize: 12
                                                color: model.isTarget ? window.text : window.overlay0
                                                text: model.dayName 
                                                Behavior on color { ColorAnimation { duration: 400 } }
                                            }
                                        }
                                    }
                                }
                            }

                            // RIGHT: Calendar Month Heatmap
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.preferredWidth: 300
                                radius: 14
                                color: window.base
                                border.color: Qt.alpha(window.surface1, 0.3)
                                border.width: 1

                                opacity: introMidRight
                                transform: Translate { x: 30 * (1 - introMidRight) }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        font.family: "Michroma"
                                        font.weight: Font.DemiBold
                                        font.pixelSize: 14
                                        color: window.text
                                        text: window.monthNames[window.activeDate.getMonth()]
                                    }

                                    Grid {
                                        Layout.alignment: Qt.AlignCenter
                                        columns: 7 
                                        flow: Grid.LeftToRight 
                                        spacing: 6 

                                        Repeater {
                                            model: monthListModel
                                            delegate: Rectangle {
                                                width: 18 
                                                height: 18 
                                                radius: 4
                                                color: model.total === -1 ? "transparent" : (model.total === 0 ? window.surface0 : Qt.rgba(window.mauve.r, window.mauve.g, window.mauve.b, Math.min(1.0, 0.3 + 0.7 * (model.total / window.maxMonthTotal))))
                                                Behavior on color { ColorAnimation { duration: 700; easing.type: Easing.OutQuint } }

                                                border.color: model.isTarget ? window.text : "transparent"
                                                border.width: model.isTarget ? 1 : 0
                                                Behavior on border.color { ColorAnimation { duration: 300 } }
                                                
                                                visible: model.total !== -1

                                                // Slight animated bounce upon load
                                                scale: 0.7 + (0.3 * introMidRight)

                                                MouseArea {
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    enabled: model.total !== -1
                                                    onClicked: {
                                                        if (model.total !== -1) {
                                                            window.changeToDate(model.dateStr);
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ==========================================
                        // 3. BOTTOM CARD (App List OR Hourly Chart)
                        // Uses appViewFocus to smoothly transition natively
                        // ==========================================
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true 
                            radius: 14
                            color: window.base
                            border.color: Qt.alpha(window.surface1, 0.3)
                            border.width: 1

                            opacity: introBottom
                            transform: Translate { y: 30 * (1 - introBottom) }
                            
                            Item {
                                anchors.fill: parent

                                // --- VIEW A: App List ---
                                ListView {
                                    id: appList
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    anchors.topMargin: 12
                                    anchors.bottomMargin: 12
                                    
                                    opacity: 1.0 - window.appViewFocus
                                    visible: opacity > 0
                                    transform: Translate { x: -30 * window.appViewFocus }
                                    scale: 0.95 + (0.05 * (1.0 - window.appViewFocus)) // Native slide-and-scale

                                    model: appListModel
                                    interactive: true 
                                    clip: true        
                                    spacing: 2
                                    
                                    move: Transition { NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutQuint } }
                                    
                                    ScrollBar.vertical: ScrollBar {
                                        active: appList.moving || appList.movingVertically
                                        width: 4
                                        policy: ScrollBar.AsNeeded
                                        contentItem: Rectangle { implicitWidth: 4; radius: 2; color: window.surface2 }
                                    }
                                    
                                    delegate: Rectangle {
                                        width: ListView.view.width
                                        height: 58 
                                        color: "transparent"
                                        radius: 10

                                        // Micro-staggering cascading animation inside the list
                                        opacity: introBottom
                                        transform: Translate { y: (index * 12) * (1 - introBottom) }

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 10
                                            color: rowMa.containsMouse ? window.surface0 : "transparent"
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                        }

                                        MouseArea {
                                            id: rowMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                window.selectedAppClass = model.appClass;
                                                window.selectedAppName = model.name;
                                                window.selectedAppIcon = model.icon;
                                                window.appDate = new Date(); // Always start app view on today
                                                window.requestDataUpdate();
                                            }
                                        }

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 16
                                            anchors.rightMargin: 16
                                            anchors.topMargin: 10
                                            anchors.bottomMargin: 10
                                            spacing: 6

                                            RowLayout {
                                                Layout.fillWidth: true
                                                
                                                Image {
                                                    visible: model.icon !== ""
                                                    source: model.icon.startsWith("/") ? "file://" + model.icon : "image://icon/" + model.icon
                                                    sourceSize: Qt.size(20, 20)
                                                    Layout.preferredWidth: 20
                                                    Layout.preferredHeight: 20
                                                    Layout.alignment: Qt.AlignVCenter
                                                    Layout.rightMargin: 8
                                                    fillMode: Image.PreserveAspectFit
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    font.family: "Michroma"
                                                    font.weight: Font.DemiBold
                                                    font.pixelSize: 15
                                                    color: window.text
                                                    text: model.name
                                                    elide: Text.ElideRight
                                                }
                                                Text {
                                                    font.family: "Michroma"
                                                    font.weight: Font.Medium
                                                    font.pixelSize: 14
                                                    color: window.subtext0
                                                    text: window.formatTimeList(model.seconds)
                                                }
                                            }

                                            Item {
                                                Layout.fillWidth: true
                                                height: 10
                                                Rectangle { anchors.fill: parent; radius: 5; color: window.crust }
                                                Rectangle {
                                                    height: parent.height
                                                    // Tied to the synchronized app bars state
                                                    width: Math.max(10, parent.width * (model.percent / 100.0) * window.introAppBars)
                                                    radius: 5
                                                    gradient: Gradient {
                                                        orientation: Gradient.Horizontal
                                                        GradientStop { position: 0.0; color: window.mauve }
                                                        GradientStop { position: 1.0; color: window.blue }
                                                    }
                                                    Behavior on width { 
                                                        enabled: window.introAppBars === 1.0
                                                        NumberAnimation { duration: 600; easing.type: Easing.OutQuint } 
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // --- VIEW B: 24-Hour App Activity Chart (Now 48 chunks / 30 mins) ---
                                ColumnLayout {
                                    id: appChartWrapper
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 12

                                    opacity: window.appViewFocus
                                    visible: opacity > 0
                                    transform: Translate { x: 30 * (1 - window.appViewFocus) }
                                    scale: 0.95 + (0.05 * window.appViewFocus) // Native slide-and-scale zoom in

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        font.family: "Michroma"
                                        font.weight: Font.DemiBold
                                        font.pixelSize: 14
                                        color: window.text
                                        text: I18n.s("Daily usage")
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        spacing: 4 

                                        Repeater {
                                            model: 48 // 2 bars per hour (30 min intervals)
                                            delegate: Item {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true

                                                Rectangle {
                                                    anchors.bottom: parent.bottom
                                                    width: parent.width
                                                    // Actively grow from ground up tied to introAppBars
                                                    height: Math.max(4, parent.height * (window.hourlyData[index] / Math.max(window.maxHourlyTotal, 1)) * window.introAppBars)
                                                    radius: 2
                                                    color: window.hourlyData[index] > 0 ? window.blue : window.surface0
                                                    
                                                    Behavior on height { 
                                                        enabled: window.introAppBars === 1.0
                                                        NumberAnimation { duration: 600; easing.type: Easing.OutQuint } 
                                                    }
                                                    Behavior on color { ColorAnimation { duration: 400 } }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        onEntered: { parent.opacity = 0.7 }
                                                        onExited: { parent.opacity = 1.0 }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // X-Axis Labels 24h
                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { font.family: "Michroma"; font.weight: Font.Medium; font.pixelSize: 11; color: window.overlay0; text: I18n.s("00:00") }
                                        Item { Layout.fillWidth: true }
                                        Text { font.family: "Michroma"; font.weight: Font.Medium; font.pixelSize: 11; color: window.overlay0; text: I18n.s("06:00") }
                                        Item { Layout.fillWidth: true }
                                        Text { font.family: "Michroma"; font.weight: Font.Medium; font.pixelSize: 11; color: window.overlay0; text: I18n.s("12:00") }
                                        Item { Layout.fillWidth: true }
                                        Text { font.family: "Michroma"; font.weight: Font.Medium; font.pixelSize: 11; color: window.overlay0; text: I18n.s("18:00") }
                                        Item { Layout.fillWidth: true }
                                        Text { font.family: "Michroma"; font.weight: Font.Medium; font.pixelSize: 11; color: window.overlay0; text: I18n.s("23:00") }
                                    }
                                }
                            }
                        }
                    } // End of Daily View Wrapper

                    // ==========================================
                    // WEEK VIEW WRAPPER
                    // ==========================================
                    ColumnLayout {
                        id: weekViewWrapper
                        anchors.fill: parent
                        spacing: 16

                        opacity: window.weekViewFocus
                        visible: opacity > 0
                        transform: Translate { x: 40 * (1 - window.weekViewFocus) }
                        scale: 0.95 + (0.05 * window.weekViewFocus) // Fluid zoom in on activation

                        // ─────────────────────────────────────────
                        // Week Heatmap Card
                        // ─────────────────────────────────────────
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 260
                            radius: 14
                            color: window.base
                            border.color: Qt.alpha(window.surface1, 0.3)
                            border.width: 1

                            opacity: introMidLeft
                            transform: Translate { y: 20 * (1 - introMidLeft) }

                            // Outer ColumnLayout: stacks [heatmap row | x-axis] vertically
                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 6

                                // ── Inner RowLayout: heatmap (left) + stats (right) ──
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 16

                                    // LEFT: 7 day rows of 24 hour cells
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        spacing: 4

                                        Repeater {
                                            model: 7
                                            delegate: RowLayout {
                                                property int dayIndex: index
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                spacing: 8

                                                opacity: introMidLeft
                                                transform: Translate { x: -20 * (1 - introMidLeft) + (dayIndex * 5 * (1 - introMidLeft)) }

                                                Text {
                                                    text: [I18n.s("Monday"), I18n.s("Tuesday"), I18n.s("Wednesday"), I18n.s("Thursday"), I18n.s("Friday"), I18n.s("Saturday"), I18n.s("Sunday")][dayIndex]
                                                    font.family: "Michroma"
                                                    font.weight: Font.Normal
                                                    font.pixelSize: 12
                                                    color: window.subtext0
                                                    Layout.preferredWidth: 75
                                                    verticalAlignment: Text.AlignVCenter
                                                }

                                                // Clip wrapper for rounded edges on the unified continuous bar
                                                Rectangle {
                                                    Layout.fillWidth: true
                                                    Layout.fillHeight: true
                                                    radius: 10
                                                    color: "transparent"
                                                    clip: true

                                                    RowLayout {
                                                        anchors.fill: parent
                                                        spacing: 0

                                                        Repeater {
                                                            model: 24
                                                            delegate: Rectangle {
                                                                Layout.fillWidth: true
                                                                Layout.fillHeight: true
                                                                radius: 0
                                                                
                                                                property real val: (window.weekHeatmapData[dayIndex] && window.weekHeatmapData[dayIndex][index]) ? window.weekHeatmapData[dayIndex][index] : 0
                                                                property real intensity: Math.min(1.0, 0.2 + 0.8 * (val / Math.max(window.maxWeekHour, 1)))
                                                                color: val === 0 ? window.surface0 : Qt.rgba(window.mauve.r, window.mauve.g, window.mauve.b, intensity)

                                                                // Staggered animated popup matrix effect for the heatmap cells
                                                                scale: window.isWeekView ? 1.0 : 0.5
                                                                Behavior on scale {
                                                                    NumberAnimation {
                                                                        duration: 400 + (dayIndex * 30) + (index * 10)
                                                                        easing.type: Easing.OutBack
                                                                    }
                                                                }
                                                                Behavior on color { ColorAnimation { duration: 600; easing.type: Easing.OutQuint } }

                                                                MouseArea {
                                                                    anchors.fill: parent
                                                                    hoverEnabled: true
                                                                    onEntered: parent.opacity = 0.7
                                                                    onExited: parent.opacity = 1.0
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // RIGHT: Daily avg + Peak hours stats column
                                    ColumnLayout {
                                        Layout.preferredWidth: 17
                                        Layout.fillHeight: true
                                        spacing: 12

                                        // Daily Average box
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 10
                                            color: window.surface0

                                            ColumnLayout {
                                                anchors.centerIn: parent
                                                spacing: 4
                                                Text {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    font.family: "Michroma"
                                                    font.weight: Font.Medium
                                                    font.pixelSize: 12
                                                    color: window.subtext0
                                                    text: I18n.s("Daily average")
                                                }
                                                Text {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    font.family: "Michroma"
                                                    font.weight: Font.Bold
                                                    font.pixelSize: 18
                                                    color: window.text
                                                    text: window.formatTimeList(window.averageSeconds)
                                                }
                                            }
                                        }

                                        // Peak Hours box
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            radius: 10
                                            color: window.surface0

                                            ColumnLayout {
                                                anchors.centerIn: parent
                                                spacing: 4
                                                Text {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    font.family: "Michroma"
                                                    font.weight: Font.Medium
                                                    font.pixelSize: 12
                                                    color: window.subtext0
                                                    text: I18n.s("Peak hours")
                                                }
                                                Text {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    font.family: "Michroma"
                                                    font.weight: Font.Bold
                                                    font.pixelSize: 14
                                                    color: window.text
                                                    text: window.peakUsageHours
                                                }
                                            }
                                        }
                                    }
                                }

                                // ── X-axis labels: sit below the heatmap rows, aligned with them ──
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    // Spacer matches the day-name label width above
                                    Item { Layout.preferredWidth: 75 + 8 } // 75 label + 8 spacing

                                    Text { font.family: "Michroma"; font.weight: Font.Medium; font.pixelSize: 11; color: window.overlay0; text: I18n.s("00:00"); Layout.alignment: Qt.AlignLeft }
                                    Item { Layout.fillWidth: true }
                                    Text { font.family: "Michroma"; font.weight: Font.Medium; font.pixelSize: 11; color: window.overlay0; text: I18n.s("06:00"); Layout.alignment: Qt.AlignHCenter }
                                    Item { Layout.fillWidth: true }
                                    Text { font.family: "Michroma"; font.weight: Font.Medium; font.pixelSize: 11; color: window.overlay0; text: I18n.s("12:00"); Layout.alignment: Qt.AlignHCenter }
                                    Item { Layout.fillWidth: true }
                                    Text { font.family: "Michroma"; font.weight: Font.Medium; font.pixelSize: 11; color: window.overlay0; text: I18n.s("18:00"); Layout.alignment: Qt.AlignHCenter }
                                    Item { Layout.fillWidth: true }
                                    Text { font.family: "Michroma"; font.weight: Font.Medium; font.pixelSize: 11; color: window.overlay0; text: I18n.s("23:00"); Layout.alignment: Qt.AlignRight }

                                    // Spacer matches the stats column width above so labels stop there
                                    Item { Layout.preferredWidth: 120 + 32 } // 120 stats col + 16 spacing
                                }
                            }
                        }

                        // Week Top Apps Card
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 14
                            color: window.base
                            border.color: Qt.alpha(window.surface1, 0.3)
                            border.width: 1

                            opacity: introBottom
                            transform: Translate { y: 30 * (1 - introBottom) }

                            ListView {
                                id: weekAppList
                                anchors.fill: parent
                                anchors.margins: 8
                                anchors.topMargin: 12
                                anchors.bottomMargin: 12
                                model: weekAppListModel
                                interactive: true 
                                clip: true        
                                spacing: 2
                                
                                move: Transition { NumberAnimation { properties: "x,y"; duration: 400; easing.type: Easing.OutQuint } }
                                
                                ScrollBar.vertical: ScrollBar {
                                    active: weekAppList.moving || weekAppList.movingVertically
                                    width: 4
                                    policy: ScrollBar.AsNeeded
                                    contentItem: Rectangle { implicitWidth: 4; radius: 2; color: window.surface2 }
                                }
                                
                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 58 
                                    color: "transparent"
                                    radius: 10

                                    opacity: introBottom
                                    transform: Translate { y: (index * 12) * (1 - introBottom) }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 10
                                        color: weekRowMa.containsMouse ? window.surface0 : "transparent"
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }

                                    MouseArea {
                                        id: weekRowMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            window.selectedAppClass = model.appClass;
                                            window.selectedAppName = model.name;
                                            window.selectedAppIcon = model.icon;
                                            window.appDate = new Date(); 
                                            window.isWeekView = false;
                                            window.requestDataUpdate();
                                        }
                                    }

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 16
                                        anchors.rightMargin: 16
                                        anchors.topMargin: 10
                                        anchors.bottomMargin: 10
                                        spacing: 6

                                        RowLayout {
                                            Layout.fillWidth: true
                                            
                                            Image {
                                                visible: model.icon !== ""
                                                source: model.icon.startsWith("/") ? "file://" + model.icon : "image://icon/" + model.icon
                                                sourceSize: Qt.size(20, 20)
                                                Layout.preferredWidth: 20
                                                Layout.preferredHeight: 20
                                                Layout.alignment: Qt.AlignVCenter
                                                Layout.rightMargin: 8
                                                fillMode: Image.PreserveAspectFit
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                font.family: "Michroma"
                                                font.weight: Font.DemiBold
                                                font.pixelSize: 15
                                                color: window.text
                                                text: model.name
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                font.family: "Michroma"
                                                font.weight: Font.Medium
                                                font.pixelSize: 14
                                                color: window.subtext0
                                                text: window.formatTimeList(model.seconds)
                                            }
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                            height: 10
                                            Rectangle { anchors.fill: parent; radius: 5; color: window.crust }
                                            Rectangle {
                                                height: parent.height
                                                width: Math.max(10, parent.width * (model.percent / 100.0) * window.introAppBars)
                                                radius: 5
                                                gradient: Gradient {
                                                    orientation: Gradient.Horizontal
                                                    GradientStop { position: 0.0; color: window.mauve }
                                                    GradientStop { position: 1.0; color: window.blue }
                                                }
                                                Behavior on width { 
                                                    enabled: window.introAppBars === 1.0
                                                    NumberAnimation { duration: 600; easing.type: Easing.OutQuint } 
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } // End Week View Wrapper
                } // End Container Item
            }
        }
    }
}
