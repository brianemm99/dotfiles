import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs
import qs.components
import qs.services

// Notification toasts (top right of the focused monitor) and the history panel, which slides
// in from the right edge of the screen it was opened on, centered on that edge.
// State lives in services/Notifs.
Scope {
    id: root

    // ---------------------------------------------------------------- history panel

    PanelWindow {
        id: panel

        // 0 = hidden off the right edge, 1 = fully in; animated here (Hyprland has no_anim on qs:)
        property real shown: Notifs.panelOpen ? 1 : 0
        Behavior on shown {
            NumberAnimation { duration: Theme.animDuration * 1.5; easing.type: Theme.animEasing }
        }

        screen: Notifs.panelScreen
        visible: Notifs.panelOpen || shown > 0

        // anchored to the right edge only, so the compositor centers it vertically
        anchors.right: true
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 380
        implicitHeight: Math.min(sheet.contentHeight, (screen?.height ?? 900) * 0.75)
        color: "transparent"

        WlrLayershell.namespace: "qs:notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: Notifs.panelOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        // a click anywhere outside closes it
        HyprlandFocusGrab {
            windows: [panel]
            active: Notifs.panelOpen
            onCleared: Notifs.closePanel()
        }

        Rectangle {
            id: sheet

            readonly property real contentHeight: header.height + list.contentHeight + 30

            // slides along x; extends past the right edge so only the left corners are round
            x: (1 - panel.shown) * panel.width
            width: panel.width + Theme.radius
            height: panel.height
            radius: Theme.radius
            color: Theme.bg
            border.width: 1
            border.color: Theme.surface

            focus: true
            Keys.onEscapePressed: Notifs.closePanel()

            Column {
                id: header
                x: 10
                y: 10
                width: panel.width - 20
                spacing: 4

                Item {
                    width: parent.width
                    height: 28

                    IconText {
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Notifications"
                        font.bold: true
                    }

                    IconText {
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Notifs.list.length > 0
                        text: "Clear all"
                        color: clearArea.containsMouse ? Theme.accent : Theme.muted

                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            anchors.margins: -4
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Notifs.clearAll()
                        }
                    }
                }

                Toggle {
                    width: parent.width
                    icon: "\u{F009B}" // bell off
                    label: "Do not disturb"
                    detail: checked ? "Toasts off, history still fills" : ""
                    checked: Notifs.dnd
                    onClicked: Notifs.dnd = !Notifs.dnd
                }
            }

            ListView {
                id: list
                x: 10
                y: header.y + header.height + 10
                width: panel.width - 20
                height: panel.height - y - 10
                clip: true
                spacing: 8
                boundsBehavior: Flickable.StopAtBounds
                model: Notifs.list

                delegate: NotificationCard {
                    required property var modelData
                    width: list.width
                    notification: modelData
                    onCloseClicked: notification.dismiss()
                    onActivated: Notifs.closePanel()
                }

                IconText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 6
                    visible: list.count === 0
                    text: "No notifications"
                    color: Theme.muted
                }
            }
        }
    }

    // ---------------------------------------------------------------- toasts

    PanelWindow {
        id: toasts

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
        visible: Notifs.toasts.length > 0 && !Notifs.panelOpen

        anchors {
            top: true
            right: true
        }
        margins {
            top: 8
            right: 8
        }
        // sit below the bar without reserving space of its own
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        implicitWidth: 360
        implicitHeight: Math.max(1, stack.implicitHeight)
        color: "transparent"

        WlrLayershell.namespace: "qs:notifications"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Column {
            id: stack
            width: parent.width
            spacing: 8

            Repeater {
                model: Notifs.toasts

                NotificationCard {
                    id: toast
                    required property var modelData
                    width: stack.width
                    notification: modelData
                    toast: true
                    onCloseClicked: Notifs.hideToast(notification)
                    onActivated: Notifs.hideToast(notification)

                    // hovering pauses the countdown; critical ones (timeout 0) stay
                    Timer {
                        interval: Notifs.timeoutOf(toast.notification)
                        running: interval > 0 && !toast.hovered
                        onTriggered: Notifs.hideToast(toast.notification)
                    }
                }
            }
        }
    }
}
