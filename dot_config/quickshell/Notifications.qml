import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

Scope {
    id: root

    NotificationServer {
        id: server

        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            // Sway's volume/brightness keys tag their notifications with this hint;
            // replace the previous one instead of stacking a popup per keypress.
            const sync = notif.hints["x-canonical-private-synchronous"];
            if (sync) {
                for (const other of server.trackedNotifications.values) {
                    if (other.hints["x-canonical-private-synchronous"] === sync)
                        other.dismiss();
                }
            }
            notif.tracked = true;
        }
    }

    PanelWindow {
        anchors {
            top: true
            right: true
        }
        margins {
            top: 8
            right: 8
        }
        exclusiveZone: 0
        implicitWidth: 380
        implicitHeight: popups.implicitHeight
        color: "transparent"
        visible: server.trackedNotifications.values.length > 0

        ColumnLayout {
            id: popups
            width: parent.width
            spacing: 8

            Repeater {
                model: server.trackedNotifications

                Rectangle {
                    id: card

                    required property Notification modelData
                    readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
                    // -1 (or unset) means "server default"; 0 means never expire.
                    readonly property int timeout: modelData.expireTimeout > 0 ? modelData.expireTimeout
                        : modelData.expireTimeout === 0 || critical ? 0 : 5000

                    Layout.fillWidth: true
                    implicitHeight: content.implicitHeight + 20
                    radius: Theme.radius
                    color: Theme.surface
                    border.width: 1
                    border.color: critical ? Theme.urgent : Theme.border

                    Timer {
                        running: card.timeout > 0 && !hover.containsMouse
                        interval: card.timeout
                        onTriggered: card.modelData.expire()
                    }

                    MouseArea {
                        id: hover
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: card.modelData.dismiss()
                    }

                    RowLayout {
                        id: content
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        IconImage {
                            readonly property string src: card.modelData.image || card.modelData.appIcon
                            visible: src !== ""
                            source: src.startsWith("/") ? `file://${src}`
                                : src.includes("://") ? src
                                : Quickshell.iconPath(src, true)
                            implicitSize: 36
                            Layout.alignment: Qt.AlignTop
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            BarText {
                                Layout.fillWidth: true
                                text: card.modelData.summary
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            BarText {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: card.modelData.body
                                textFormat: Text.StyledText
                                color: Theme.muted
                                wrapMode: Text.Wrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                            }

                            // Progress hint, e.g. volume/brightness level.
                            Rectangle {
                                readonly property var value: card.modelData.hints["value"]
                                visible: value !== undefined
                                Layout.fillWidth: true
                                implicitHeight: 4
                                radius: 2
                                color: Theme.border

                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(100, parent.value ?? 0)) / 100
                                    height: parent.height
                                    radius: parent.radius
                                    color: Theme.accent
                                }
                            }

                            RowLayout {
                                visible: card.modelData.actions.length > 0
                                spacing: 6

                                Repeater {
                                    model: card.modelData.actions

                                    Rectangle {
                                        required property NotificationAction modelData
                                        implicitWidth: actionLabel.implicitWidth + 16
                                        implicitHeight: actionLabel.implicitHeight + 8
                                        radius: Theme.radius
                                        color: Theme.border

                                        BarText {
                                            id: actionLabel
                                            anchors.centerIn: parent
                                            text: parent.modelData.text
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: parent.modelData.invoke()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
