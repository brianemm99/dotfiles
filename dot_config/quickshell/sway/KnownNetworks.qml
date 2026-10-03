pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Networks connected to before, so nm-applet's "Connection Established"
// notification only shows for new ones. Kept in the shell's state directory;
// the first time, it's seeded with the Wi-Fi networks NetworkManager has saved.
Singleton {
    id: root

    // True if this is nm-applet announcing a network seen before. Otherwise
    // remembers the network (if it is one) and returns false.
    function isRepeat(notif: Notification): bool {
        if (notif.summary !== "Connection Established" || !notif.body.startsWith("You are now connected to"))
            return false;
        // e.g. You are now connected to the Wi-Fi network “Home”.
        // Ethernet and mobile broadband messages carry no name; key them by the message.
        const network = notif.body.match(/“(.+)”/)?.[1] ?? notif.body;
        if (known.networks.includes(network))
            return true;
        known.networks = [...known.networks, network];
        return false;
    }

    FileView {
        id: file

        path: Quickshell.statePath("known-networks.json")
        // Loaded before the first notification can arrive at login.
        blockLoading: true
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                seed.running = true;
        }

        JsonAdapter {
            id: known
            property list<string> networks: []
        }
    }

    // Saved Wi-Fi profiles' network names, one per line.
    Process {
        id: seed
        command: ["sh", "-c", `
            nmcli -g UUID,TYPE connection show | while IFS=: read -r uuid type; do
                [ "$type" = 802-11-wireless ] && nmcli -g 802-11-wireless.ssid connection show "$uuid"
            done`]
        stdout: StdioCollector {
            onStreamFinished: {
                // nmcli's terse output backslash-escapes ":" and "\".
                const saved = this.text.split("\n").filter(line => line).map(line => line.replace(/\\(.)/g, "$1"))
                    .filter(ssid => !known.networks.includes(ssid));
                known.networks = [...known.networks, ...saved];
            }
        }
    }
}
