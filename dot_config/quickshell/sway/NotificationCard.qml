import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

// One notification. Clicking it dismisses it.
Rectangle {
    id: card

    required property Notification modelData
    // Show when it arrived, next to the summary.
    property bool showTime: false

    readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
    readonly property bool hovered: hover.containsMouse

    implicitHeight: content.implicitHeight + 20
    radius: Theme.radius
    color: Theme.surface
    border.width: 1
    border.color: critical ? Theme.urgent : Theme.border

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

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                BarText {
                    Layout.fillWidth: true
                    text: card.modelData.summary
                    font.bold: true
                    elide: Text.ElideRight
                }

                BarText {
                    visible: card.showTime
                    text: Qt.formatTime(NotificationService.received[card.modelData.id] ?? new Date(), "HH:mm")
                    color: Theme.muted
                    font.pixelSize: Theme.fontSize - 2
                }
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
