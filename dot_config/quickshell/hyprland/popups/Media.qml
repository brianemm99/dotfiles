import QtQuick
import Quickshell
import Quickshell.Widgets
import qs
import qs.components
import qs.services

// Media drop-down under the bar's NowPlaying module (click only, no keybind).
// Wide and short: album art on the left; on the right the Browser / Spotify switch (centred),
// title and artist, previous / play-pause / next; the scrub bar runs the full width at the bottom.
// Buttons run playerctl on the shown player; the scrub bar seeks on release.
// With no player: no art, "Nothing playing", everything greyed out. Esc or a click outside closes.
DropDown {
    id: root

    readonly property int pad: 14
    readonly property int inner: 400
    readonly property int artSize: 120
    readonly property var player: Players.active
    readonly property bool has: player !== null

    open: Players.open
    screen: Players.screen
    namespace: "qs:media"
    onCloseRequested: Players.hide()

    // centred under the module, kept on screen
    anchors {
        top: true
        left: true
    }
    margins.left: Math.max(0, Math.min((screen?.width ?? 0) - implicitWidth, Players.anchorX - implicitWidth / 2))
    implicitWidth: inner + pad * 2
    implicitHeight: body.implicitHeight + pad * 2

    // Mpris position doesn't update by itself; ask for it while visible (also once when paused)
    Timer {
        running: root.open && root.has
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.player.positionChanged()
    }

    function time(s) {
        s = Math.max(0, Math.floor(s));
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), sec = s % 60;
        const mm = h > 0 ? String(m).padStart(2, "0") : String(m);
        return (h > 0 ? h + ":" : "") + mm + ":" + String(sec).padStart(2, "0");
    }

    // one half of the Browser / Spotify switch
    component SourceButton: Rectangle {
        id: btn

        property string source
        property string label
        readonly property var player: source === "spotify" ? Players.spotify : Players.browser
        readonly property bool available: player !== null
        readonly property bool selected: Players.source === source

        width: 80
        height: 24
        radius: Theme.radius - 2
        color: selected ? Theme.accent : hover.hovered && available ? Theme.surface : "transparent"

        Row {
            anchors.centerIn: parent
            spacing: 6

            IconText {
                text: btn.label
                font.pixelSize: Theme.fontSize - 1
                color: btn.selected ? Theme.accentText : btn.available ? Theme.fg : Theme.muted
            }
            // this source is playing right now
            IconText {
                visible: btn.player?.isPlaying ?? false
                text: "\u{F040A}"
                font.pixelSize: 9
                color: btn.selected ? Theme.accentText : Theme.accent2
            }
        }

        HoverHandler {
            id: hover
            cursorShape: btn.available ? Qt.PointingHandCursor : Qt.ArrowCursor
        }
        TapHandler {
            enabled: btn.available
            onTapped: Players.select(btn.source)
        }
    }

    component ControlButton: Rectangle {
        id: ctl

        property string icon
        property bool enabled: true
        property bool primary: false
        signal clicked

        width: primary ? 40 : 32
        height: width
        radius: width / 2
        color: primary ? (enabled ? Theme.accent : Theme.surface) : area.containsMouse && enabled ? Theme.surface : "transparent"

        IconText {
            anchors.centerIn: parent
            text: ctl.icon
            font.pixelSize: ctl.primary ? 20 : 18
            color: !ctl.enabled ? Theme.muted : ctl.primary ? Theme.accentText : Theme.fg
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            enabled: ctl.enabled
            cursorShape: Qt.PointingHandCursor
            onClicked: ctl.clicked()
        }
    }

    Item {
        anchors.fill: parent
        focus: true

        Column {
            id: body
            x: root.pad
            y: root.pad
            width: root.inner
            spacing: 20     // room above the scrub bar

            Row {
                width: parent.width
                spacing: 14

                // album art; a glyph while there is none
                ClippingRectangle {
                    width: root.artSize
                    height: root.artSize
                    radius: Theme.radius
                    color: Theme.surface

                    Image {
                        id: art
                        anchors.fill: parent
                        visible: root.has
                        source: root.has ? Players.artUrl(root.player) : ""
                        sourceSize: Qt.size(root.artSize * 2, root.artSize * 2)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    IconText {
                        visible: !root.has || art.status !== Image.Ready
                        anchors.centerIn: parent
                        text: "\u{F075A}" // music
                        font.pixelSize: 44
                        color: Theme.muted
                    }
                }

                Item {
                    width: root.inner - root.artSize - parent.spacing
                    height: root.artSize

                    // Browser / Spotify, centred over the buttons
                    Rectangle {
                        id: toggle
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: sources.implicitWidth + 4
                        height: 28
                        radius: Theme.radius
                        color: Theme.bg
                        border.width: 1
                        border.color: Theme.surface

                        Row {
                            id: sources
                            anchors.centerIn: parent

                            SourceButton {
                                source: "browser"
                                label: "Browser"
                            }
                            SourceButton {
                                source: "spotify"
                                label: "Spotify"
                            }
                        }
                    }

                    // title and artist
                    Column {
                        anchors.top: toggle.bottom
                        anchors.topMargin: 10
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 2

                        IconText {
                            width: parent.width
                            elide: Text.ElideRight
                            font.bold: root.has
                            color: root.has ? Theme.fg : Theme.muted
                            text: root.has ? (root.player.trackTitle || root.player.identity) : "Nothing playing"
                        }
                        IconText {
                            width: parent.width
                            visible: root.has && root.player.trackArtist !== ""
                            elide: Text.ElideRight
                            font.pixelSize: Theme.fontSize - 1
                            color: Theme.muted
                            text: root.player?.trackArtist ?? ""
                        }
                    }

                    // previous, play/pause, next
                    Row {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 16

                        ControlButton {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "\u{F04AE}" // skip previous
                            enabled: root.has && root.player.canGoPrevious
                            onClicked: Players.command("previous")
                        }
                        ControlButton {
                            anchors.verticalCenter: parent.verticalCenter
                            primary: true
                            icon: root.player?.isPlaying ? "\u{F03E4}" : "\u{F040A}" // pause / play
                            enabled: root.has && root.player.canTogglePlaying
                            onClicked: Players.command("play-pause")
                        }
                        ControlButton {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: "\u{F04AD}" // skip next
                            enabled: root.has && root.player.canGoNext
                            onClicked: Players.command("next")
                        }
                    }
                }
            }

            // scrub bar: drag shows where it will land, release seeks
            Column {
                id: scrub
                width: parent.width
                spacing: 4

                readonly property real length: root.has && root.player.lengthSupported ? root.player.length : 0
                readonly property bool seekable: root.has && root.player.canSeek && root.player.positionSupported && length > 0
                readonly property real pos: root.has && root.player.positionSupported ? root.player.position : 0
                readonly property real frac: drag.pressed ? drag.frac : length > 0 ? Math.max(0, Math.min(1, pos / length)) : 0

                Item {
                    width: parent.width
                    height: 14

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 4
                        radius: 2
                        color: Theme.surface

                        Rectangle {
                            width: scrub.frac * parent.width
                            height: parent.height
                            radius: parent.radius
                            color: scrub.seekable ? Theme.accent : Theme.muted
                        }
                    }
                    Rectangle {
                        visible: scrub.seekable
                        anchors.verticalCenter: parent.verticalCenter
                        x: scrub.frac * (parent.width - width)
                        width: drag.pressed || drag.containsMouse ? 12 : 8
                        height: width
                        radius: width / 2
                        color: Theme.fg
                    }

                    MouseArea {
                        id: drag
                        property real frac: 0
                        anchors.fill: parent
                        enabled: scrub.seekable
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: event => frac = Math.max(0, Math.min(1, event.x / width))
                        onPositionChanged: event => {
                            if (pressed)
                                frac = Math.max(0, Math.min(1, event.x / width));
                        }
                        onReleased: Players.seek(frac * scrub.length)
                    }
                }

                Item {
                    width: parent.width
                    height: elapsed.implicitHeight

                    IconText {
                        id: elapsed
                        anchors.left: parent.left
                        font.pixelSize: Theme.fontSize - 2
                        color: Theme.muted
                        text: scrub.length > 0 ? root.time(scrub.frac * scrub.length) : "-:--"
                    }
                    IconText {
                        anchors.right: parent.right
                        font.pixelSize: Theme.fontSize - 2
                        color: Theme.muted
                        text: scrub.length > 0 ? root.time(scrub.length) : "-:--"
                    }
                }
            }
        }
    }
}
