import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import qs

// One dot per workspace that belongs on this bar's monitor, in id order: its home
// workspaces (from Hyprland's workspace rules, so the split lives only in
// monitors/devices.lua) plus any other workspace currently on this monitor.
// The visible workspace of each monitor is a solid dot (accent on the focused monitor).
// Others with windows are hollow fg; unused ones (missing or empty) are a small muted dot.
// Urgent is crit.
Row {
    id: root

    required property HyprlandMonitor monitor

    // workspace id -> rule's monitor selector ("eDP-1" or "desc:...")
    property var rules: ({})

    function matches(m, sel) {
        if (!m || !sel)
            return false;
        if (sel.startsWith("desc:"))
            return (m.description ?? "").startsWith(sel.slice(5));
        return m.name === sel;
    }

    // A rule whose monitor is not connected gets no placeholder dot anywhere; if that
    // workspace is in use it still shows on whichever monitor it is on.
    function homeOf(id) {
        const sel = root.rules[id];
        return Hyprland.monitors.values.find(m => matches(m, sel)) ?? null;
    }

    // Special workspaces have negative ids and are hidden.
    readonly property var ids: {
        const set = new Set();
        for (const id in root.rules)
            if (homeOf(Number(id)) === root.monitor)
                set.add(Number(id));
        for (const w of Hyprland.workspaces.values)
            if (w.id > 0 && w.monitor === root.monitor)
                set.add(w.id);
        return [...set].sort((a, b) => a - b);
    }

    function workspace(id) {
        return Hyprland.workspaces.values.find(w => w.id === id) ?? null;
    }

    function goTo(id) {  // not "focus": that is a built-in Item property
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
    }

    // Next/previous dot on this monitor, no wrap.
    function step(delta) {
        const current = ids.indexOf(monitor?.activeWorkspace?.id ?? -1);
        const next = current + delta;
        if (current >= 0 && next >= 0 && next < ids.length)
            goTo(ids[next]);
    }

    Process {
        id: readRules
        command: ["hyprctl", "workspacerules", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const map = {};
                    for (const r of JSON.parse(text))
                        if (/^\d+$/.test(r.workspaceString) && r.monitor && r.enabled !== false)
                            map[Number(r.workspaceString)] = r.monitor;
                    root.rules = map;
                } catch (e) {
                    console.warn("Workspaces: bad workspacerules output", e);
                }
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded" && !readRules.running)
                readRules.running = true;
        }
    }

    spacing: 6

    Repeater {
        model: root.ids

        Item {
            id: cell

            required property int modelData
            readonly property HyprlandWorkspace ws: root.workspace(modelData)
            readonly property bool current: ws?.active ?? false
            readonly property bool occupied: (ws?.toplevels.values.length ?? 0) > 0
            readonly property bool urgent: ws?.urgent ?? false
            readonly property bool unused: !current && !occupied && !urgent

            width: 14
            height: Theme.barHeight

            Rectangle {
                anchors.centerIn: parent
                width: cell.unused ? 5 : 10
                height: width
                radius: width / 2
                readonly property color tint: cell.urgent ? Theme.crit
                    : cell.current ? (cell.ws.focused ? Theme.accent : Theme.fg)
                    : cell.occupied ? Theme.fg : Theme.muted
                color: cell.current || cell.unused ? tint : "transparent"
                opacity: cell.unused ? 0.6 : 1
                border.width: cell.current || cell.unused ? 0 : 1.5
                border.color: tint
                scale: mouse.containsMouse && !cell.current ? (cell.unused ? 1.4 : 1.2) : 1

                Behavior on width {
                    NumberAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing }
                }
                Behavior on scale {
                    NumberAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing }
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.goTo(cell.modelData)
            }
        }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => root.step(event.angleDelta.y < 0 ? 1 : -1)
    }
}
