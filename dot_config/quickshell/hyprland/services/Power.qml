pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Open state of the power menu (PowerMenu.qml), shared with the ⏻ button on the bar.
Singleton {
    id: root

    property bool open: false
    property ShellScreen screen: null

    function show(screen) {
        root.screen = screen ?? Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
        open = true;
    }
    function hide() {
        if (open)
            closedAt = Date.now();
        open = false;
    }
    // A click on ⏻ while the menu is open first closes it (click outside), then arrives
    // here; without the guard that same click would open it again.
    property real closedAt: 0
    function toggle(screen) {
        if (open)
            hide();
        else if (Date.now() - closedAt > 300)
            show(screen);
    }

    // SUPER + Escape in hyprland.lua: qs ipc -c hyprland call power toggle
    IpcHandler {
        target: "power"

        function toggle(): void {
            root.toggle(null);
        }
    }
}
