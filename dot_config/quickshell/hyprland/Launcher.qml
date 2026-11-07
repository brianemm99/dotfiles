import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs
import qs.components
import qs.services

// App launcher, centered on the focused monitor. SUPER + R (IPC target "launcher").
// Type to filter; Up/Down or Tab/Shift+Tab move; Enter or a click launches; Esc or a click
// outside closes. With no query: pinned apps first, then the rest by launch count.
Scope {
    id: root

    // desktop entry ids, in display order
    readonly property var pinned: ["brave-browser", "spotify-launcher", "obsidian", "discord", "bluetui"]

    property bool open: false
    property string query: ""
    property int selected: 0

    readonly property var apps: DesktopEntries.applications.values.filter(e => !e.noDisplay)

    // 0 = no match. Name prefix > word prefix > substring > generic name/keywords > fuzzy.
    function score(e, q) {
        const name = e.name.toLowerCase();
        if (name.startsWith(q))
            return 100;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
            return 80;
        if (name.includes(q))
            return 60;
        const extra = [e.genericName, e.id, ...(e.keywords ?? [])].join(" ").toLowerCase();
        if (extra.includes(q))
            return 40;
        // every query letter in order in the name; tighter matches score higher
        let i = 0, gaps = 0, last = -1;
        for (const ch of q) {
            const at = name.indexOf(ch, last + 1);
            if (at < 0)
                return 0;
            if (last >= 0)
                gaps += at - last - 1;
            last = at;
            i++;
        }
        return Math.max(1, 30 - gaps);
    }

    readonly property var results: {
        const q = query.trim().toLowerCase();
        const uses = e => Launch.counts[e.id] ?? 0;
        const pin = e => {
            const i = pinned.indexOf(e.id);
            return i < 0 ? pinned.length : i;
        };
        if (!q)
            return apps.slice().sort((a, b) => pin(a) - pin(b) || uses(b) - uses(a) || a.name.localeCompare(b.name));
        return apps.map(e => ({ e, s: score(e, q) }))
            .filter(r => r.s > 0)
            .sort((a, b) => b.s - a.s || uses(b.e) - uses(a.e) || pin(a.e) - pin(b.e) || a.e.name.localeCompare(b.e.name))
            .map(r => r.e);
    }

    onResultsChanged: selected = 0

    function show() {
        query = "";
        selected = 0;
        open = true;
    }
    function hide() {
        open = false;
    }
    function move(delta) {
        const n = results.length;
        if (n > 0)
            selected = (selected + delta + n) % n;
    }
    function launch(e) {
        if (!e)
            return;
        Launch.entry(e);
        hide();
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.open ? root.hide() : root.show();
        }
    }

    PanelWindow {
        id: win

        // fade and grow in; kept mapped until the closing fade ends
        property real shown: root.open ? 1 : 0
        Behavior on shown {
            NumberAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing }
        }

        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
        visible: root.open || shown > 0

        // no anchors: the compositor centers it on the screen
        exclusionMode: ExclusionMode.Ignore
        implicitWidth: 560
        implicitHeight: box.height
        color: "transparent"

        WlrLayershell.namespace: "qs:launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        HyprlandFocusGrab {
            windows: [win]
            active: root.open
            onCleared: root.hide()
        }

        Rectangle {
            id: box

            readonly property int rowHeight: 48
            readonly property int maxRows: 8

            width: parent.width
            height: search.height + list.height + 30
            radius: Theme.radius
            color: Theme.bg
            border.width: 1
            border.color: Theme.surface
            opacity: win.shown
            scale: 0.96 + 0.04 * win.shown

            // search field
            Rectangle {
                id: search
                x: 10
                y: 10
                width: parent.width - 20
                height: 44
                radius: Theme.radius
                color: Theme.surface

                IconText {
                    id: glass
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\u{F0349}" // magnify
                    color: Theme.muted
                    font.pixelSize: 16
                }

                TextInput {
                    id: input
                    anchors.left: glass.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.fg
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize + 2
                    clip: true
                    focus: root.open
                    text: root.query
                    onTextEdited: root.query = text

                    IconText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text === ""
                        text: "Search apps"
                        color: Theme.muted
                        font.pixelSize: Theme.fontSize + 2
                    }

                    Keys.onEscapePressed: root.hide()
                    Keys.onReturnPressed: root.launch(root.results[root.selected])
                    Keys.onEnterPressed: root.launch(root.results[root.selected])
                    Keys.onDownPressed: root.move(1)
                    Keys.onUpPressed: root.move(-1)
                    Keys.onTabPressed: root.move(1)
                    Keys.onBacktabPressed: root.move(-1)
                }

                // re-focus the field each time the launcher opens
                Connections {
                    target: root
                    function onOpenChanged() {
                        if (root.open)
                            input.forceActiveFocus();
                    }
                }
            }

            ListView {
                id: list
                x: 10
                y: search.y + search.height + 10
                width: parent.width - 20
                height: Math.max(box.rowHeight, Math.min(count, box.maxRows) * box.rowHeight)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.results
                currentIndex: root.selected
                highlightMoveDuration: 0

                delegate: Rectangle {
                    id: row

                    required property DesktopEntry modelData
                    required property int index
                    readonly property bool current: index === root.selected
                    readonly property bool isPinned: root.pinned.includes(modelData.id)

                    width: list.width
                    height: box.rowHeight
                    radius: Theme.radius
                    color: current ? Theme.surface : "transparent"

                    IconImage {
                        id: appIcon
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        implicitSize: 28
                        source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                        asynchronous: true
                    }

                    Column {
                        anchors.left: appIcon.right
                        anchors.leftMargin: 12
                        anchors.right: pin.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter

                        IconText {
                            width: parent.width
                            text: row.modelData.name
                            elide: Text.ElideRight
                            color: row.current ? Theme.accent : Theme.fg
                        }
                        IconText {
                            width: parent.width
                            visible: text !== ""
                            text: row.modelData.genericName || row.modelData.comment
                            elide: Text.ElideRight
                            font.pixelSize: Theme.fontSize - 2
                            color: Theme.muted
                        }
                    }

                    IconText {
                        id: pin
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.isPinned ? "\u{F0403}" : "" // pin
                        color: Theme.muted
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selected = row.index
                        onClicked: root.launch(row.modelData)
                    }
                }

                IconText {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: "No matching apps"
                    color: Theme.muted
                }
            }
        }
    }
}
