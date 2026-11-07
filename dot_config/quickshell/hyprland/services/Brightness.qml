pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Laptop panel backlight through brightnessctl (works as the user via logind).
// The kernel sends no change events for the backlight, so callers refresh() when it may
// have changed: the quick-settings panel polls while open, the OSD after a brightness key.
Singleton {
    id: root

    property bool available: false
    property real value: 0              // 0..1

    function refresh() {
        if (!read.running)
            read.running = true;
    }

    // Drags send many values; only the newest waiting one is written.
    property int queued: -1
    function set(v) {
        value = Math.max(0.01, Math.min(1, v));
        queued = Math.round(value * 100);
        if (!write.running)
            flush();
    }
    function flush() {
        write.command = ["brightnessctl", "-c", "backlight", "-q", "-n2", "set", `${queued}%`];
        queued = -1;
        write.running = true;
    }

    // "amdgpu_bl1,backlight,15735,24%,65535"
    Process {
        id: read
        command: ["brightnessctl", "-c", "backlight", "-m", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                root.available = f.length >= 5 && Number(f[4]) > 0;
                if (root.available && !write.running && root.queued < 0)
                    root.value = Number(f[2]) / Number(f[4]);
            }
        }
    }

    Process {
        id: write
        onExited: root.queued >= 0 ? root.flush() : root.refresh()
    }

    Component.onCompleted: refresh()
}
