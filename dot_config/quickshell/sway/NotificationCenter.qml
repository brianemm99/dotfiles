import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

// Bell button for the bar. Opens a panel of past notifications that slides
// in from the middle of the screen's right edge.
Item {
    id: root

    // The bar window; the panel opens on its screen.
    required property PanelWindow bar

    property bool open: false
    readonly property int count: NotificationService.list.length

    // 0 = closed, 1 = open. The window stays mapped until it reaches 0 so
    // closing animates too.
    property real progress: open ? 1 : 0
    Behavior on progress {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    onOpenChanged: {
        NotificationService.centerOpen = open;
        // They're all in the panel now.
        if (open)
            NotificationService.popups = NotificationService.popups.filter(n => NotificationService.isTransient(n));
    }

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    BarButton {
        id: button
        anchors.fill: parent
        icon: NotificationService.dnd ? "\uf1f6" : "\uf0f3" // bell-slash, bell
        active: root.open
        onClicked: root.open = !root.open

        // Unread dot
        Rectangle {
            visible: root.count > 0 && !root.open
            x: parent.width / 2 + 3
            y: 3
            width: 6
            height: 6
            radius: 3
            color: Theme.accent
        }
    }

    // Full-screen and transparent so clicks outside the panel (and Escape)
    // close it; sway has no popup focus grab.
    PanelWindow {
        screen: root.bar.screen
        visible: root.open || root.progress > 0
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-notifications"

        onVisibleChanged: {
            if (visible)
                panel.forceActiveFocus();
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }

        Rectangle {
            id: panel

            readonly property int panelWidth: 380

            // Extends past the screen edge by its radius, so only the left
            // corners are rounded and it sits flush against the edge.
            x: parent.width - panelWidth * root.progress
            y: (parent.height - height) / 2
            width: panelWidth + radius
            height: Math.min(column.implicitHeight + 24, parent.height * 0.7)
            opacity: root.progress
            radius: Theme.radius
            color: Theme.bg
            border.width: 1
            border.color: Theme.border

            Keys.onEscapePressed: root.open = false

            // Swallow clicks so they don't reach the close area behind.
            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                id: column

                x: 12
                y: 12
                width: panel.panelWidth - 24
                height: panel.height - 24
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    BarText {
                        text: "Notifications"
                        font.bold: true
                        font.pixelSize: Theme.fontSize + 1
                    }

                    BarText {
                        visible: root.count > 0
                        text: root.count
                        color: Theme.muted
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        visible: root.count > 0
                        implicitWidth: clearLabel.implicitWidth + 16
                        implicitHeight: clearLabel.implicitHeight + 8
                        radius: Theme.radius
                        color: clearArea.containsMouse ? Theme.border : "transparent"

                        BarText {
                            id: clearLabel
                            anchors.centerIn: parent
                            text: "Clear all"
                            color: clearArea.containsMouse ? Theme.fg : Theme.muted
                        }

                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: NotificationService.dismissAll()
                        }
                    }
                }

                ToggleRow {
                    Layout.fillWidth: true
                    icon: "\uf186" // moon
                    label: "Do not disturb"
                    checked: NotificationService.dnd
                    onToggled: NotificationService.dnd = !NotificationService.dnd
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Theme.border
                }

                // Newest first; scrolls once the panel reaches its maximum height.
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: contentHeight
                    visible: root.count > 0
                    clip: true
                    spacing: 8
                    boundsBehavior: Flickable.StopAtBounds
                    model: [...NotificationService.list].reverse()

                    delegate: NotificationCard {
                        width: ListView.view.width
                        showTime: true
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 16
                    Layout.bottomMargin: 16
                    visible: root.count === 0
                    spacing: 8

                    Icon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uf1f6" // bell-slash
                        font.pixelSize: Theme.fontSize * 2
                        color: Theme.border
                    }

                    BarText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No notifications"
                        color: Theme.muted
                    }
                }
            }
        }
    }
}
