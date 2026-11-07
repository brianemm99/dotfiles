pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Battery max-charge limit on the Framework EC, via framework_tool.
// framework_tool needs root; system/etc/sudoers.d/framework-charge-limit allows exactly
// `--charge-limit`, `--charge-limit 70` and `--charge-limit 100` without a password.
Singleton {
    id: root

    readonly property int limitWhenOn: 70   // must match the sudoers rule
    property int limit: 0               // current max %, 0 = unknown
    property bool available: false      // sudo rule installed and the EC answered
    readonly property bool enabled: limit > 0 && limit < 100

    function refresh() {
        if (!read.running && !write.running)
            read.running = true;
    }

    function set(on) {
        if (write.running)
            return;
        write.command = ["sudo", "-n", "/usr/bin/framework_tool", "--charge-limit", String(on ? limitWhenOn : 100)];
        write.running = true;
    }

    Process {
        id: read
        command: ["sudo", "-n", "/usr/bin/framework_tool", "--charge-limit"]
        stdout: StdioCollector {
            onStreamFinished: {
                // prefer a number labelled "max…", else the last percentage printed
                const max = text.match(/max\D*?(\d+)\s*%/i);
                const all = text.match(/\d+\s*%/g) ?? []; // no matchAll in Qt's JS engine
                const n = max ? Number(max[1]) : all.length ? parseInt(all[all.length - 1]) : 0;
                root.available = n > 0 && n <= 100;
                root.limit = root.available ? n : 0;
            }
        }
    }

    Process {
        id: write
        onExited: read.running = true
    }

    Component.onCompleted: refresh()
}
