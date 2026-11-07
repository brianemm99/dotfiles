pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Tailscale up/down. Runs as the user, which works once the user is tailscaled's operator:
//   sudo tailscale set --operator=$USER      (one time; see .chezmoidata/packages.yaml)
// No events; callers refresh() (the quick-settings panel polls while open).
Singleton {
    id: root

    property bool available: false      // CLI present and tailscaled answering
    property string state: ""           // BackendState: Running, Stopped, NeedsLogin, Starting …
    property string address: ""         // this machine's first tailnet IP
    property string error: ""           // last up/down failure, shown instead of the state
    readonly property bool running: state === "Running"

    function refresh() {
        if (!read.running && !write.running)
            read.running = true;
    }

    function set(on) {
        if (write.running)
            return;
        error = "";
        // `up` must restate the non-default operator setting, or tailscale refuses;
        // the timeout keeps it from waiting forever on a login URL
        write.command = on
            ? ["tailscale", "up", `--operator=${Quickshell.env("USER")}`, "--timeout=15s"]
            : ["tailscale", "down"];
        write.running = true;
    }

    Process {
        id: read
        command: ["tailscale", "status", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const s = JSON.parse(text);
                    root.available = true;
                    root.state = s.BackendState ?? "";
                    root.address = s.Self?.TailscaleIPs?.[0] ?? "";
                } catch (e) {
                    root.available = false;
                    root.state = "";
                }
            }
        }
    }

    Process {
        id: write
        stderr: StdioCollector {
            id: errors
        }
        // only a failed exit is an error; tailscale also prints warnings on success
        onExited: code => {
            const t = errors.text.trim();
            if (code !== 0)
                root.error = /access denied|operator|permission/i.test(t)
                    ? "Needs operator: sudo tailscale set --operator=$USER"
                    : (t.split("\n").pop() || `tailscale exited ${code}`);
            read.running = true;
        }
    }

    Component.onCompleted: refresh()
}
