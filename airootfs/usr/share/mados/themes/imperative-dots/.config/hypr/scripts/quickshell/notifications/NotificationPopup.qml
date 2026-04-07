import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../"
import "../i18n"

Scope {
    id: notifScope

    property var notifications
    property string mainMonitor: ""
    property bool barVisible: false
    property int barHeight: 0

    property bool centerOpen: false

    property int popupWidth: 360
    property int popupSpacing: 8
    property int popupMaxVisible: 4
    property int popupRightMargin: 16
    property int popupTopMargin: 12

    readonly property int effectiveTopMargin: popupTopMargin + (barVisible ? barHeight : 0)
    readonly property int notifCount: notifications ? notifications.values.length : 0
    readonly property bool hasNotifs: notifCount > 0

    function toggleCenter() {
        centerOpen = !centerOpen;
    }

    function dismissAll() {
        if (!notifications)
            return;

        let vals = notifications.values;
        for (let i = vals.length - 1; i >= 0; i--) {
            vals[i].dismiss();
        }
    }

    MatugenColors {
        id: theme
    }

    PanelWindow {
        id: notifPanel

        screen: notifScope.mainMonitor !== "" ? (Quickshell.screens.find(s => s.name === notifScope.mainMonitor) ?? Quickshell.screens[0]) : Quickshell.screens[0]

        anchors {
            top: true
            right: true
        }

        implicitWidth: notifScope.centerOpen ? (screen ? screen.width : 1920) : (notifScope.popupWidth + notifScope.popupRightMargin * 2)
        implicitHeight: notifScope.centerOpen ? (screen ? screen.height : 1080) : Math.max(1, notifScope.effectiveTopMargin + popupColumn.implicitHeight + notifScope.popupSpacing + 8)

        color: "transparent"
        visible: notifScope.centerOpen || popupColumn.implicitHeight > 0

        WlrLayershell.namespace: "qs-notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: notifScope.centerOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        exclusionMode: ExclusionMode.Ignore

        Rectangle {
            anchors.fill: parent
            visible: notifScope.centerOpen
            color: Qt.rgba(0, 0, 0, 0.45)
            opacity: notifScope.centerOpen ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: notifScope.centerOpen = false
            }
        }

        FocusScope {
            anchors.fill: parent
            focus: notifScope.centerOpen

            Keys.onEscapePressed: {
                notifScope.centerOpen = false;
                event.accepted = true;
            }
        }

        Rectangle {
            id: centerCard
            visible: notifScope.centerOpen
            anchors.right: parent.right
            anchors.rightMargin: notifScope.popupRightMargin
            anchors.top: parent.top
            anchors.topMargin: notifScope.popupTopMargin
            anchors.bottom: parent.bottom
            anchors.bottomMargin: notifScope.popupTopMargin
            width: notifScope.popupWidth
            radius: 14

            color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.95)
            border.width: 1
            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.9)

            opacity: notifScope.centerOpen ? 1.0 : 0.0
            x: notifScope.centerOpen ? 0 : width + 48

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on x {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            RowLayout {
                id: centerHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 14
                height: 32
                spacing: 8

                Text {
                    text: I18n.s("NOTIFICATIONS")
                    font.family: "Michroma"
                    font.pixelSize: 12
                    font.weight: Font.Black
                    color: theme.text
                    Layout.fillWidth: true
                }

                Rectangle {
                    width: clearLabel.implicitWidth + 14
                    height: 24
                    radius: 8
                    color: clearMouse.containsMouse ? Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.85) : "transparent"
                    border.width: 1
                    border.color: Qt.rgba(theme.red.r, theme.red.g, theme.red.b, 0.7)

                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: I18n.s("CLEAR")
                        font.family: "Michroma"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: clearMouse.containsMouse ? theme.base : theme.red
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: notifScope.dismissAll()
                    }
                }
            }

            Flickable {
                anchors.top: centerHeader.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                anchors.leftMargin: 10
                anchors.rightMargin: 10

                clip: true
                contentHeight: centerColumn.implicitHeight
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: centerColumn
                    width: parent.width
                    spacing: notifScope.popupSpacing

                    Repeater {
                        model: notifScope.notifications

                        delegate: NotificationCard {
                            notification: modelData
                            cardWidth: centerColumn.width
                            isPopup: false
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: !notifScope.hasNotifs
                    text: I18n.s("NO NOTIFICATIONS")
                    font.family: "Michroma"
                    font.pixelSize: 13
                    font.weight: Font.Black
                    color: theme.overlay1
                }
            }
        }

        Column {
            id: popupColumn
            visible: !notifScope.centerOpen
            anchors.right: parent.right
            anchors.rightMargin: notifScope.popupRightMargin
            anchors.top: parent.top
            anchors.topMargin: notifScope.effectiveTopMargin
            width: notifScope.popupWidth
            spacing: notifScope.popupSpacing

            Repeater {
                id: popupRepeater
                model: notifScope.notifications

                delegate: NotificationCard {
                    property int rowIndex: index
                    notification: modelData
                    cardWidth: notifScope.popupWidth
                    isPopup: true

                    visible: rowIndex >= Math.max(0, notifScope.notifCount - notifScope.popupMaxVisible)
                }
            }
        }
    }

    component NotificationCard: Item {
        id: card

        property var notification
        property int cardWidth: 360
        property bool isPopup: true

        width: cardWidth
        property real naturalHeight: contentColumn.implicitHeight + 24
        height: naturalHeight
        clip: true

        property bool dismissing: false

        opacity: 0.0
        transform: Translate {
            id: cardTranslate
            x: 32
        }

        Component.onCompleted: {
            cardEntryAnim.start();
            if (isPopup)
                autoExpireTimer.start();
        }

        function animateDismiss() {
            if (dismissing)
                return;

            dismissing = true;
            autoExpireTimer.stop();
            cardEntryAnim.stop();
            cardExitAnim.start();
        }

        ParallelAnimation {
            id: cardEntryAnim

            NumberAnimation {
                target: card
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 220
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: cardTranslate
                property: "x"
                from: 32
                to: 0
                duration: 220
                easing.type: Easing.OutCubic
            }
        }

        SequentialAnimation {
            id: cardExitAnim

            ParallelAnimation {
                NumberAnimation {
                    target: card
                    property: "opacity"
                    to: 0
                    duration: 180
                    easing.type: Easing.InCubic
                }

                NumberAnimation {
                    target: cardTranslate
                    property: "x"
                    to: 32
                    duration: 180
                    easing.type: Easing.InCubic
                }
            }

            NumberAnimation {
                target: card
                property: "height"
                to: 0
                duration: 140
                easing.type: Easing.InOutCubic
            }

            ScriptAction {
                script: {
                    if (card.notification)
                        card.notification.dismiss();
                }
            }
        }

        Timer {
            id: autoExpireTimer
            interval: {
                if (card.notification && card.notification.expireTimeout > 0)
                    return card.notification.expireTimeout;

                return 6000;
            }
            running: false
            onTriggered: card.animateDismiss()
        }

        property bool hovered: cardMouse.containsMouse

        onHoveredChanged: {
            if (!isPopup)
                return;

            if (hovered) {
                autoExpireTimer.stop();
            } else if (!dismissing) {
                autoExpireTimer.restart();
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: Qt.rgba(theme.base.r, theme.base.g, theme.base.b, 0.92)
            border.width: 1
            border.color: Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.9)
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 4
            radius: 2
            color: theme.blue
        }

        ColumnLayout {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: 12
            anchors.leftMargin: 14
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: card.notification ? (card.notification.appName || I18n.s("Notification")) : I18n.s("Notification")
                    font.family: "Michroma"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: theme.blue
                }

                Text {
                    id: summaryLabel
                    text: card.notification ? (card.notification.summary || "") : ""
                    font.family: "Michroma"
                    font.pixelSize: 10
                    color: theme.text
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    visible: text !== ""
                }

                Text {
                    text: "x"
                    font.family: "Michroma"
                    font.pixelSize: 12
                    font.weight: Font.Black
                    color: closeMouse.containsMouse ? theme.red : theme.overlay1

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.animateDismiss()
                    }
                }
            }

            Text {
                text: card.notification ? (card.notification.body || "") : ""
                font.family: "Michroma"
                font.pixelSize: 11
                color: theme.subtext0
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                visible: text !== ""
                maximumLineCount: card.isPopup ? 3 : 6
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: card.notification && card.notification.actions && card.notification.actions.length > 0

                Repeater {
                    model: card.notification ? card.notification.actions : []

                    delegate: Rectangle {
                        property var action: modelData
                        width: actionLabel.implicitWidth + 16
                        height: 24
                        radius: 8
                        color: actionMouse.containsMouse ? theme.blue : Qt.rgba(theme.surface0.r, theme.surface0.g, theme.surface0.b, 0.85)
                        border.width: 1
                        border.color: actionMouse.containsMouse ? Qt.rgba(theme.blue.r, theme.blue.g, theme.blue.b, 1.0) : Qt.rgba(theme.surface2.r, theme.surface2.g, theme.surface2.b, 0.8)

                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: action && action.text ? action.text : I18n.s("Action")
                            font.family: "Michroma"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: actionMouse.containsMouse ? theme.base : theme.text
                        }

                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (action)
                                    action.invoke();
                            }
                        }
                    }
                }
            }
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.animateDismiss()
        }
    }
}
