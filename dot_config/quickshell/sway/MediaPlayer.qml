import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets

// Now playing, with a dropdown for album art, a scrub bar and playback
// controls. Tabs switch between MPRIS players (Spotify, the browser, ...).
BarMenu {
    id: root

    // playerctld mirrors whichever player is active, so it would duplicate one.
    readonly property var players: Mpris.players.values
        .filter(p => !p.dbusName.includes("playerctld"))

    // The tab picked by the user; falls back to whatever is playing.
    property MprisPlayer chosen: null
    readonly property MprisPlayer player: players.includes(chosen) ? chosen
        : players.find(p => p.isPlaying) ?? players[0] ?? null

    function playerIcon(player: MprisPlayer): string {
        const name = `${player.identity} ${player.desktopEntry}`.toLowerCase();
        return name.includes("spotify") ? "\uf1bc" // spotify (brands)
            : /brave|chrom|firefox|browser/.test(name) ? "\uf0ac" // globe
            : "\uf001"; // music
    }

    function formatTime(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        const pad = n => String(n).padStart(2, "0");
        return s >= 3600
            ? `${Math.floor(s / 3600)}:${pad(Math.floor(s / 60) % 60)}:${pad(s % 60)}`
            : `${Math.floor(s / 60)}:${pad(s % 60)}`;
    }

    visible: player !== null
    onVisibleChanged: if (!visible) open = false

    icon: player?.isPlaying ? "\uf001" : "\uf04c" // music, pause
    label: player ? (player.trackTitle || player.identity) : ""
    maxLabelChars: 30

    // MPRIS doesn't push position updates, so poll while it's on screen.
    Timer {
        interval: 1000
        repeat: true
        running: root.open && (root.player?.isPlaying ?? false)
        onTriggered: root.player.positionChanged()
    }

    ColumnLayout {
        id: content

        readonly property int artSize: 288

        width: artSize + 16
        spacing: 8

        // Player tabs
        RowLayout {
            Layout.topMargin: 6
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            spacing: 4
            visible: root.players.length > 1

            Repeater {
                model: root.players

                Rectangle {
                    id: tab

                    required property MprisPlayer modelData
                    readonly property bool selected: modelData === root.player
                    readonly property string glyph: root.playerIcon(modelData)

                    Layout.fillWidth: true
                    implicitHeight: Theme.barHeight - 6
                    radius: Theme.radius
                    color: selected ? Theme.accent : tabArea.containsMouse ? Theme.border : "transparent"

                    Row {
                        anchors.centerIn: parent
                        spacing: 6

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            text: tab.glyph
                            // Brands only has a regular face.
                            font.family: tab.glyph === "\uf1bc" ? "Font Awesome 6 Brands" : Theme.iconFont
                            font.weight: tab.glyph === "\uf1bc" ? Font.Normal : Font.Black
                            color: tab.selected ? Theme.bg : Theme.fg
                        }

                        BarText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: tab.modelData.identity
                            color: tab.selected ? Theme.bg : Theme.fg
                        }
                    }

                    MouseArea {
                        id: tabArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.chosen = tab.modelData
                    }
                }
            }
        }

        // Album art, or a music note when the player doesn't provide any.
        ClippingRectangle {
            Layout.topMargin: root.players.length > 1 ? 0 : 6
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: content.artSize
            implicitHeight: content.artSize
            radius: Theme.radius
            color: Theme.surface

            Image {
                id: art
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: content.artSize * 2
                sourceSize.height: content.artSize * 2
            }

            Icon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                text: "\uf001"
                font.pixelSize: content.artSize / 4
                color: Theme.border
            }
        }

        // Title and artist
        ColumnLayout {
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.fillWidth: true
            spacing: 0

            Marquee {
                Layout.fillWidth: true
                text: root.player?.trackTitle || "Nothing playing"
                font.pixelSize: Theme.fontSize + 1
                font.weight: Font.DemiBold
            }

            Marquee {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.player?.trackArtist ?? ""
                color: Theme.muted
            }
        }

        // Scrub bar, with elapsed and total time. Seeks on release.
        ColumnLayout {
            id: scrub

            readonly property real length: root.player?.length ?? 0
            readonly property bool seekable: (root.player?.canSeek ?? false) && length > 0
            readonly property real fraction: length > 0
                ? Math.min(1, (scrubArea.pressed ? scrubArea.preview : root.player.position) / length)
                : 0

            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.fillWidth: true
            spacing: 2
            visible: root.player?.lengthSupported ?? false

            Item {
                Layout.fillWidth: true
                implicitHeight: 14

                Rectangle {
                    id: scrubTrack
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Theme.border

                    Rectangle {
                        width: parent.width * scrub.fraction
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: scrub.seekable
                    x: (parent.width - width) * scrub.fraction
                    width: 12
                    height: 12
                    radius: 6
                    color: Theme.fg
                }

                MouseArea {
                    id: scrubArea

                    // Position under the pointer while dragging, in seconds.
                    property real preview: 0

                    function update(x: real): void {
                        preview = Math.max(0, Math.min(1, x / width)) * scrub.length;
                    }

                    anchors.fill: parent
                    enabled: scrub.seekable
                    preventStealing: true
                    onPressed: mouse => update(mouse.x)
                    onPositionChanged: mouse => update(mouse.x)
                    onReleased: root.player.position = preview
                }
            }

            RowLayout {
                Layout.fillWidth: true

                BarText {
                    text: root.formatTime(scrubArea.pressed ? scrubArea.preview : root.player?.position ?? 0)
                    color: Theme.muted
                    font.pixelSize: Theme.fontSize - 2
                }

                Item {
                    Layout.fillWidth: true
                }

                BarText {
                    text: root.formatTime(scrub.length)
                    color: Theme.muted
                    font.pixelSize: Theme.fontSize - 2
                }
            }
        }

        // Previous, play/pause, next
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 6
            spacing: 16

            Repeater {
                model: [
                    { icon: "\uf048", size: 40, enabled: root.player?.canGoPrevious ?? false, action: () => root.player.previous() },
                    { icon: root.player?.isPlaying ? "\uf04c" : "\uf04b", size: 48, enabled: root.player?.canTogglePlaying ?? false, action: () => root.player.togglePlaying() },
                    { icon: "\uf051", size: 40, enabled: root.player?.canGoNext ?? false, action: () => root.player.next() },
                ]

                Rectangle {
                    id: control

                    required property var modelData
                    required property int index
                    readonly property bool primary: index === 1

                    implicitWidth: modelData.size
                    implicitHeight: modelData.size
                    radius: width / 2
                    opacity: modelData.enabled ? 1 : 0.4
                    color: primary ? Theme.accent
                        : controlArea.containsMouse && modelData.enabled ? Theme.border
                        : "transparent"

                    Icon {
                        anchors.centerIn: parent
                        // Nudge the play triangle so it looks centred.
                        anchors.horizontalCenterOffset: text === "\uf04b" ? 2 : 0
                        text: control.modelData.icon
                        font.pixelSize: control.primary ? Theme.fontSize + 5 : Theme.fontSize + 2
                        color: control.primary ? Theme.bg : Theme.fg
                    }

                    MouseArea {
                        id: controlArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: control.modelData.enabled
                        onClicked: control.modelData.action()
                    }
                }
            }
        }
    }
}
