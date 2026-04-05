import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: Colors.base

    // FIX: Dynamically get the username. Fallback to the first user in the model if lastUser is empty.
    property string currentUserName: userModel.lastUser !== "" ? userModel.lastUser : (userModel.count > 0 ? userModel.data(userModel.index(0, 0), 257) : "User")

    // SDDM Connections for error handling
    Connections {
        target: sddm
        function onLoginFailed() {
            passwordField.text = ""
            errorMessage.opacity = 1.0
            errorHideTimer.restart()
        }
    }

    // 1. BACKGROUND & BLUR
    Item {
        anchors.fill: parent

        Image {
            id: bgWallpaper
            anchors.fill: parent
            source: config.background
            fillMode: Image.PreserveAspectCrop
            visible: false 
        }

        MultiEffect {
            anchors.fill: bgWallpaper
            source: bgWallpaper
            blurEnabled: true
            blurMax: 64
            blur: 1.0
        }
        
        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.25 
        }
    }

    // 2. CLOCK MODULE
    ColumnLayout {
        id: clockModule
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -120
        spacing: -10

        Text {
            id: timeText
            text: Qt.formatTime(new Date(), "hh:mm")
            font.family: "Michroma"
            font.pixelSize: 140
            font.weight: Font.Bold
            color: Colors.text
            Layout.alignment: Qt.AlignHCenter
        }

        Text {
            id: dateText
            text: Qt.formatDate(new Date(), "dddd, MMMM dd")
            font.family: "Michroma"
            font.pixelSize: 22
            font.weight: Font.Bold
            color: Colors.text
            Layout.alignment: Qt.AlignHCenter
        }

        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: {
                timeText.text = Qt.formatTime(new Date(), "hh:mm")
                dateText.text = Qt.formatDate(new Date(), "dddd, MMMM dd")
            }
        }
    }

    // 3. AUTHENTICATION MODULE
    RowLayout {
        id: authModule
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 60
        spacing: 32 

        // Avatar
        Rectangle {
            Layout.alignment: Qt.AlignVCenter | Qt.AlignTop
            width: 150; height: 150
            radius: 75
            color: Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.5)
            border.color: Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.5)
            border.width: 3
            clip: true

            Image {
                anchors.fill: parent
                // FIX: Use currentUserName instead of lastUser
                source: sddm.facesDir + "/" + root.currentUserName + ".face.icon"
                fillMode: Image.PreserveAspectCrop
                onStatusChanged: {
                    if (status == Image.Error) source = ""
                }
            }
        }

        // Details & Input
        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 12

            Text {
                // FIX: Use currentUserName instead of lastUser
                text: root.currentUserName
                font.family: "Michroma"
                font.pixelSize: 28
                font.weight: Font.Bold
                color: Colors.text
                Layout.alignment: Qt.AlignLeft
            }

            // IMPROVED: Styled Session Switcher
            ComboBox {
                id: sessionMenu
                Layout.alignment: Qt.AlignLeft
                Layout.preferredWidth: 280
                model: sessionModel
                textRole: "name"
                currentIndex: sessionModel.lastIndex
                font.family: "Michroma"
                font.pixelSize: 14
                
                background: Rectangle {
                    color: Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.5)
                    radius: 12
                    border.width: 1
                    border.color: sessionMenu.hovered || sessionMenu.popup.visible ? Colors.text : "transparent"
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                }

                contentItem: Text {
                    leftPadding: 16
                    rightPadding: sessionMenu.indicator.width + sessionMenu.spacing
                    text: "󰧨  " + sessionMenu.currentText
                    color: Colors.subtext0
                    font: sessionMenu.font
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                indicator: Text {
                    x: sessionMenu.width - width - 16
                    y: sessionMenu.topPadding + (sessionMenu.availableHeight - height) / 2
                    text: ""
                    font.family: "Iosevka Nerd Font"
                    font.pixelSize: 14
                    color: Colors.subtext0
                }

                popup: Popup {
                    y: sessionMenu.height + 8
                    width: sessionMenu.width
                    padding: 8
                    
                    background: Rectangle {
                        color: Colors.base
                        radius: 12
                        border.width: 1
                        border.color: Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.15)
                    }

                    contentItem: ListView {
                        clip: true
                        implicitHeight: contentHeight
                        model: sessionMenu.popup.visible ? sessionMenu.delegateModel : null
                        ScrollIndicator.vertical: ScrollIndicator { }
                    }
                }

                delegate: ItemDelegate {
                    width: sessionMenu.popup.width - 16
                    padding: 12
                    
                    contentItem: Text {
                        text: model.name
                        color: hovered ? Colors.base : Colors.text
                        font: sessionMenu.font
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        radius: 8
                        color: hovered ? Colors.text : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 280
                Layout.preferredHeight: 60
                radius: 30
                clip: true 
                
                color: Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.5)
                border.width: 2
                border.color: passwordField.focus ? Colors.text : Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.08)
                Behavior on border.color { ColorAnimation { duration: 250 } }

                TextInput {
                    id: passwordField
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true 
                    echoMode: TextInput.Password
                    font.family: "Michroma"
                    font.pixelSize: 24
                    color: Colors.text
                    focus: true

                    Text {
                        text: "Password..."
                        color: Qt.rgba(Colors.subtext0.r, Colors.subtext0.g, Colors.subtext0.b, 0.5)
                        font: passwordField.font
                        visible: !passwordField.text && !passwordField.inputMethodComposing
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    onAccepted: {
                        if (text !== "") {
                            errorMessage.opacity = 0.0 // Hide error on new attempt
                            // FIX: Use currentUserName instead of lastUser
                            sddm.login(root.currentUserName, text, sessionMenu.currentIndex)
                        }
                    }
                    
                    onTextChanged: {
                        if (errorMessage.opacity > 0) {
                            errorMessage.opacity = 0.0
                        }
                    }
                }
            }

            // NEW: Error Message Label
            Text {
                id: errorMessage
                Layout.alignment: Qt.AlignHCenter
                text: "Login failed. Please try again."
                font.family: "Michroma"
                font.pixelSize: 12
                color: Colors.red
                opacity: 0.0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Timer {
                    id: errorHideTimer
                    interval: 3000
                    onTriggered: errorMessage.opacity = 0.0
                }
            }
        }
    }
    
    // 4. POWER CONTROLS
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 40
        spacing: 24

        // Suspend
        Rectangle {
            width: 48; height: 48; radius: 24
            color: suspendMa.containsMouse ? Qt.rgba(Colors.mauve.r, Colors.mauve.g, Colors.mauve.b, 0.2) : Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.5)
            border.color: suspendMa.containsMouse ? Colors.mauve : Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.1)
            
            Text {
                anchors.centerIn: parent
                text: "󰒲"
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 20
                color: suspendMa.containsMouse ? Colors.mauve : Colors.text
            }
            MouseArea {
                id: suspendMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: sddm.suspend()
            }
        }

        // Reboot
        Rectangle {
            width: 48; height: 48; radius: 24
            color: rebootMa.containsMouse ? Qt.rgba(Colors.blue.r, Colors.blue.g, Colors.blue.b, 0.2) : Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.5)
            border.color: rebootMa.containsMouse ? Colors.blue : Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.1)
            
            Text {
                anchors.centerIn: parent
                text: "󰜉"
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 20
                color: rebootMa.containsMouse ? Colors.blue : Colors.text
            }
            MouseArea {
                id: rebootMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: sddm.reboot()
            }
        }

        // Power Off
        Rectangle {
            width: 48; height: 48; radius: 24
            color: powerMa.containsMouse ? Qt.rgba(Colors.red.r, Colors.red.g, Colors.red.b, 0.2) : Qt.rgba(Colors.surface0.r, Colors.surface0.g, Colors.surface0.b, 0.5)
            border.color: powerMa.containsMouse ? Colors.red : Qt.rgba(Colors.text.r, Colors.text.g, Colors.text.b, 0.1)
            
            Text {
                anchors.centerIn: parent
                text: "󰐥"
                font.family: "Iosevka Nerd Font"
                font.pixelSize: 20
                color: powerMa.containsMouse ? Colors.red : Colors.text
            }
            MouseArea {
                id: powerMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: sddm.powerOff()
            }
        }
    }
}
