import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtCore
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window

    // -------------------------------------------------------------------------
    // KEYBOARD SHORTCUTS
    // (Escape is handled by Main.qml now)
    // -------------------------------------------------------------------------
    Shortcut { 
        sequence: "Left"
        onActivated: {
            if (calHover.hovered) {
                window.setMonthOffset(window.targetMonthOffset - 1);
            } else {
                window.setWeatherView(window.targetWeatherView - 1);
            }
        }
    }

    Shortcut { 
        sequence: "Right"
        onActivated: {
            if (calHover.hovered) {
                window.setMonthOffset(window.targetMonthOffset + 1);
            } else {
                window.setWeatherView(window.targetWeatherView + 1);
            }
        }
    }

  
    // -------------------------------------------------------------------------
    // COLORS (Dynamic Matugen Palette)
    // -------------------------------------------------------------------------
    MatugenColors { id: _theme }
    readonly property color base: _theme.base
    readonly property color mantle: _theme.mantle
    readonly property color crust: _theme.crust
    readonly property color text: _theme.text
    readonly property color subtext1: _theme.subtext1
    readonly property color subtext0: _theme.subtext0
    readonly property color overlay2: _theme.overlay2
    readonly property color overlay1: _theme.overlay1
    readonly property color overlay0: _theme.overlay0
    readonly property color surface2: _theme.surface2
    readonly property color surface1: _theme.surface1
    readonly property color surface0: _theme.surface0
    
    readonly property color mauve: _theme.mauve
    readonly property color pink: _theme.pink
    readonly property color blue: _theme.blue
    readonly property color sapphire: _theme.sapphire
    readonly property color peach: _theme.peach
    readonly property color yellow: _theme.yellow
    readonly property color teal: _theme.teal
    readonly property color green: _theme.green
    readonly property color red: _theme.red

    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/calendar"

    // -------------------------------------------------------------------------
    // TIME OF DAY DYNAMIC COLORS
    // -------------------------------------------------------------------------
    readonly property color timeColor: {
        let h = window.currentTime.getHours();
        if (h >= 5 && h < 12) return window.peach;      // Morning
        if (h >= 12 && h < 17) return window.sapphire;  // Afternoon
        if (h >= 17 && h < 21) return window.mauve;     // Evening
        return window.blue;                             // Night
    }

    readonly property color timeAccent: {
        let h = window.currentTime.getHours();
        if (h >= 5 && h < 12) return window.yellow;     // Morning Accent
        if (h >= 12 && h < 17) return window.teal;      // Afternoon Accent
        if (h >= 17 && h < 21) return window.pink;      // Evening Accent
        return window.mauve;                            // Night Accent
    }

    readonly property color textAccent: Qt.tint(window.timeAccent, Qt.alpha(window.text, 0.35))

    // -------------------------------------------------------------------------
    // STARTUP ANIMATION STATES
    // -------------------------------------------------------------------------
    property bool startupComplete: false
    property real introMain: 0
    property real introAmbient: 0
    property real introClock: 0
    property real introCalendar: 0
    property real introWeather: 0

    SequentialAnimation {
        running: true
        
        // 50ms buffer to allow the window manager to map the surface before animating
        PauseAnimation { duration: 20 }

        ParallelAnimation {
            // Base window fades and scales slightly
            NumberAnimation { target: window; property: "introMain"; from: 0; to: 1.0; duration: 800; easing.type: Easing.OutQuart }

            // Ambient background glows and big parallax icon fade in
            SequentialAnimation {
                PauseAnimation { duration: 150 }
                NumberAnimation { target: window; property: "introAmbient"; from: 0; to: 1.0; duration: 1000; easing.type: Easing.OutSine }
            }

            // Central clock and 3D orbital pop from the center
            SequentialAnimation {
                PauseAnimation { duration: 250 }
                NumberAnimation { target: window; property: "introClock"; from: 0; to: 1.0; duration: 900; easing.type: Easing.OutBack; easing.overshoot: 1.15 }
            }

            // Left wing (Calendar) slides in from the left
            SequentialAnimation {
                PauseAnimation { duration: 350 }
                NumberAnimation { target: window; property: "introCalendar"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutQuint }
            }

            // Right wing (Weather) slides in from the right
            SequentialAnimation {
                PauseAnimation { duration: 400 }
                NumberAnimation { target: window; property: "introWeather"; from: 0; to: 1.0; duration: 850; easing.type: Easing.OutQuint }
            }
        }
        ScriptAction { script: window.startupComplete = true }
    }

    ParallelAnimation {
        id: exitAnim
        NumberAnimation { target: window; property: "introMain"; to: 0; duration: 400; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introAmbient"; to: 0; duration: 250; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introClock"; to: 0; duration: 300; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introCalendar"; to: 0; duration: 350; easing.type: Easing.InQuart }
        NumberAnimation { target: window; property: "introWeather"; to: 0; duration: 350; easing.type: Easing.InQuart }
    }

    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0; to: Math.PI * 2; duration: 90000; loops: Animation.Infinite; running: true
    }

    // -------------------------------------------------------------------------
    // STATE & TIME (WITH SECOND PULSE)
    // -------------------------------------------------------------------------
    property var currentTime: new Date()
    property real currentEpoch: currentTime.getTime() / 1000
    
    property real secondPulse: 1.0
    NumberAnimation on secondPulse { 
        id: pulseReset 
        to: 1.0; duration: 600; easing.type: Easing.OutQuint; running: false 
    }

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            window.currentTime = new Date();
            window.secondPulse = 1.06; // Gentle pulse
            pulseReset.start();        
            
            if (window.currentTime.getHours() === 0 && window.currentTime.getMinutes() === 0 && window.currentTime.getSeconds() === 0) {
                updateCalendarGrid();
            }
        }
    }

    // -------------------------------------------------------------------------
    // WEATHER DATA & ELEGANT TRANSITIONS (3D ORBIT SPIN)
    // -------------------------------------------------------------------------
    property var weatherData: null
    property int weatherView: 0
    property color activeWeatherHex: weatherData && weatherData.forecast && weatherData.forecast[weatherView] ? weatherData.forecast[weatherView].hex : window.mauve
    property bool showWeatherSettings: false
    property string weatherApiKey: ""
    property string weatherCityId: ""
    property string weatherUnit: "metric"
    property string weatherSettingsStatus: ""
    property color weatherSettingsStatusColor: window.subtext0

    // Transition Properties
    property int targetWeatherView: 0
    property real weatherContentOpacity: 1.0
    property real weatherContentOffset: 0.0
    property int weatherAnimDirection: 1
    
    // New 3D Spin Properties
    property real transitionSpin: 0.0
    property real transitionScale: 1.0

    // -------------------------------------------------------------------------
    // TEMPERATURE LOGIC 
    // -------------------------------------------------------------------------
    property real targetTemp: window.weatherData && window.weatherData.forecast[window.targetWeatherView] ? Number(window.weatherData.forecast[window.targetWeatherView].max) : 0
    property real displayedTemp: targetTemp

    Behavior on displayedTemp {
        NumberAnimation {
            id: tempAnim
            duration: 800
            easing.type: Easing.OutQuart
        }
    }

    property bool isTempAnimating: tempAnim.running
    property color tempGlowColor: {
        if (!isTempAnimating || !window.startupComplete) return window.text;
        
        // If the target is higher than the currently ticking number, we are counting up
        if (window.targetTemp > window.displayedTemp) return window.red;
        
        // If the target is lower than the currently ticking number, we are counting down
        if (window.targetTemp < window.displayedTemp) return window.blue;
        
        return window.text; 
    }
    SequentialAnimation {
        id: weatherTransitionAnim
        ParallelAnimation {
            NumberAnimation { target: window; property: "weatherContentOpacity"; to: 0.0; duration: 250; easing.type: Easing.InSine }
            NumberAnimation { target: window; property: "weatherContentOffset"; to: -40 * weatherAnimDirection; duration: 250; easing.type: Easing.InSine }
            
            // Spin the 3D orbit out and scale it down for depth
            NumberAnimation { target: window; property: "transitionSpin"; to: 180 * weatherAnimDirection; duration: 300; easing.type: Easing.InBack }
            NumberAnimation { target: window; property: "transitionScale"; to: 0.8; duration: 300; easing.type: Easing.InCubic }
        }
        ScriptAction { 
            script: { 
                window.weatherView = window.targetWeatherView; 
                window.weatherContentOffset = 40 * weatherAnimDirection; // Move to opposite side while hidden
                
                // Reset the spin to the opposite side so it continues spinning into place seamlessly
                window.transitionSpin = -180 * weatherAnimDirection;
            } 
        }
        ParallelAnimation {
            NumberAnimation { target: window; property: "weatherContentOpacity"; to: 1.0; duration: 450; easing.type: Easing.OutQuart }
            NumberAnimation { target: window; property: "weatherContentOffset"; to: 0.0; duration: 450; easing.type: Easing.OutQuart }
            
            // Snap the 3D orbit back to 0 degrees and restore full scale
            NumberAnimation { target: window; property: "transitionSpin"; to: 0.0; duration: 600; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
            NumberAnimation { target: window; property: "transitionScale"; to: 1.0; duration: 500; easing.type: Easing.OutBack }
        }
    }

    function setWeatherView(idx) {
        if (idx < 0 || idx > 4 || !window.weatherData) return;
        if (idx === window.targetWeatherView) return; // Ignore if we are already heading there

        // If an animation is already running, gracefully interrupt it and apply the logical switch
        // before starting the new animation so the data doesn't get desynced.
        if (weatherTransitionAnim.running) {
            weatherTransitionAnim.stop();
            window.weatherView = window.targetWeatherView;
        }

        window.weatherAnimDirection = idx > window.weatherView ? 1 : -1;
        window.targetWeatherView = idx;
        weatherTransitionAnim.start();
    }

    property int activeHourIndex: {
        if (window.weatherView !== 0 || !window.weatherData || !window.weatherData.forecast || !window.weatherData.forecast[0] || !window.weatherData.forecast[0].hourly) return -1;
        
        let ch = window.currentTime.getHours();
        let hrArr = window.weatherData.forecast[0].hourly.slice(0, 8);
        let bestIdx = -1;
        let minDiff = 999;
        
        for (let i = 0; i < hrArr.length; i++) {
            let timeStr = hrArr[i].time || "00:00";
            let h = parseInt(timeStr.split(":")[0]);
            let diff = Math.abs(h - ch);
            if (diff < minDiff) {
                minDiff = diff;
                bestIdx = i;
            }
        }
        return bestIdx !== -1 ? bestIdx : 0;
    }

    Process {
        id: weatherPoller
        command: ["bash", window.scriptsDir + "/weather.sh", "--json"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try { window.weatherData = JSON.parse(txt); } catch(e) {}
                }
            }
        }
    }

    Process {
        id: weatherConfigPoller
        command: ["bash", window.scriptsDir + "/weather.sh", "--get-config"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    let cfg = JSON.parse(data)
                    window.weatherApiKey = cfg.key || ""
                    window.weatherCityId = cfg.city_id || ""
                    window.weatherUnit = cfg.unit || "metric"
                } catch (e) {}
            }
        }
    }

    Process {
        id: weatherConfigSaver
        command: [
            "bash",
            window.scriptsDir + "/weather.sh",
            "--set-config",
            window.weatherApiKey,
            window.weatherCityId,
            window.weatherUnit
        ]
        stdout: SplitParser {
            onRead: data => {
                let txt = data.trim()
                if (txt.length === 0) {
                    return
                }
                try {
                    let res = JSON.parse(txt)
                    if (res.ok) {
                        window.weatherSettingsStatus = "Saved. Refreshing weather..."
                        window.weatherSettingsStatusColor = window.green
                        weatherForcePoller.running = true
                        saveCloseTimer.start()
                    } else {
                        window.weatherSettingsStatus = res.message || "Invalid API key or city id"
                        window.weatherSettingsStatusColor = window.red
                    }
                } catch (e) {
                    window.weatherSettingsStatus = "Validation failed"
                    window.weatherSettingsStatusColor = window.red
                }
            }
        }
    }

    Timer {
        id: saveCloseTimer
        interval: 900
        repeat: false
        onTriggered: {
            window.showWeatherSettings = false
            window.weatherSettingsStatus = ""
        }
    }

    Process {
        id: weatherForcePoller
        command: ["bash", window.scriptsDir + "/weather.sh", "--refresh"]
        stdout: SplitParser {
            onRead: data => {
                let txt = data.trim()
                if (txt.length > 10) {
                    try { window.weatherData = JSON.parse(txt) } catch (e) {}
                }
            }
        }
    }

    Timer {
        interval: 150000 
        running: true; repeat: true
        onTriggered: weatherPoller.running = true
    }

    // -------------------------------------------------------------------------
    // CALENDAR GRID LOGIC & TRANSITIONS
    // -------------------------------------------------------------------------
    property int monthOffset: 0
    property int targetMonthOffset: 0
    property string targetMonthName: ""
    ListModel { id: calendarModel }

    property real calendarContentOpacity: 1.0
    property real calendarContentOffset: 0.0
    property int calendarAnimDirection: 1

    SequentialAnimation {
        id: calendarTransitionAnim
        ParallelAnimation {
            NumberAnimation { target: window; property: "calendarContentOpacity"; to: 0.0; duration: 200; easing.type: Easing.InSine }
            NumberAnimation { target: window; property: "calendarContentOffset"; to: -20 * calendarAnimDirection; duration: 200; easing.type: Easing.InSine }
        }
        ScriptAction {
            script: {
                window.monthOffset = window.targetMonthOffset;
                window.calendarContentOffset = 20 * calendarAnimDirection;
            }
        }
        ParallelAnimation {
            NumberAnimation { target: window; property: "calendarContentOpacity"; to: 1.0; duration: 350; easing.type: Easing.OutQuart }
            NumberAnimation { target: window; property: "calendarContentOffset"; to: 0.0; duration: 350; easing.type: Easing.OutQuart }
        }
    }

    function setMonthOffset(newOffset) {
        if (newOffset === window.targetMonthOffset) return;

        if (calendarTransitionAnim.running) {
            calendarTransitionAnim.stop();
            window.monthOffset = window.targetMonthOffset;
        }

        window.calendarAnimDirection = newOffset > window.targetMonthOffset ? 1 : -1;
        window.targetMonthOffset = newOffset;
        calendarTransitionAnim.start();
    }

    function updateCalendarGrid() {
        let d = new Date(window.currentTime.getTime());
        d.setDate(1); 
        d.setMonth(d.getMonth() + window.monthOffset);

        let targetMonth = d.getMonth();
        let targetYear = d.getFullYear();
        
        let actualToday = new Date();
        let isRealCurrentMonth = (actualToday.getMonth() === targetMonth && actualToday.getFullYear() === targetYear);
        let todayDate = actualToday.getDate();

        window.targetMonthName = Qt.formatDateTime(d, "MMMM yyyy");

        let firstDay = new Date(targetYear, targetMonth, 1).getDay();
        firstDay = (firstDay === 0) ? 6 : firstDay - 1; 

        let daysInMonth = new Date(targetYear, targetMonth + 1, 0).getDate();
        let daysInPrevMonth = new Date(targetYear, targetMonth, 0).getDate();

        calendarModel.clear();

        for (let i = firstDay - 1; i >= 0; i--) {
            calendarModel.append({ dayNum: (daysInPrevMonth - i).toString(), isCurrentMonth: false, isToday: false });
        }
        for (let i = 1; i <= daysInMonth; i++) {
            calendarModel.append({ dayNum: i.toString(), isCurrentMonth: true, isToday: (isRealCurrentMonth && i === todayDate) });
        }
        let remaining = 42 - calendarModel.count;
        for (let i = 1; i <= remaining; i++) {
            calendarModel.append({ dayNum: i.toString(), isCurrentMonth: false, isToday: false });
        }
    }

    onMonthOffsetChanged: updateCalendarGrid()

    Component.onCompleted: {
        updateCalendarGrid();
    }

    // -------------------------------------------------------------------------
    // UI LAYOUT
    // -------------------------------------------------------------------------
    Item {
        anchors.fill: parent
        scale: 0.95 + (0.05 * introMain)
        opacity: introMain

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: window.base
            border.color: window.surface0
            border.width: 1
            clip: true

            // =======================================================
            // AMBIENT WIDGET COLOR BLOBS (Spread Out)
            // =======================================================
            Rectangle {
                width: parent.width * 0.5; height: width; radius: width / 2
                x: (parent.width * 0.75 - width / 2) + Math.cos(window.globalOrbitAngle * 1.5) * 350
                y: (parent.height * 0.3 - height / 2) + Math.sin(window.globalOrbitAngle * 1.5) * 200
                opacity: 0.025 * window.introAmbient
                color: window.activeWeatherHex
                Behavior on color { ColorAnimation { duration: 1000 } }
            }

            Rectangle {
                width: parent.width * 0.6; height: width; radius: width / 2
                x: (parent.width * 0.25 - width / 2) + Math.sin(window.globalOrbitAngle * 1.2) * -300
                y: (parent.height * 0.7 - height / 2) + Math.cos(window.globalOrbitAngle * 1.2) * -250
                opacity: 0.02 * window.introAmbient
                color: window.timeColor
                Behavior on color { ColorAnimation { duration: 1000 } }
            }

            Rectangle {
                width: parent.width * 0.45; height: width; radius: width / 2
                x: (parent.width * 0.5 - width / 2) + Math.cos(window.globalOrbitAngle * -1.8) * 400
                y: (parent.height * 0.5 - height / 2) + Math.sin(window.globalOrbitAngle * -1.8) * -350
                opacity: 0.015 * window.introAmbient
                color: window.timeAccent
                Behavior on color { ColorAnimation { duration: 1000 } }
            }

            // Big Parallax Weather Icon (Tied to Weather Transition)
            Text {
                anchors.centerIn: parent
                text: window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].icon : ""
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 800
                color: window.activeWeatherHex
                opacity: (0.03 + (0.01 * Math.sin(window.globalOrbitAngle * 4))) * window.introAmbient * window.weatherContentOpacity
                z: 0
                Behavior on color { ColorAnimation { duration: 1500 } }
                
                property real drift: 0
                SequentialAnimation on drift {
                    loops: Animation.Infinite
                    NumberAnimation { to: -20; duration: 6000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0; duration: 6000; easing.type: Easing.InOutSine }
                }
                
                transform: [
                    Translate { y: parent.drift },
                    Translate { x: window.weatherContentOffset * 2 } // Exaggerated shift for background depth
                ]
            }

            // =======================================================
            // CENTRAL HERO: THE BREATHING TIME HUB & 3D HOURLY ORBIT
            // =======================================================
            Item {
                id: centralHub
                anchors.centerIn: parent
                width: 1; height: 1 
                z: 5

                opacity: introClock
                scale: 0.85 + (0.15 * introClock)

                property real levitation: 0
                SequentialAnimation on levitation {
                    loops: Animation.Infinite
                    NumberAnimation { to: -15; duration: 4000; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0; duration: 4000; easing.type: Easing.InOutSine }
                }

                property real orbitBreath: 1.0
                SequentialAnimation on orbitBreath {
                    loops: Animation.Infinite
                    running: true
                    NumberAnimation { to: 1.035; duration: 3500; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 3500; easing.type: Easing.InOutSine }
                }

                // 3D Perspective Wobble (Pitch, Yaw, Roll)
                property real pitchBreath: 0
                SequentialAnimation on pitchBreath {
                    loops: Animation.Infinite; running: true
                    NumberAnimation { to: 3.5; duration: 4200; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -3.5; duration: 4200; easing.type: Easing.InOutSine }
                }

                property real yawBreath: 0
                SequentialAnimation on yawBreath {
                    loops: Animation.Infinite; running: true
                    NumberAnimation { to: 2.5; duration: 5100; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -2.5; duration: 5100; easing.type: Easing.InOutSine }
                }

                property real rollBreath: 0
                SequentialAnimation on rollBreath {
                    loops: Animation.Infinite; running: true
                    NumberAnimation { to: 1.5; duration: 5800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: -1.5; duration: 5800; easing.type: Easing.InOutSine }
                }
                
                transform: [
                    Translate { y: 25 * (1.0 - introClock) },
                    Translate { y: centralHub.levitation },
                    Rotation { axis { x: 1; y: 0; z: 0 } angle: centralHub.pitchBreath },
                    Rotation { axis { x: 0; y: 1; z: 0 } angle: centralHub.yawBreath },
                    Rotation { axis { x: 0; y: 0; z: 1 } angle: centralHub.rollBreath }
                ]

                Canvas {
                    z: -10
                    x: -400   // Widened to prevent clipping when scaled
                    y: -200   // Heightened to prevent clipping when scaled
                    width: 800
                    height: 400
                    opacity: 0.25

                    property real currentScale: centralHub.orbitBreath
                    onCurrentScaleChanged: requestPaint()

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.beginPath();
                        var currentRx = 320 * currentScale;
                        var currentRy = 140 * currentScale;
                        for (var i = 0; i <= Math.PI * 2; i += 0.05) {
                            var xx = width/2 + Math.cos(i) * currentRx;
                            var yy = height/2 + Math.sin(i) * currentRy;
                            if (i === 0) ctx.moveTo(xx, yy); else ctx.lineTo(xx, yy);
                        }
                        ctx.strokeStyle = window.textAccent;
                        ctx.lineWidth = 1.5;
                        ctx.setLineDash([4, 10]);
                        ctx.stroke();
                    }
                    Behavior on opacity { NumberAnimation { duration: 1500 } }
                }

                // Core Clock
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0
                    z: 0 
                    scale: 0.95 + (0.05 * window.secondPulse) 
                    
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 2
                        Text {
                            text: Qt.formatTime(window.currentTime, "HH:mm")
                            font.family: "Michroma"
                            font.weight: Font.Black
                            font.pixelSize: 84
                            color: window.text
                            style: Text.Outline; styleColor: Qt.alpha(window.crust, 0.4)
                        }
                        Text {
                            text: Qt.formatTime(window.currentTime, ":ss")
                            font.family: "Michroma"
                            font.weight: Font.Bold
                            font.pixelSize: 32
                            color: window.textAccent
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 15
                            opacity: window.secondPulse > 1.02 ? 1.0 : 0.6 
                            style: Text.Outline; styleColor: Qt.alpha(window.crust, 0.4)
                            Behavior on color { ColorAnimation { duration: 1000 } }
                        }
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDateTime(window.currentTime, "dddd, MMMM dd")
                        font.family: "Michroma"
                        font.weight: Font.Bold
                        font.pixelSize: 16
                        color: window.subtext0
                        opacity: 0.9
                    }
                }

                // TRUE 3D ORBITAL HOURLY FORECAST (Tied to Spin Transition)
                Item {
                    anchors.fill: parent
                    opacity: window.weatherContentOpacity
                    
                    // Added Scale property to give a z-depth shrink effect when spinning
                    scale: window.transitionScale 
                    transform: Translate { x: window.weatherContentOffset * 1.5 }

                    Repeater {
                        id: hourRepeater
                        model: window.weatherData && window.weatherData.forecast[window.weatherView] && window.weatherData.forecast[window.weatherView].hourly ? window.weatherData.forecast[window.weatherView].hourly.slice(0, 8) : []
                        
                        delegate: Item {
                            property int mCount: hourRepeater.count
                            property bool isToday: window.weatherView === 0
                            property bool isHighlighted: isToday && index === window.activeHourIndex
                            
                            property real rx: 320 * centralHub.orbitBreath
                            property real ry: 140 * centralHub.orbitBreath
                            
                            property int relIdx: isToday ? (index - window.activeHourIndex) : index
                            
                            property real targetAngleDeg: isToday ? (65 + (relIdx * 30)) : (index * (360 / Math.max(1, mCount)))
                            
                            property real orbitOffset: isToday ? 0 : (window.globalOrbitAngle * (180 / Math.PI) * -1.5)
                            property real osc: isToday ? (Math.sin(window.globalOrbitAngle * 10 + index) * 5) : 0 
                            
                            // Integrated window.transitionSpin directly into the final angle calculation
                            property real rad: (targetAngleDeg + orbitOffset + osc + window.transitionSpin) * (Math.PI / 180)

                            x: Math.cos(rad) * rx - width/2
                            y: Math.sin(rad) * ry - height/2
                            z: Math.sin(rad) * 100 
                            
                            scale: isHighlighted ? 1.4 : (isToday ? (0.95 + 0.20 * Math.sin(rad)) : (0.90 + 0.25 * Math.sin(rad)))
                            opacity: isHighlighted ? 1.0 : (isToday ? (0.7 + 0.3 * ((Math.sin(rad) + 1) / 2)) : (0.65 + 0.35 * ((Math.sin(rad) + 1) / 2)))

                            width: 56; height: 95
                            
                            Rectangle {
                                anchors.fill: parent
                                radius: 28
                                color: isHighlighted ? window.textAccent : (hrMa.containsMouse ? window.surface2 : window.surface0)
                                border.color: isHighlighted ? "transparent" : (hrMa.containsMouse ? window.textAccent : window.surface1)
                                border.width: 1
                                
                                Behavior on color { ColorAnimation { duration: 200 } }
                                
                                ColumnLayout {
                                    anchors.centerIn: parent 
                                    spacing: 4
                                    
                                    Text { 
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.time
                                        font.family: "Michroma"; font.weight: Font.Bold; font.pixelSize: 12
                                        color: isHighlighted ? window.base : (hrMa.containsMouse ? window.text : window.overlay1)
                                    }
                                    
                                    Text { 
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.icon || (window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].icon : "")
                                        font.family: "Iosevka Nerd Font"; font.pixelSize: 18
                                        color: isHighlighted ? window.base : (modelData.hex || window.text)
                                        
                                        transform: Translate { y: hrMa.containsMouse ? -3 : 0 }
                                        Behavior on transform { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                                    }
                                    
                                    Text { 
                                        Layout.alignment: Qt.AlignHCenter; text: modelData.temp + "°"
                                        font.family: "Iosevka Nerd Font"; font.weight: Font.Black; font.pixelSize: 14
                                        color: isHighlighted ? window.base : window.text 
                                    }
                                }
                            }
                            MouseArea { id: hrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                        }
                    }
                }
            }

            // =======================================================
            // LEFT WING: FLOATING GLASS CALENDAR
            // =======================================================
            Rectangle {
                id: calendarRect
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 40
                width: 320
                height: 420
                color: Qt.alpha(window.surface0, 0.2) 
                radius: 14
                border.color: Qt.alpha(window.surface1, 0.4)
                border.width: 1
                z: 10 

                opacity: introCalendar
                transform: Translate { x: -40 * (1.0 - introCalendar) }

                HoverHandler { id: calHover }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 25
                    spacing: 15

                    RowLayout {
                        Layout.fillWidth: true
                        
                        // "Return to Today" Home Button
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: homeMa.containsMouse ? window.surface1 : "transparent"
                            opacity: window.targetMonthOffset !== 0 ? 1.0 : 0.0
                            visible: opacity > 0
                            Behavior on opacity { NumberAnimation { duration: 200 } }
                            Text { anchors.centerIn: parent; text: "󰃭"; font.family: "Iosevka Nerd Font"; color: window.text; font.pixelSize: 16 }
                            MouseArea { 
                                id: homeMa; anchors.fill: parent; hoverEnabled: window.targetMonthOffset !== 0; 
                                onClicked: if (window.targetMonthOffset !== 0) window.setMonthOffset(0) 
                            }
                        }

                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: prevMa.containsMouse ? window.surface1 : "transparent"
                            Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; color: window.text; font.pixelSize: 16 }
                            MouseArea { id: prevMa; anchors.fill: parent; hoverEnabled: true; onClicked: window.setMonthOffset(window.targetMonthOffset - 1) }
                        }
                        
                        Text {
                            Layout.fillWidth: true
                            text: window.targetMonthName.toUpperCase()
                            font.family: "Michroma"
                            font.weight: Font.Black
                            font.pixelSize: 16
                            color: window.text
                            horizontalAlignment: Text.AlignHCenter
                            
                            opacity: window.calendarContentOpacity
                            transform: Translate { x: window.calendarContentOffset }
                        }

                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: nextMa.containsMouse ? window.surface1 : "transparent"
                            Text { anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; color: window.text; font.pixelSize: 16 }
                            MouseArea { id: nextMa; anchors.fill: parent; hoverEnabled: true; onClicked: window.setMonthOffset(window.targetMonthOffset + 1) }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Repeater {
                            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                            Text {
                                Layout.fillWidth: true
                                text: modelData
                                font.family: "Michroma"
                                font.weight: Font.Black
                                font.pixelSize: 14
                                color: window.overlay0
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 7
                        rowSpacing: 6
                        columnSpacing: 6

                        opacity: window.calendarContentOpacity
                        transform: Translate { x: window.calendarContentOffset }

                        Repeater {
                            model: calendarModel
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                
                                color: isToday ? window.textAccent : (dayMa.containsMouse ? Qt.alpha(window.surface2, 0.4) : "transparent")
                                radius: 10
                                scale: dayMa.containsMouse ? 1.2 : 1.0
                                border.color: isToday ? window.surface0 : (dayMa.containsMouse ? window.overlay0 : "transparent")
                                border.width: isToday || dayMa.containsMouse ? 1 : 0
                                
                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                                Text {
                                    anchors.centerIn: parent
                                    text: dayNum
                                    font.family: "Michroma"
                                    font.weight: isToday ? Font.Black : Font.Bold
                                    font.pixelSize: 14
                                    color: isToday ? window.base : (isCurrentMonth ? window.text : window.surface0)
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }

                                MouseArea { id: dayMa; anchors.fill: parent; hoverEnabled: true }
                            }
                        }
                    }
                }
            }

            // =======================================================
            // RIGHT WING: ORGANIC FLOATING WEATHER STATS
            // =======================================================
            Item {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 40
                width: 320
                height: 420
                z: 10 

                opacity: introWeather
                transform: Translate { x: 40 * (1.0 - introWeather) }

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    RowLayout {
                        Layout.alignment: Qt.AlignRight | Qt.AlignTop
                        spacing: 20
                        
                        MouseArea { 
                            id: wPrevMa; width: 30; height: 30; hoverEnabled: true
                            onClicked: window.setWeatherView(window.targetWeatherView - 1) 
                            
                            property real pulseOffset: 0
                            SequentialAnimation on pulseOffset {
                                loops: Animation.Infinite; running: true
                                NumberAnimation { to: -3; duration: 1000; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 0; duration: 1000; easing.type: Easing.InOutSine }
                            }
                            
                            Text { 
                                anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: 18
                                color: parent.containsMouse ? window.textAccent : window.overlay1
                                transform: Translate { x: parent.containsMouse ? -5 : wPrevMa.pulseOffset }
                                Behavior on transform { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            }
                        }
                        
                        Text {
                            Layout.preferredWidth: 110 // Fixed width so the buttons don't jump around
                            horizontalAlignment: Text.AlignHCenter // Keeps the day name centered between the buttons
                            text: window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].day_full.toUpperCase() : "LOADING..."
                            font.family: "Michroma"
                            font.weight: Font.Black
                            font.pixelSize: 16
                            color: window.text
                        }
                        
                        MouseArea { 
                            id: wNextMa; width: 30; height: 30; hoverEnabled: true
                            onClicked: window.setWeatherView(window.targetWeatherView + 1)
                            
                            property real pulseOffset: 0
                            SequentialAnimation on pulseOffset {
                                loops: Animation.Infinite; running: true
                                NumberAnimation { to: 3; duration: 1000; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 0; duration: 1000; easing.type: Easing.InOutSine }
                            }
                            
                            Text { 
                                anchors.centerIn: parent; text: ""; font.family: "Iosevka Nerd Font"; font.pixelSize: 18
                                color: parent.containsMouse ? window.textAccent : window.overlay1
                                transform: Translate { x: parent.containsMouse ? 5 : wNextMa.pulseOffset }
                                Behavior on transform { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.alignment: Qt.AlignRight 
                        spacing: -5
                        
                        // BIG TEMPERATURE TEXT - Anchored so it doesn't slide with the wrapper
                        Text {
                            Layout.alignment: Qt.AlignHCenter 
                            text: Math.round(window.displayedTemp) + "°"
                            font.family: "Iosevka Nerd Font"
                            font.weight: Font.Black
                            font.pixelSize: 84
                            color: window.tempGlowColor
                            style: Text.Outline; 
                            styleColor: window.isTempAnimating ? Qt.alpha(window.tempGlowColor, 0.5) : Qt.alpha(window.crust, 0.4)
                            
                            Behavior on color { ColorAnimation { duration: 300 } }
                            Behavior on styleColor { ColorAnimation { duration: 300 } }
                        }
                        
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].desc : ""
                            font.family: "Michroma"
                            font.weight: Font.Bold
                            font.pixelSize: 16
                            color: window.textAccent
                            Behavior on color { ColorAnimation { duration: 1000 } }
                            
                            opacity: window.weatherContentOpacity
                            transform: Translate { x: window.weatherContentOffset }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: window.weatherData && window.weatherData.forecast && window.weatherData.forecast[window.weatherView] && window.weatherData.forecast[window.weatherView].desc === "No API Key"
                            onClicked: {
                                weatherConfigPoller.running = true
                                window.weatherSettingsStatus = ""
                                window.showWeatherSettings = true
                            }
                        }
                    }

                    Item { Layout.fillHeight: true } 

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight
                        Layout.rightMargin: 10
                        spacing: 20

                        Repeater {
                            model: 4

                            Item {
                                width: 68
                                height: 100
                                scale: gaugeMa.containsMouse ? 1.15 : 1.0
                                Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }

                                property var forecast: window.weatherData && window.weatherData.forecast[window.targetWeatherView] ? window.weatherData.forecast[window.targetWeatherView] : null

                                property string gaugeIcon: index === 0 ? "" : index === 1 ? "" : index === 2 ? "" : ""
                                property string gaugeLbl: index === 0 ? "WIND" : index === 1 ? "HUMID" : index === 2 ? "RAIN" : "FEELS"

                                property string gaugeVal: forecast ? (
                                    index === 0 ? forecast.wind + "m/s" :
                                    index === 1 ? forecast.humidity + "%" :
                                    index === 2 ? forecast.pop + "%" :
                                    forecast.feels_like + "°"
                                ) : ""

                                property real gaugeFill: forecast ? (
                                    index === 0 ? Math.min(1.0, forecast.wind / 25.0) :
                                    index === 1 ? forecast.humidity / 100.0 :
                                    index === 2 ? forecast.pop / 100.0 :
                                    Math.max(0.0, Math.min(1.0, (forecast.feels_like + 15) / 55.0))
                                ) : 0.0
                                
                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 68; height: 68; radius: 34
                                    color: window.textAccent
                                    opacity: gaugeMa.containsMouse ? 0.3 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 200 } }
                                }

                                Item {
                                    id: circleItem
                                    width: 68; height: 68
                                    anchors.top: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    
                                    Canvas {
                                        id: gaugeCanvas
                                        anchors.fill: parent
                                        rotation: -90 
                                        
                                        property real animProgress: parent.parent.gaugeFill
                                        
                                        Behavior on animProgress {
                                            NumberAnimation { duration: 1000; easing.type: Easing.OutExpo }
                                        }
                                        
                                        onAnimProgressChanged: requestPaint()
                                        
                                        onPaint: {
                                            var ctx = getContext("2d");
                                            ctx.clearRect(0, 0, width, height);
                                            var r = width / 2;
                                            
                                            ctx.beginPath();
                                            ctx.arc(r, r, r - 4, 0, 2 * Math.PI);
                                            ctx.strokeStyle = Qt.alpha(window.text, 0.1);
                                            ctx.lineWidth = 3;
                                            ctx.stroke();
                                            
                                            if (animProgress > 0) {
                                                ctx.beginPath();
                                                ctx.arc(r, r, r - 4, 0, animProgress * 2 * Math.PI);
                                                var grad = ctx.createLinearGradient(0, 0, width, height);
                                                grad.addColorStop(0, window.timeAccent);
                                                grad.addColorStop(1, window.sapphire);
                                                ctx.strokeStyle = grad;
                                                ctx.lineWidth = 4;
                                                ctx.lineCap = "round";
                                                ctx.stroke();
                                            }
                                        }
                                    }
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: parent.parent.gaugeVal
                                        font.family: "Michroma"
                                        font.weight: Font.Black
                                        font.pixelSize: 14
                                        color: window.text
                                    }
                                }
                                
                                RowLayout {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 4
                                    
                                    Text { 
                                        text: parent.parent.gaugeIcon
                                        font.family: "Iosevka Nerd Font"
                                        font.pixelSize: 14
                                        color: gaugeMa.containsMouse ? window.textAccent : window.overlay0
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                    Text { 
                                        text: parent.parent.gaugeLbl
                                        font.family: "Michroma"
                                        font.weight: Font.Bold
                                        font.pixelSize: 12
                                        color: window.overlay0 
                                    }
                                }
                                
                                MouseArea { id: gaugeMa; anchors.fill: parent; hoverEnabled: true }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 26
            color: Qt.rgba(window.crust.r, window.crust.g, window.crust.b, 0.88)
            border.width: 1
            border.color: Qt.rgba(window.surface2.r, window.surface2.g, window.surface2.b, 0.9)
            visible: window.showWeatherSettings
            opacity: window.showWeatherSettings ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            ColumnLayout {
                anchors.centerIn: parent
                width: 520
                spacing: 12

                Text {
                    text: "Weather API Setup"
                    font.family: "Michroma"
                    font.pixelSize: 20
                    font.weight: Font.Black
                    color: window.text
                }

                Text {
                    text: "OpenWeatherMap API Key"
                    font.family: "Michroma"
                    font.pixelSize: 11
                    color: window.subtext0
                }
                TextField {
                    id: apiKeyField
                    Layout.fillWidth: true
                    text: window.weatherApiKey
                    placeholderText: "Paste your API key"
                    onTextChanged: window.weatherApiKey = text
                }

                Text {
                    text: "City ID"
                    font.family: "Michroma"
                    font.pixelSize: 11
                    color: window.subtext0
                }
                TextField {
                    id: cityIdField
                    Layout.fillWidth: true
                    text: window.weatherCityId
                    placeholderText: "Example: 2643743"
                    onTextChanged: window.weatherCityId = text
                }

                RowLayout {
                    spacing: 10
                    Text {
                        text: "Units"
                        font.family: "Michroma"
                        font.pixelSize: 11
                        color: window.subtext0
                    }
                    ComboBox {
                        id: unitBox
                        model: ["metric", "imperial"]
                        currentIndex: window.weatherUnit === "imperial" ? 1 : 0
                        onCurrentTextChanged: window.weatherUnit = currentText
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        height: 42
                        radius: 10
                        color: Qt.rgba(window.surface0.r, window.surface0.g, window.surface0.b, 0.9)
                        border.width: 1
                        border.color: window.surface2
                        Text {
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.family: "Michroma"
                            font.pixelSize: 12
                            color: window.text
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: window.showWeatherSettings = false
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 42
                        radius: 10
                        color: Qt.rgba(window.blue.r, window.blue.g, window.blue.b, 0.85)
                        Text {
                            anchors.centerIn: parent
                            text: "Save"
                            font.family: "Michroma"
                            font.pixelSize: 12
                            font.weight: Font.Black
                            color: window.crust
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                window.weatherSettingsStatus = "Validating..."
                                window.weatherSettingsStatusColor = window.yellow
                                weatherConfigSaver.running = true
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: window.weatherSettingsStatus
                    visible: text.length > 0
                    wrapMode: Text.Wrap
                    font.family: "Michroma"
                    font.pixelSize: 11
                    color: window.weatherSettingsStatusColor
                }
            }
        }
    }
}
