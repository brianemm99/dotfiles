pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Wi-Fi state straight from iwd over D-Bus (no NetworkManager), plus whether a wired link is up.
// `gdbus monitor` reports every iwd change, so the state updates at once; a slow poll keeps the
// signal strength and the wired link fresh, since neither comes from iwd signals.
Singleton {
    id: root

    property bool available: false      // iwd running with a Wi-Fi device
    property bool powered: false
    property string device: ""          // e.g. wlan0
    property string state: "disconnected" // iwd Station.State: connected, connecting, disconnected, roaming …
    property string ssid: ""
    property int signal: -100           // dBm
    property bool wired: false
    readonly property bool connected: state === "connected"

    property string devicePath: ""
    property string stationPath: ""
    property string networkPath: ""

    // Off is iwd's device power. On also lifts an rfkill block (airplane mode) first.
    function setPowered(on) {
        if (!devicePath)
            return;
        const set = `busctl --system set-property net.connman.iwd ${devicePath} net.connman.iwd.Device Powered b ${on}`;
        Quickshell.execDetached(["sh", "-c", on ? `rfkill unblock wlan; sleep 0.5; ${set}` : set]);
    }

    function refresh() {
        if (objects.running)
            again = true;
        else
            objects.running = true;
    }
    property bool again: false

    function parseObjects(text) {
        const nl = text.indexOf("\n");
        wired = text.slice(0, nl).trim() === "wired 1";

        let data = null;
        try {
            data = JSON.parse(text.slice(nl + 1)).data[0];
        } catch (e) {
            available = false;
            state = "disconnected";
            ssid = "";
            return;
        }

        // The first Wi-Fi device. Station exists only while the device is powered.
        for (const path in data) {
            const dev = data[path]["net.connman.iwd.Device"];
            if (!dev)
                continue;
            const st = data[path]["net.connman.iwd.Station"];
            available = true;
            devicePath = path;
            device = dev.Name?.data ?? "";
            powered = dev.Powered?.data ?? false;
            stationPath = st ? path : "";
            state = st?.State?.data ?? "disconnected";
            networkPath = st?.ConnectedNetwork?.data ?? "";
            ssid = networkPath ? (data[networkPath]?.["net.connman.iwd.Network"]?.Name?.data ?? "") : "";
            if (connected)
                strength.running = true;
            return;
        }
        available = false;
        state = "disconnected";
        ssid = "";
    }

    // wired: any non-wireless physical interface that is up; then every iwd object as JSON
    Process {
        id: objects
        command: ["sh", "-c", `
            wired=0
            for d in /sys/class/net/*; do
              [ -e "$d/device" ] || continue
              [ -e "$d/wireless" ] && continue
              [ "$(cat "$d/operstate")" = up ] && wired=1
            done
            echo "wired $wired"
            busctl --system --json=short call net.connman.iwd / org.freedesktop.DBus.ObjectManager GetManagedObjects 2>/dev/null
        `]
        stdout: StdioCollector {
            onStreamFinished: root.parseObjects(text)
        }
        onExited: if (root.again) {
            root.again = false;
            running = true;
        }
    }

    // signal of the connected network: GetOrderedNetworks returns [path, 100 * dBm] pairs
    Process {
        id: strength
        command: ["busctl", "--system", "--json=short", "call", "net.connman.iwd", root.stationPath,
            "net.connman.iwd.Station", "GetOrderedNetworks"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const hit = JSON.parse(text).data[0].find(n => n[0] === root.networkPath);
                    if (hit)
                        root.signal = Math.round(hit[1] / 100);
                } catch (e) {}
            }
        }
    }

    Process {
        id: monitor
        running: true
        command: ["gdbus", "monitor", "--system", "--dest", "net.connman.iwd"]
        stdout: SplitParser {
            onRead: debounce.restart()
        }
        onExited: restartMonitor.start() // iwd restarted or gdbus died
    }

    Timer {
        id: restartMonitor
        interval: 2000
        onTriggered: monitor.running = true
    }

    Timer {
        id: debounce
        interval: 300 // a scan fires dozens of signals
        onTriggered: root.refresh()
    }

    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
