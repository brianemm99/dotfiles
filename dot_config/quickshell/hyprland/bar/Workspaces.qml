import QtQuick
import Quickshell.Hyprland
import qs

// One dot per existing workspace on this bar's monitor, in id order.
// The visible workspace of each monitor is a solid dot (accent on the focused monitor),
// the others hollow: fg if they hold windows, muted if empty. Urgent is crit.
Row {
    id: root

    required property HyprlandMonitor monitor

    // Special workspaces have negative ids and are hidden.
    readonly property var workspaces: Hyprland.workspaces.values
        .filter(w => w.id > 0 && w.monitor === root.monitor)
        .sort((a, b) => a.id - b.id)

    function goTo(id) {  // not "focus": that is a built-in Item property
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
    }

    // Next/previous existing workspace on this monitor, no wrap.
    function step(delta) {
        const ids = workspaces.map(w => w.id);
        const current = ids.indexOf(monitor?.activeWorkspace?.id ?? -1);
        const next = current + delta;
        if (current >= 0 && next >= 0 && next < ids.length)
            goTo(ids[next]);
    }

    spacing: 6

    Repeater {
        model: root.workspaces

        Item {
            id: cell

            required property HyprlandWorkspace modelData
            readonly property bool current: modelData.active
            readonly property bool occupied: modelData.toplevels.values.length > 0

            width: 14
            height: Theme.barHeight

            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                radius: 5
                readonly property color tint: cell.modelData.urgent ? Theme.crit
                    : cell.current ? (cell.modelData.focused ? Theme.accent : Theme.fg)
                    : cell.occupied ? Theme.fg : Theme.muted
                color: cell.current ? tint : "transparent"
                border.width: cell.current ? 0 : 1.5
                border.color: tint
                scale: mouse.containsMouse && !cell.current ? 1.2 : 1

                Behavior on scale {
                    NumberAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing }
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.goTo(cell.modelData.id)
            }
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => root.step(event.angleDelta.y < 0 ? 1 : -1)
    }
}
