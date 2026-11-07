import QtQuick
import Quickshell
import Quickshell.Widgets
import qs
import qs.components
import qs.services

// Right of the clock: album art and "Title | Artist" of the selected source (services/Players),
// at most 30 characters wide; longer text scrolls. Paused: the same, dimmed. No player: " - ".
// Click opens the media drop-down under it.
Item {
    id: root

    required property ShellScreen screen

    readonly property var player: Players.active
    readonly property string text: Players.label(player)
    readonly property bool scrolls: label.implicitWidth > maxWidth
    readonly property real maxWidth: chars.width     // 30 characters of the monospace font

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    TextMetrics {
        id: chars
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        text: "0".repeat(30)
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        opacity: root.player && !root.player.isPlaying ? 0.5 : 1

        ClippingRectangle {
            visible: root.player !== null
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            radius: 4
            color: Theme.surface

            Image {
                id: art
                anchors.fill: parent
                source: Players.artUrl(root.player)
                sourceSize: Qt.size(40, 40)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
            IconText {
                visible: art.status !== Image.Ready
                anchors.centerIn: parent
                text: "\u{F075A}" // music
                font.pixelSize: 12
                color: Theme.muted
            }
        }

        // the window the text moves in
        Item {
            visible: root.player !== null
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(label.implicitWidth, root.maxWidth)
            height: label.implicitHeight
            clip: true

            Row {
                id: strip
                spacing: 0

                IconText {
                    id: label
                    text: root.text
                }
                // second copy trails the first so the loop is seamless
                IconText {
                    visible: root.scrolls
                    text: "     " + root.text
                }
            }

            SequentialAnimation {
                running: root.scrolls
                loops: Animation.Infinite
                onRunningChanged: if (!running)
                    strip.x = 0

                PauseAnimation {
                    duration: 2000
                }
                NumberAnimation {
                    target: strip
                    property: "x"
                    from: 0
                    // one copy plus the gap, then x = 0 looks identical
                    to: -(strip.implicitWidth - label.implicitWidth)
                    duration: Math.max(1, (strip.implicitWidth - label.implicitWidth) * 1000 / 30)   // 30 px/s
                }
            }
        }

        IconText {
            visible: root.player === null
            text: " - "
            color: Theme.muted
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Players.toggle(root.screen, root.mapToItem(null, root.width / 2, 0).x)
    }
}
