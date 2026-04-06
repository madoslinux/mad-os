import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root
    focus: true

    property string widgetArg: "open"
    property string selectedAddress: ""
    property string pendingAction: "open"

    ListModel {
        id: windowsModel
    }

    function currentItemData() {
        if (listView.currentIndex < 0 || listView.currentIndex >= windowsModel.count)
            return null;

        return windowsModel.get(listView.currentIndex);
    }

    function refresh(action) {
        if (action !== undefined && action !== null)
            pendingAction = String(action);

        if (!listProcess.running)
            listProcess.running = true;
    }

    function open() {
        refresh("open");
    }

    function next() {
        if (windowsModel.count <= 0)
            return;

        listView.currentIndex = (listView.currentIndex + 1 + windowsModel.count) % windowsModel.count;
    }

    function prev() {
        if (windowsModel.count <= 0)
            return;

        listView.currentIndex = (listView.currentIndex - 1 + windowsModel.count) % windowsModel.count;
    }

    function cancel() {
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
    }

    function confirm() {
        let data = currentItemData();
        if (!data)
            return;

        Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:" + data.address]);
        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close", "switcher", "keepfocus"]);
    }

    function closeSelected() {
        let data = currentItemData();
        if (!data)
            return;

        Quickshell.execDetached(["hyprctl", "dispatch", "closewindow", "address:" + data.address]);
        refresh("open");
    }

    function runAction(actionName) {
        let action = String(actionName || "open").toLowerCase();
        if (action === "open" || action === "") {
            return;
        } else if (action === "next") {
            next();
        } else if (action === "prev") {
            prev();
        } else if (action === "confirm") {
            confirm();
        } else if (action === "cancel") {
            cancel();
        } else if (action === "close") {
            closeSelected();
        }
    }

    function rebuildModel(rawJson) {
        let parsed = [];

        try {
            parsed = JSON.parse(rawJson);
        } catch (e) {
            parsed = [];
        }

        if (!Array.isArray(parsed))
            parsed = [];

        parsed = parsed.filter(win => {
            let title = String(win.title || "");
            return title !== "qs-master";
        });

        parsed.sort((a, b) => {
            let ah = (a.focusHistoryID !== undefined && a.focusHistoryID !== null) ? Number(a.focusHistoryID) : 9999;
            let bh = (b.focusHistoryID !== undefined && b.focusHistoryID !== null) ? Number(b.focusHistoryID) : 9999;
            return ah - bh;
        });

        let previousAddress = selectedAddress;

        windowsModel.clear();
        for (let i = 0; i < parsed.length; i++) {
            let w = parsed[i];
            windowsModel.append({
                "address": String(w.address || ""),
                "title": String(w.title || "Untitled"),
                "appId": String(w.class || "App"),
                "workspaceId": (w.workspace && w.workspace.id !== undefined) ? Number(w.workspace.id) : 0,
                "focused": Number(w.focusHistoryID || 1) === 0
            });
        }

        if (windowsModel.count <= 0) {
            listView.currentIndex = -1;
            selectedAddress = "";
            return;
        }

        let nextIndex = -1;

        if (previousAddress !== "") {
            for (let i = 0; i < windowsModel.count; i++) {
                if (windowsModel.get(i).address === previousAddress) {
                    nextIndex = i;
                    break;
                }
            }
        }

        if (nextIndex === -1)
            nextIndex = windowsModel.count > 1 ? 1 : 0;

        listView.currentIndex = Math.max(0, Math.min(nextIndex, windowsModel.count - 1));
        selectedAddress = windowsModel.get(listView.currentIndex).address;
    }

    onWidgetArgChanged: {
        let arg = String(widgetArg || "open").toLowerCase();
        if (arg === "next" || arg === "prev")
            arg = "open";

        refresh(arg);
    }

    Component.onCompleted: {
        let arg = String(widgetArg || "open").toLowerCase();
        if (arg === "next" || arg === "prev")
            arg = "open";

        refresh(arg);
    }

    Keys.onEscapePressed: {
        cancel();
        event.accepted = true;
    }

    Keys.onReturnPressed: {
        confirm();
        event.accepted = true;
    }

    Keys.onEnterPressed: {
        confirm();
        event.accepted = true;
    }

    Keys.onLeftPressed: {
        prev();
        event.accepted = true;
    }

    Keys.onRightPressed: {
        next();
        event.accepted = true;
    }

    Keys.onTabPressed: {
        next();
        event.accepted = true;
    }

    Keys.onBacktabPressed: {
        prev();
        event.accepted = true;
    }

    Process {
        id: listProcess
        command: ["bash", "-c", "hyprctl -j clients"]

        stdout: StdioCollector {
            onStreamFinished: {
                let action = root.pendingAction;
                root.pendingAction = "open";
                root.rebuildModel(this.text.trim());
                root.runAction(action);
            }
        }
    }

    Timer {
        interval: 1200
        running: true
        repeat: true
        onTriggered: root.refresh("")
    }

    MatugenColors {
        id: theme
    }

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.95)
        border.width: 1
        border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.9)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 14

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "WINDOW SWITCHER"
                font.family: "Michroma"
                font.pixelSize: 18
                font.weight: Font.Black
                color: theme.text
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: windowsModel.count + " windows"
                font.family: "Michroma"
                font.pixelSize: 11
                font.weight: Font.Bold
                color: theme.subtext0
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 14
            color: Qt.rgba(theme.mantle.r, theme.mantle.g, theme.mantle.b, 0.88)
            border.width: 1
            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.9)

            ListView {
                id: listView
                anchors.fill: parent
                anchors.margins: 14
                orientation: ListView.Horizontal
                spacing: 12
                model: windowsModel
                clip: true

                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: Math.max(0, (width - 360) / 2)
                preferredHighlightEnd: Math.max(0, (width + 360) / 2)
                highlightMoveDuration: 220
                highlightFollowsCurrentItem: true
                header: Item {
                    width: Math.max(0, (listView.width - 360) / 2)
                    height: 1
                }
                footer: Item {
                    width: Math.max(0, (listView.width - 360) / 2)
                    height: 1
                }

                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < windowsModel.count)
                        root.selectedAddress = windowsModel.get(currentIndex).address;
                }

                delegate: Rectangle {
                    id: card
                    required property int index
                    required property var model

                    readonly property bool current: ListView.isCurrentItem

                    width: current ? 360 : 210
                    height: 420
                    radius: 12

                    color: current ? Qt.rgba(theme.surface1.r, theme.surface1.g, theme.surface1.b, 0.95) : Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.75)
                    border.width: current ? 2 : 1
                    border.color: current ? theme.blue : Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.8)

                    Behavior on width {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: 180
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 180
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 230
                            radius: 10
                            color: Qt.rgba(theme.crust.r, theme.crust.g, theme.crust.b, 0.95)
                            border.width: 1
                            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.9)

                            Text {
                                anchors.centerIn: parent
                                text: model.appId && model.appId.length > 0 ? model.appId.charAt(0).toUpperCase() : "?"
                                font.family: "Michroma"
                                font.pixelSize: current ? 96 : 72
                                font.weight: Font.Black
                                color: current ? theme.blue : theme.overlay1
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: (model.appId || "App").toUpperCase()
                            font.family: "Michroma"
                            font.pixelSize: 12
                            font.weight: Font.Black
                            color: current ? theme.blue : theme.text
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: model.title || "Untitled"
                            font.family: "Michroma"
                            font.pixelSize: 11
                            color: theme.subtext0
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "WS " + model.workspaceId
                                font.family: "Michroma"
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: theme.peach
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: model.focused === true
                                width: focusedLabel.implicitWidth + 10
                                height: 18
                                radius: 6
                                color: Qt.rgba(theme.green.r, theme.green.g, theme.green.b, 0.85)

                                Text {
                                    id: focusedLabel
                                    anchors.centerIn: parent
                                    text: "FOCUSED"
                                    font.family: "Michroma"
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    color: theme.base
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            listView.currentIndex = index;
                            root.confirm();
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: windowsModel.count === 0
                    text: "NO WINDOWS"
                    font.family: "Michroma"
                    font.pixelSize: 18
                    font.weight: Font.Black
                    color: theme.overlay1
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Tab/Shift+Tab to switch, Enter to focus, Esc to cancel"
            horizontalAlignment: Text.AlignHCenter
            font.family: "Michroma"
            font.pixelSize: 10
            font.weight: Font.Bold
            color: theme.subtext1
        }
    }
}
