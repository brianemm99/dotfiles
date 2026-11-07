pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// rfkill soft blocks: airplane mode, and whether Wi-Fi / Bluetooth are blocked.
// `rfkill event` streams every change, so the state follows other tools too.
Singleton {
    id: root

    property bool wifiBlocked: false
    property bool bluetoothBlocked: false
    property bool airplane: false       // every radio soft-blocked

    function setAirplane(on) {
        Quickshell.execDetached(["rfkill", on ? "block" : "unblock", "all"]);
    }

    function refresh() {
        if (!list.running)
            list.running = true;
    }

    Process {
        id: list
        command: ["rfkill", "-J"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const devs = JSON.parse(text).rfkilldevices ?? [];
                    const blocked = type => devs.some(d => d.type === type && d.soft === "blocked");
                    root.wifiBlocked = blocked("wlan");
                    root.bluetoothBlocked = blocked("bluetooth");
                    root.airplane = devs.length > 0 && devs.every(d => d.soft === "blocked");
                } catch (e) {}
            }
        }
    }

    Process {
        id: events
        running: true
        command: ["rfkill", "event"]
        stdout: SplitParser {
            onRead: debounce.restart()
        }
        onExited: restart.start()
    }

    Timer {
        id: restart
        interval: 2000
        onTriggered: events.running = true
    }

    Timer {
        id: debounce
        interval: 150
        onTriggered: root.refresh()
    }
}
