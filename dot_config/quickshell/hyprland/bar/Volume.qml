import QtQuick
import Quickshell.Services.Pipewire
import qs
import qs.components

// Default output: icon by level and percent. Click mutes, scroll changes by 5 %.
// The volume keys stay in hyprland.lua; this only follows what they change.
Item {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int percent: Math.round(volume * 100)

    visible: sink !== null
    implicitWidth: label.implicitWidth
    implicitHeight: Theme.barHeight

    // binds the sink so its volume and mute stay live
    PwObjectTracker {
        objects: [root.sink]
    }

    IconText {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        readonly property string icon: root.muted ? "\u{F075F}"      // volume off
            : root.percent >= 60 ? "\u{F057E}"                        // high
            : root.percent >= 25 ? "\u{F0580}"                        // medium
            : "\u{F057F}"                                             // low
        text: `${icon} ${root.percent}%`
        color: root.muted ? Theme.muted : Theme.fg
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: event => {
            if (root.sink?.audio)
                root.sink.audio.muted = !root.sink.audio.muted;
        }
        onWheel: event => {
            if (!root.sink?.audio)
                return;
            const step = event.angleDelta.y > 0 ? 5 : -5;
            root.sink.audio.volume = Math.max(0, Math.min(100, Math.round(root.volume * 100 / 5) * 5 + step)) / 100;
        }
    }
}
