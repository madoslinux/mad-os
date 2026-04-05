import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../"

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
    readonly property color blue: _theme.blue
    readonly property color pink: _theme.pink
    readonly property color teal: _theme.teal
    readonly property color yellow: _theme.yellow
    readonly property color peach: _theme.peach
    readonly property color green: _theme.green
    readonly property color red: _theme.red
    readonly property color sapphire: _theme.sapphire

    // -------------------------------------------------------------------------
    // STATE & MATH
    // -------------------------------------------------------------------------
    property int activeEditIndex: 0
    property real uiScale: 0.10 
    
    // Dynamically tracks whichever monitor is NOT currently selected
    property int stationaryIndex: monitorsModel.count === 2 ? (activeEditIndex === 0 ? 1 : 0) : 0
    
    // Wayland Absolute Anchor tracking
    property int originalLayoutOriginX: 0
    property int originalLayoutOriginY: 0

    ListModel {
        id: monitorsModel
    }
    
    // Replaced hardcoded accents with dynamic defaults
    property color selectedResAccent: window.mauve
    property color selectedRateAccent: window.blue

    property real currentSimW: monitorsModel.count > 0 ? monitorsModel.get(0).resW : 1920
    property real currentSimH: monitorsModel.count > 0 ? monitorsModel.get(0).resH : 1080

    property real globalOrbitAngle: 0
    NumberAnimation on globalOrbitAngle {
        from: 0
        to: Math.PI * 2
        duration: 90000
        loops: Animation.Infinite
        running: true
    }
    // -------------------------------------------------------------------------
    // FLUID STARTUP ANIMATIONS 
    // -------------------------------------------------------------------------
    property real introProgress: 0.0
    property real monitorScale: 0.85
    property real uiYOffset: 25
    property real screenLight: 0.0

    Component.onCompleted: startupAnim.start()

    ParallelAnimation {
        id: startupAnim
        // Overall window and UI wrapper fades in
        NumberAnimation { target: window; property: "introProgress"; from: 0.0; to: 1.0; duration: 900; easing.type: Easing.OutQuint }
        
        // Monitor physical body scales in slightly
        NumberAnimation { target: window; property: "monitorScale"; from: 0.85; to: 1.0; duration: 1200; easing.type: Easing.OutQuint }
        
        // UI slides upwards gently into place - INCREASED DURATION FOR SLOWER GLIDE
        NumberAnimation { target: window; property: "uiYOffset"; from: 25; to: 0; duration: 1800; easing.type: Easing.OutQuint }
        
        // Inner screen contents fade in slower (powering on effect)
        NumberAnimation { target: window; property: "screenLight"; from: 0.0; to: 1.0; duration: 1500; easing.type: Easing.InOutQuad }
    }
    property bool applyHovered: false
    property bool applyPressed: false

    onActiveEditIndexChanged: {
        menuTransitionAnim.restart();
    }

    // MATHEMATICAL PERIMETER GLUE: Forces a proposed coordinate to perfectly touch the stationary monitor
    function getPerimeterSnap(pX, pY, sX, sY, sW, sH, mW, mH, snapT) {
        let edges = [
            { x1: sX - mW, x2: sX + sW, y1: sY - mH, y2: sY - mH }, // Top Edge
            { x1: sX - mW, x2: sX + sW, y1: sY + sH, y2: sY + sH }, // Bottom Edge
            { x1: sX - mW, x2: sX - mW, y1: sY - mH, y2: sY + sH }, // Left Edge
            { x1: sX + sW, x2: sX + sW, y1: sY - mH, y2: sY + sH }  // Right Edge
        ];

        let bestX = pX;
        let bestY = pY;
        let minDist = 999999;

        for (let i = 0; i < 4; i++) {
            let e = edges[i];
            
            let cx = Math.max(e.x1, Math.min(pX, e.x2));
            let cy = Math.max(e.y1, Math.min(pY, e.y2));

            if (Math.abs(cx - sX) < snapT) cx = sX;
            if (Math.abs(cx - (sX + sW - mW)) < snapT) cx = sX + sW - mW;
            if (Math.abs(cx - (sX + sW/2 - mW/2)) < snapT) cx = sX + sW/2 - mW/2;
            
            if (Math.abs(cy - sY) < snapT) cy = sY;
            if (Math.abs(cy - (sY + sH - mH)) < snapT) cy = sY + sH - mH;
            if (Math.abs(cy - (sY + sH/2 - mH/2)) < snapT) cy = sY + sH/2 - mH/2;

            let dist = Math.hypot(pX - cx, pY - cy);
            if (dist < minDist) {
                minDist = dist;
                bestX = cx;
                bestY = cy;
            }
        }
        return { x: bestX, y: bestY };
    }

    function forceLayoutUpdate() {
        if (monitorsModel.count === 2) {
            let mIdx = window.activeEditIndex;
            let sIdx = window.stationaryIndex;
            
            let sModel = monitorsModel.get(sIdx);
            let mModel = monitorsModel.get(mIdx);
            
            let sW = (sModel.resW / sModel.sysScale) * window.uiScale;
            let sH = (sModel.resH / sModel.sysScale) * window.uiScale;
            let mW = (mModel.resW / mModel.sysScale) * window.uiScale;
            let mH = (mModel.resH / mModel.sysScale) * window.uiScale;
            
            let snapped = window.getPerimeterSnap(
                mModel.uiX, mModel.uiY, 
                sModel.uiX, sModel.uiY, 
                sW, sH, mW, mH, 20
            );
            
            monitorsModel.setProperty(mIdx, "uiX", snapped.x);
            monitorsModel.setProperty(mIdx, "uiY", snapped.y);
        }
    }

    Timer {
        id: delayedLayoutUpdate
        interval: 10
        running: false
        repeat: false
        onTriggered: window.forceLayoutUpdate()
    }

    // -------------------------------------------------------------------------
    // NATIVE SYSTEM PROCESSES 
    // -------------------------------------------------------------------------
    Process {
        id: displayPoller
        command: ["hyprctl", "monitors", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text.trim());
                    monitorsModel.clear();
                    
                    let minX = 999999, minY = 999999;

                    for (let i = 0; i < data.length; i++) {
                        if (data[i].x < minX) minX = data[i].x;
                        if (data[i].y < minY) minY = data[i].y;
                    }

                    window.originalLayoutOriginX = minX !== 999999 ? minX : 0;
                    window.originalLayoutOriginY = minY !== 999999 ? minY : 0;

                    for (let i = 0; i < data.length; i++) {
                        let scl = data[i].scale !== undefined ? data[i].scale : 1.0;
                        let normalizedX = (data[i].x - minX) * window.uiScale;
                        let normalizedY = (data[i].y - minY) * window.uiScale;

                        monitorsModel.append({
                            name: data[i].name,
                            resW: data[i].width,
                            resH: data[i].height,
                            sysScale: scl,
                            rate: Math.round(data[i].refreshRate).toString(),
                            uiX: normalizedX,
                            uiY: normalizedY
                        });

                        if (data[i].focused) window.activeEditIndex = i;
                    }
                    
                    window.forceLayoutUpdate();
                } catch(e) {}
            }
        }
    }

    // -------------------------------------------------------------------------
    // UI LAYOUT
    // -------------------------------------------------------------------------
    Item {
        anchors.fill: parent
        scale: 0.95 + (0.05 * window.introProgress)
        opacity: window.introProgress

        Rectangle {
            anchors.fill: parent
            radius: 30
            color: window.base
            border.color: window.surface0
            border.width: 1
            clip: true

            Rectangle {
                width: parent.width * 0.8
                height: width
                radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * 150
                y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * 100
                opacity: 0.04
                color: window.selectedResAccent
                Behavior on color { ColorAnimation { duration: 1000 } }
            }
            Rectangle {
                width: parent.width * 0.9
                height: width
                radius: width / 2
                x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * -150
                y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * -100
                opacity: 0.04
                color: window.selectedRateAccent
                Behavior on color { ColorAnimation { duration: 1000 } }
            }

            // ==========================================
            // LEFT SIDE VISUAL AREA
            // ==========================================
            Item {
                id: leftVisualArea
                width: 380
                height: 300
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 20

                // --------------------------------------------------
                // MODE 1: SINGLE MONITOR
                // --------------------------------------------------
                Item {
                    anchors.fill: parent
                    visible: monitorsModel.count === 1

                    Item {
                        id: singleMonitorZoom
                        anchors.centerIn: parent
                        width: 380
                        height: 280
                        
                        property real baseScale: Math.min(1.0, 2200 / window.currentSimW)
                        scale: baseScale * window.monitorScale
                        opacity: window.introProgress
                        Behavior on baseScale { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }

                        Rectangle {
                            id: deskSurface
                            width: 1000
                            height: 14
                            radius: 6
                            anchors.top: standBase.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: window.mantle
                            border.color: window.surface0
                            border.width: 1

                            Rectangle { 
                                width: 24
                                height: 350
                                radius: 4
                                color: window.crust
                                anchors.top: parent.bottom
                                anchors.topMargin: -5
                                anchors.left: parent.left
                                anchors.leftMargin: 100
                                z: -1 
                            }
                            Rectangle { 
                                width: 24
                                height: 350
                                radius: 4
                                color: window.crust
                                anchors.top: parent.bottom
                                anchors.topMargin: -5
                                anchors.right: parent.right
                                anchors.rightMargin: 100
                                z: -1 
                            }
                        }

                        Rectangle {
                            id: standBase
                            width: 130
                            height: 8
                            radius: 4
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 20
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: window.surface1
                        }
                        
                        Rectangle {
                            id: standNeck
                            width: 34
                            height: 70
                            anchors.bottom: standBase.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: window.surface0
                            Rectangle { 
                                width: 10
                                height: 30
                                radius: 5
                                anchors.centerIn: parent
                                color: window.base 
                            }
                        }

                        Rectangle {
                            id: screenBezel
                            width: 140 + (180 * (window.currentSimW / 1920))
                            height: 90 + (90 * (window.currentSimH / 1080))
                            anchors.bottom: standNeck.top
                            anchors.bottomMargin: -10
                            anchors.horizontalCenter: parent.horizontalCenter
                            radius: 12
                            color: window.crust
                            border.color: window.surface2
                            border.width: 2
                            
                            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }
                            Behavior on height { NumberAnimation { duration: 600; easing.type: Easing.OutQuint } }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 10
                                radius: 6
                                color: window.surface0
                                clip: true

                                // This inner block handles the "powering on" visual delay
                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"
                                    opacity: window.screenLight
                                    
                                    gradient: Gradient {
                                        orientation: Gradient.Vertical
                                        GradientStop { 
                                            position: 0.0
                                            color: Qt.tint(window.surface0, Qt.alpha(window.selectedResAccent, 0.15))
                                            Behavior on color { ColorAnimation { duration: 400 } } 
                                        }
                                        GradientStop { 
                                            position: 1.0
                                            color: Qt.tint(window.surface0, Qt.alpha(window.selectedRateAccent, 0.1))
                                            Behavior on color { ColorAnimation { duration: 400 } } 
                                        }
                                    }
                                    
                                    Grid { 
                                        anchors.centerIn: parent
                                        rows: 10
                                        columns: 15
                                        spacing: 20
                                        Repeater { 
                                            model: 150
                                            Rectangle { width: 2; height: 2; radius: 1; color: Qt.alpha(window.text, 0.1) } 
                                        } 
                                    }

                                    Item {
                                        anchors.centerIn: parent
                                        scale: 1.0 / singleMonitorZoom.scale
                                        
                                        ColumnLayout {
                                            anchors.centerIn: parent
                                            spacing: 4
                                            Text { 
                                                Layout.alignment: Qt.AlignHCenter
                                                font.family: "Iosevka Nerd Font"
                                                font.pixelSize: 38
                                                color: window.selectedResAccent
                                                text: "󰍹"
                                                Behavior on color { ColorAnimation { duration: 400 } } 
                                            }
                                            Text { 
                                                Layout.alignment: Qt.AlignHCenter
                                                font.family: "Michroma"
                                                font.weight: Font.Bold
                                                font.pixelSize: 16
                                                color: window.text
                                                text: monitorsModel.count > 0 ? monitorsModel.get(0).name : "Unknown" 
                                            }
                                            Text { 
                                                Layout.alignment: Qt.AlignHCenter
                                                font.family: "Michroma"
                                                font.pixelSize: 12
                                                color: window.subtext0
                                                text: window.currentSimW + "x" + window.currentSimH + " @ " + (monitorsModel.count > 0 ? monitorsModel.get(0).rate : "60") + "Hz" 
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // --------------------------------------------------
                // MODE 2: MULTI-MONITOR
                // --------------------------------------------------
                Item {
                    anchors.fill: parent
                    visible: monitorsModel.count > 1

                    Item {
                        id: multiMonitorView
                        width: 380
                        height: 280
                        anchors.centerIn: parent
                        clip: true 

                        Grid {
                            anchors.centerIn: parent
                            rows: 25
                            columns: 34
                            spacing: 18
                            Repeater { 
                                model: 850
                                Rectangle { width: 2; height: 2; radius: 1; color: Qt.alpha(window.text, 0.1) } 
                            }
                        }

                        // Perfect mathematical scale: Centers the Bounding Box of both monitors
                        property real targetScale: {
                            if (monitorsModel.count < 2) return 1.0;
                            let sModel = monitorsModel.get(window.stationaryIndex);
                            let mModel = monitorsModel.get(window.activeEditIndex);
                            let sW = (sModel.resW / sModel.sysScale) * window.uiScale;
                            let sH = (sModel.resH / sModel.sysScale) * window.uiScale;
                            let mW = (mModel.resW / mModel.sysScale) * window.uiScale;
                            let mH = (mModel.resH / mModel.sysScale) * window.uiScale;

                            let minX = Math.min(sModel.uiX, mModel.uiX);
                            let minY = Math.min(sModel.uiY, mModel.uiY);
                            let maxX = Math.max(sModel.uiX + sW, mModel.uiX + mW);
                            let maxY = Math.max(sModel.uiY + sH, mModel.uiY + mH);

                            let requiredW = (maxX - minX) + 80; 
                            let requiredH = (maxY - minY) + 80;

                            return Math.min(1.8, Math.min(340 / requiredW, 240 / requiredH));
                        }
                        
                        // Centering math: Keep the bounding box perfectly centered in the 380x280 view
                        property real offsetX: {
                            if (monitorsModel.count < 2) return 0;
                            let sModel = monitorsModel.get(window.stationaryIndex);
                            let mModel = monitorsModel.get(window.activeEditIndex);
                            let sW = (sModel.resW / sModel.sysScale) * window.uiScale;
                            let mW = (mModel.resW / mModel.sysScale) * window.uiScale;
                            
                            let minX = Math.min(sModel.uiX, mModel.uiX);
                            let maxX = Math.max(sModel.uiX + sW, mModel.uiX + mW);
                            let centerX = minX + (maxX - minX) / 2;
                            
                            return 190 - (centerX * targetScale);
                        }
                        
                        property real offsetY: {
                            if (monitorsModel.count < 2) return 0;
                            let sModel = monitorsModel.get(window.stationaryIndex);
                            let mModel = monitorsModel.get(window.activeEditIndex);
                            let sH = (sModel.resH / sModel.sysScale) * window.uiScale;
                            let mH = (mModel.resH / mModel.sysScale) * window.uiScale;
                            
                            let minY = Math.min(sModel.uiY, mModel.uiY);
                            let maxY = Math.max(sModel.uiY + sH, mModel.uiY + mH);
                            let centerY = minY + (maxY - minY) / 2;
                            
                            return 140 - (centerY * targetScale);
                        }

                        Item {
                            id: transformNode
                            x: multiMonitorView.offsetX
                            y: multiMonitorView.offsetY
                            scale: multiMonitorView.targetScale
                            transformOrigin: Item.TopLeft

                            Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                            Behavior on y { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                            Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

                            Repeater {
                                id: monitorRepeater
                                model: monitorsModel

                                Item {
                                    property bool isActive: window.activeEditIndex === index

                                    // THE VISIBLE SNAPPED MONITOR CARD
                                    Rectangle {
                                        id: monitorCard
                                        x: model.uiX
                                        y: model.uiY
                                        
                                        width: (model.resW / model.sysScale) * window.uiScale
                                        height: (model.resH / model.sysScale) * window.uiScale
                                        
                                        radius: 8
                                        color: isActive ? window.surface1 : window.crust
                                        border.color: isActive ? window.selectedResAccent : window.surface2
                                        border.width: isActive ? 2 : 1
                                        z: isActive ? 5 : 0

                                        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                                        Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.OutQuint } }
                                        
                                        Behavior on border.color { ColorAnimation { duration: 300 } }
                                        Behavior on color { ColorAnimation { duration: 300 } }
                                        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }
                                        Behavior on height { NumberAnimation { duration: 400; easing.type: Easing.OutQuint } }

                                        Item {
                                            anchors.centerIn: parent
                                            width: 110
                                            height: 80
                                            
                                            property real idealScale: Math.min(1.2, parent.width / 110, parent.height / 80) / transformNode.scale
                                            property real maxPhysicalScale: Math.min((parent.width * 0.9) / width, (parent.height * 0.9) / height)
                                            scale: Math.min(idealScale, maxPhysicalScale)
                                            
                                            ColumnLayout {
                                                anchors.centerIn: parent
                                                spacing: 2
                                                Text { 
                                                    Layout.alignment: Qt.AlignHCenter
                                                    font.family: "Iosevka Nerd Font"
                                                    font.pixelSize: 32
                                                    color: isActive ? window.selectedResAccent : window.text
                                                    text: "󰍹"
                                                    Behavior on color { ColorAnimation { duration: 300 } } 
                                                }
                                                Text { 
                                                    Layout.alignment: Qt.AlignHCenter
                                                    font.family: "Michroma"
                                                    font.weight: Font.Black
                                                    font.pixelSize: 13
                                                    color: window.text
                                                    text: model.name 
                                                }
                                                Text { 
                                                    Layout.alignment: Qt.AlignHCenter
                                                    font.family: "Michroma"
                                                    font.pixelSize: 10
                                                    color: window.subtext0
                                                    text: model.resW + "x" + model.resH + " @ " + model.rate + "Hz" 
                                                }
                                            }
                                        }
                                    }

                                    // THE INVISIBLE GHOST DRAGGER
                                    Item {
                                        id: ghostDrag
                                        x: model.uiX
                                        y: model.uiY
                                        width: monitorCard.width
                                        height: monitorCard.height
                                        z: isActive ? 10 : 1

                                        MouseArea {
                                            id: ghostMa
                                            anchors.fill: parent
                                            drag.target: ghostDrag
                                            drag.axis: Drag.XAndYAxis
                                            
                                            onPressed: {
                                                window.activeEditIndex = index;
                                                ghostDrag.x = model.uiX;
                                                ghostDrag.y = model.uiY;
                                            }

                                            onPositionChanged: {
                                                if (drag.active && monitorsModel.count === 2) {
                                                    let sIdx = window.stationaryIndex;
                                                    let sModel = monitorsModel.get(sIdx);
                                                    
                                                    let sW = (sModel.resW / sModel.sysScale) * window.uiScale;
                                                    let sH = (sModel.resH / sModel.sysScale) * window.uiScale;
                                                    let mW = monitorCard.width;
                                                    let mH = monitorCard.height;

                                                    // Hard boundary limit: Stop the ghost from flying infinitely off the canvas
                                                    let padding = 40;
                                                    let minX = sModel.uiX - mW - padding;
                                                    let maxX = sModel.uiX + sW + padding;
                                                    let minY = sModel.uiY - mH - padding;
                                                    let maxY = sModel.uiY + sH + padding;

                                                    ghostDrag.x = Math.max(minX, Math.min(ghostDrag.x, maxX));
                                                    ghostDrag.y = Math.max(minY, Math.min(ghostDrag.y, maxY));
                                                    
                                                    let snapped = window.getPerimeterSnap(
                                                        ghostDrag.x, ghostDrag.y, 
                                                        sModel.uiX, sModel.uiY, 
                                                        sW, sH, mW, mH, 20
                                                    );
                                                    
                                                    monitorsModel.setProperty(index, "uiX", snapped.x);
                                                    monitorsModel.setProperty(index, "uiY", snapped.y);
                                                }
                                            }

                                            onReleased: {
                                                ghostDrag.x = model.uiX;
                                                ghostDrag.y = model.uiY;
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
            // INTERACTIVE SELECTION GRIDS
            // ==========================================
            Item {
                anchors.left: leftVisualArea.right
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter 
                anchors.leftMargin: 10
                anchors.rightMargin: 30
                height: 310

                // UI block animates upwards fluidly safely without breaking the GridLayout
                opacity: window.introProgress
                transform: Translate { y: window.uiYOffset }

                SequentialAnimation {
                    id: menuTransitionAnim
                    ParallelAnimation {
                        ScaleAnimator { 
                            target: rightSideContainer
                            from: 0.99
                            to: 1.0
                            duration: 200
                            easing.type: Easing.OutSine 
                        }
                        NumberAnimation { 
                            target: highlightFlash
                            property: "opacity"
                            from: 0.05
                            to: 0.0
                            duration: 250
                            easing.type: Easing.OutQuad 
                        }
                    }
                }

                Rectangle {
                    id: highlightFlash
                    anchors.fill: rightSideContainer
                    anchors.margins: -10
                    color: window.selectedResAccent
                    opacity: 0.0
                    radius: 12
                }

                ColumnLayout {
                    id: rightSideContainer
                    anchors.fill: parent
                    spacing: 12

                    // --- RESOLUTION CARDS SECTION ---
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 10

                        Repeater {
                            model: [
                                { resW: 3840, resH: 2160, label: "4K",   accent: window.pink }, 
                                { resW: 2560, resH: 1440, label: "QHD",  accent: window.mauve },
                                { resW: 1920, resH: 1080, label: "FHD",  accent: window.blue },
                                { resW: 1600, resH: 900,  label: "HD+",  accent: window.teal }, 
                                { resW: 1366, resH: 768,  label: "WXGA", accent: window.yellow }, 
                                { resW: 1280, resH: 720,  label: "HD",   accent: window.peach }, 
                                { resW: 1024, resH: 768,  label: "XGA",  accent: window.green }, 
                                { resW: 800,  resH: 600,  label: "SVGA", accent: window.red } 
                            ]

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                radius: 12
                                
                                property bool isSel: {
                                    if (monitorsModel.count === 0) return false;
                                    let activeMon = monitorsModel.get(window.activeEditIndex);
                                    return activeMon.resW === modelData.resW && activeMon.resH === modelData.resH;
                                }
                                property color accentColor: modelData.accent
                                
                                color: isSel ? Qt.alpha(accentColor, 0.15) : (resMa.containsMouse ? window.surface0 : window.mantle)
                                border.color: isSel ? accentColor : (resMa.containsMouse ? window.surface1 : "transparent")
                                border.width: isSel ? 2 : 1
                                
                                Behavior on color { ColorAnimation { duration: 200 } }
                                Behavior on border.color { ColorAnimation { duration: 200 } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8
                                    
                                    Text { 
                                        font.family: "Michroma"
                                        font.weight: isSel ? Font.Black : Font.Bold
                                        font.pixelSize: 16
                                        color: isSel ? accentColor : window.text
                                        text: modelData.label
                                        Behavior on color { ColorAnimation { duration: 200 } } 
                                    }
                                    
                                    Item { Layout.fillWidth: true } 
                                    
                                    Text { 
                                        font.family: "Michroma"
                                        font.pixelSize: 12
                                        color: isSel ? window.text : window.overlay0
                                        text: modelData.resW + "x" + modelData.resH
                                        Behavior on color { ColorAnimation { duration: 200 } } 
                                    }
                                }

                                scale: resMa.pressed ? 0.96 : 1.0
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutSine } }

                                MouseArea {
                                    id: resMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (monitorsModel.count > 0) {
                                            window.selectedResAccent = accentColor;
                                            monitorsModel.setProperty(window.activeEditIndex, "resW", modelData.resW);
                                            monitorsModel.setProperty(window.activeEditIndex, "resH", modelData.resH);
                                            delayedLayoutUpdate.restart();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.preferredHeight: 15 } 

                    // --- REFRESH RATE SLIDER SECTION ---
                    Item {
                        id: sliderContainer
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        Layout.leftMargin: 10
                        Layout.rightMargin: 10
                        
                        property var rates: [60, 75, 100, 120, 144, 240]
                        property var rateColors: [window.red, window.mauve, window.blue, window.sapphire, window.teal, window.green]
                        
                        property int currentIndex: {
                            if (monitorsModel.count === 0) return 0;
                            let currentVal = parseInt(monitorsModel.get(window.activeEditIndex).rate) || 60;
                            let closestIdx = 0;
                            let minDiff = 9999;
                            for (let i = 0; i < rates.length; i++) {
                                let diff = Math.abs(rates[i] - currentVal);
                                if (diff < minDiff) { 
                                    minDiff = diff; 
                                    closestIdx = i; 
                                }
                            }
                            return closestIdx;
                        }

                        property real visualPct: currentIndex / (rates.length - 1)

                        onCurrentIndexChanged: { 
                            if (!sliderMa.pressed) visualPct = currentIndex / (rates.length - 1); 
                        }

                        Rectangle {
                            id: track
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: -10
                            height: 12
                            radius: 6
                            color: window.mantle
                            border.color: window.crust
                            border.width: 1
                            
                            Rectangle { 
                                width: knob.x + knob.width / 2
                                height: parent.height
                                radius: parent.radius
                                color: window.selectedRateAccent
                                Behavior on color { ColorAnimation { duration: 200 } } 
                            }
                        }

                        Repeater {
                            model: sliderContainer.rates.length
                            Item {
                                x: (index / (sliderContainer.rates.length - 1)) * track.width
                                y: track.y + 20
                                
                                Text { 
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: sliderContainer.rates[index]
                                    font.family: "Michroma"
                                    font.pixelSize: 13
                                    font.weight: sliderContainer.currentIndex === index ? Font.Bold : Font.Normal
                                    color: sliderContainer.currentIndex === index ? window.selectedRateAccent : window.overlay0
                                    Behavior on color { ColorAnimation { duration: 200 } } 
                                }
                            }
                        }

                        Rectangle {
                            id: knob
                            width: 24
                            height: 24
                            radius: 12
                            color: sliderMa.containsPress ? window.selectedRateAccent : window.text
                            anchors.verticalCenter: track.verticalCenter
                            x: (sliderContainer.visualPct * track.width) - width / 2
                            
                            Behavior on x { 
                                enabled: !sliderMa.pressed
                                NumberAnimation { duration: 250; easing.type: Easing.OutCubic } 
                            }
                            Behavior on color { ColorAnimation { duration: 150 } }
                            
                            border.width: sliderMa.containsMouse ? 4 : 0
                            border.color: Qt.alpha(window.selectedRateAccent, 0.3)
                            Behavior on border.width { NumberAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: sliderMa
                            anchors.fill: parent
                            anchors.margins: -15
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            function updateSelection(mouseX, snapToGrid) {
                                if (monitorsModel.count === 0) return;
                                let pct = (mouseX - track.x) / track.width;
                                pct = Math.max(0, Math.min(1, pct));
                                let idx = Math.round(pct * (sliderContainer.rates.length - 1));
                                
                                if (snapToGrid) {
                                    sliderContainer.visualPct = idx / (sliderContainer.rates.length - 1);
                                } else {
                                    sliderContainer.visualPct = pct;
                                }

                                monitorsModel.setProperty(window.activeEditIndex, "rate", sliderContainer.rates[idx].toString());
                                window.selectedRateAccent = sliderContainer.rateColors[idx];
                            }

                            onPressed: (mouse) => updateSelection(mouse.x, false)
                            onPositionChanged: (mouse) => { if (pressed) updateSelection(mouse.x, false) }
                            onReleased: (mouse) => updateSelection(mouse.x, true)
                            onCanceled: () => sliderContainer.visualPct = sliderContainer.currentIndex / (sliderContainer.rates.length - 1)
                        }
                    }
                    
                    Item { Layout.fillHeight: true } 
                }
            }

            // ==========================================
            // FLOATING APPLY BUTTON 
            // ==========================================
            Item {
                id: applyButtonContainer
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 30
                width: 170
                height: 50
                
                // Matches the right side panel animation
                opacity: window.introProgress
                transform: Translate { y: window.uiYOffset }

                MultiEffect {
                    source: applyBtn
                    anchors.fill: applyBtn
                    shadowEnabled: true
                    shadowColor: window.selectedRateAccent
                    shadowBlur: window.applyHovered ? 1.2 : 0.6
                    shadowOpacity: window.applyHovered ? 0.6 : 0.2
                    shadowVerticalOffset: 4
                    z: -1
                    Behavior on shadowBlur { NumberAnimation { duration: 300 } } 
                    Behavior on shadowOpacity { NumberAnimation { duration: 300 } } 
                    Behavior on shadowColor { ColorAnimation { duration: 400 } }
                }

                Rectangle {
                    id: applyBtn
                    anchors.fill: parent
                    radius: 25
                    
                    gradient: Gradient { 
                        orientation: Gradient.Horizontal
                        GradientStop { 
                            position: 0.0
                            color: window.selectedResAccent
                            Behavior on color { ColorAnimation { duration: 400 } } 
                        } 
                        GradientStop { 
                            position: 1.0
                            color: window.selectedRateAccent
                            Behavior on color { ColorAnimation { duration: 400 } } 
                        } 
                    }
                    
                    scale: window.applyPressed ? 0.94 : (window.applyHovered ? 1.04 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

                    Rectangle {
                        id: flashRect
                        anchors.fill: parent
                        radius: 25
                        color: window.text
                        opacity: 0.0
                        PropertyAnimation on opacity { 
                            id: applyFlashAnim
                            to: 0.0
                            duration: 400
                            easing.type: Easing.OutExpo 
                        }
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        
                        Text { 
                            font.family: "Iosevka Nerd Font"
                            font.pixelSize: 20
                            color: window.crust
                            text: "󰸵" 
                        }
                        
                        Text { 
                            font.family: "Michroma"
                            font.weight: Font.Black
                            font.pixelSize: 14
                            color: window.crust
                            text: monitorsModel.count > 1 ? "Apply All" : "Apply" 
                        }
                    }
                }

                MouseArea {
                    id: applyMa
                    anchors.fill: parent
                    z: 10
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onEntered: window.applyHovered = true
                    onExited: window.applyHovered = false
                    onPressed: window.applyPressed = true
                    onReleased: window.applyPressed = false
                    onCanceled: window.applyPressed = false

                    onClicked: {
                        flashRect.opacity = 0.8; 
                        applyFlashAnim.start();

                        if (monitorsModel.count === 0) return;

                        if (monitorsModel.count === 1) {
                            let mon = monitorsModel.get(0);
                            let monitorStr = mon.name + "," + mon.resW + "x" + mon.resH + "@" + mon.rate + ",auto," + mon.sysScale;
                            Quickshell.execDetached(["notify-send", "Display Update", "Applied: " + mon.resW + "x" + mon.resH + " @ " + mon.rate + "Hz"]);
                            Quickshell.execDetached(["sh", "-c", "hyprctl keyword monitor " + monitorStr]);
                        } else {
                            let rects = [];
                            for (let i = 0; i < monitorsModel.count; i++) {
                                let m = monitorsModel.get(i);
                                let layoutW = Math.round(m.resW / m.sysScale);
                                let layoutH = Math.round(m.resH / m.sysScale);
                                let rawX = m.uiX / window.uiScale;
                                let rawY = m.uiY / window.uiScale;
                                rects.push({
                                    x: rawX, y: rawY, w: layoutW, h: layoutH, 
                                    resW: m.resW, resH: m.resH, name: m.name, 
                                    rate: m.rate, sysScale: m.sysScale
                                });
                            }
                            
                            if (rects.length === 2) {
                                let r0 = rects[0];
                                let r1 = rects[1];
                                
                                let snapped = window.getPerimeterSnap(
                                    r1.x, r1.y, 
                                    r0.x, r0.y, 
                                    r0.w, r0.h, r1.w, r1.h, 200 
                                );
                                
                                r1.x = Math.round(snapped.x);
                                r1.y = Math.round(snapped.y);
                            }

                            let finalMinX = 999999;
                            let finalMinY = 999999;
                            for (let i = 0; i < rects.length; i++) {
                                if (rects[i].x < finalMinX) finalMinX = rects[i].x;
                                if (rects[i].y < finalMinY) finalMinY = rects[i].y;
                            }
                            
                            let batchCmds = [];
                            let summaryString = "";
                            for (let i = 0; i < rects.length; i++) {
                                let r = rects[i];
                                
                                r.x = Math.round((r.x - finalMinX) + window.originalLayoutOriginX);
                                r.y = Math.round((r.y - finalMinY) + window.originalLayoutOriginY);
                                
                                let monitorStr = r.name + "," + r.resW + "x" + r.resH + "@" + r.rate + "," + r.x + "x" + r.y + "," + r.sysScale;
                                batchCmds.push("keyword monitor " + monitorStr);
                                summaryString += r.name + " ";
                            }
                            
                            let fullCommand = "hyprctl --batch '" + batchCmds.join(" ; ") + "'";
                            Quickshell.execDetached(["sh", "-c", fullCommand]);
                            Quickshell.execDetached(["notify-send", "Display Update", "Applied layout for: " + summaryString]);
                        }
                    }
                }
            }
        }
    }
}
