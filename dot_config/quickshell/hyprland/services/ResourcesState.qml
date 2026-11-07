pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Open state of the resources drop-down (popups/Resources.qml), shared with the bar's rings.
// anchorX: where the rings sit on the bar, so the drop-down hangs right under them.
Singleton {
    id: root

    property bool open: false
    property ShellScreen screen: null
    property real anchorX: 48

    function show(screen, x) {
        root.screen = screen ?? Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
        if (x !== undefined)
            anchorX = x;
        open = true;
    }
    function hide() {
        if (open)
            closedAt = Date.now();
        open = false;
    }
    // a click on the rings while open first closes it (click outside); don't reopen on it
    property real closedAt: 0
    function toggle(screen, x) {
        if (open)
            hide();
        else if (Date.now() - closedAt > 300)
            show(screen, x);
    }

    // SUPER + I in hyprland.lua: qs ipc -c hyprland call resources toggle
    IpcHandler {
        target: "resources"

        function toggle(): void {
            root.toggle(null);
        }
    }
}
