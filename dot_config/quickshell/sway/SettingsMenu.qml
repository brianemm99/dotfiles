import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire

// Dropdown with toggles for Wi-Fi, Bluetooth and airplane mode, and sliders
// for output volume, mic volume and screen brightness.
BarMenu {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    icon: "\uf013" // gear
    align: Qt.AlignRight

    // Pipewire nodes must be tracked for their audio properties to be populated.
    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    // Read with brightnessctl, which also sets it through logind without root.
    // sysfs doesn't notify on changes, so it's re-read while the menu is open
    // to pick up the brightness keys.
    QtObject {
        id: brightness

        property real value: 0
        property real pending: -1

        function set(value: real): void {
            brightness.value = value;
            brightness.pending = value;
            if (!apply.running)
                apply.start();
        }
    }

    Process {
        id: read
        command: ["brightnessctl", "--class=backlight", "--machine-readable"]
        stdout: StdioCollector {
            onStreamFinished: {
                // e.g. "amdgpu_bl1,backlight,27525,42%,65535"
                const [, , current, , max] = this.text.trim().split(",");
                if (!brightnessRow.pressed && brightness.pending < 0 && max > 0)
                    brightness.value = current / max;
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.open
        onTriggered: read.running = true
    }

    // Rate-limits brightnessctl while dragging.
    Timer {
        id: apply
        interval: 30
        onTriggered: {
            Quickshell.execDetached(["brightnessctl", "--class=backlight", "--quiet", "set",
                `${Math.round(brightness.pending * 100)}%`]);
            brightness.pending = -1;
        }
    }

    // Radios. Airplane mode (and Bluetooth) go through rfkill, which works
    // without root here; Bluetooth can't be powered on while rfkill blocks it.
    QtObject {
        id: radios

        readonly property bool wifi: Networking.wifiEnabled
        readonly property bool bluetooth: Bluetooth.defaultAdapter?.enabled ?? false
        readonly property bool airplane: !wifi && !bluetooth

        function setWifi(on: bool): void {
            if (on)
                Quickshell.execDetached(["rfkill", "unblock", "wlan"]);
            Networking.wifiEnabled = on;
        }

        function setBluetooth(on: bool): void {
            Quickshell.execDetached(on
                ? ["sh", "-c", "rfkill unblock bluetooth && sleep 1 && bluetoothctl power on"]
                : ["rfkill", "block", "bluetooth"]);
        }

        function setAirplane(on: bool): void {
            Quickshell.execDetached(["rfkill", on ? "block" : "unblock", "all"]);
            if (!on)
                Networking.wifiEnabled = true;
        }
    }

    Column {
        topPadding: 3
        leftPadding: 3
        rightPadding: 6
        bottomPadding: 3
        spacing: 2

        ToggleRow {
            width: volumeRow.width
            height: Theme.barHeight - 6
            icon: "\uf1eb" // wifi
            label: "Wi-Fi"
            checked: radios.wifi
            onToggled: radios.setWifi(!radios.wifi)
        }

        ToggleRow {
            width: volumeRow.width
            height: Theme.barHeight - 6
            icon: "\uf294" // bluetooth-b
            brandIcon: true
            label: "Bluetooth"
            checked: radios.bluetooth
            onToggled: radios.setBluetooth(!radios.bluetooth)
        }

        ToggleRow {
            width: volumeRow.width
            height: Theme.barHeight - 6
            icon: "\uf072" // plane
            label: "Airplane mode"
            checked: radios.airplane
            onToggled: radios.setAirplane(!radios.airplane)
        }

        Item {
            width: 1
            height: 4
        }

        Rectangle {
            width: volumeRow.width
            height: 1
            color: Theme.border
        }

        SettingRow {
            id: volumeRow

            readonly property var audio: root.sink?.audio ?? null

            icon: Theme.volumeIcon(value, dimmed)
            value: audio?.volume ?? 0
            dimmed: audio?.muted ?? true
            iconClickable: true
            onMoved: value => { if (audio) audio.volume = value; }
            onIconClicked: { if (audio) audio.muted = !audio.muted; }
        }

        SettingRow {
            readonly property var audio: root.source?.audio ?? null

            icon: dimmed ? "\uf131" : "\uf130" // microphone(-slash)
            value: audio?.volume ?? 0
            dimmed: audio?.muted ?? true
            iconClickable: true
            onMoved: value => { if (audio) audio.volume = value; }
            onIconClicked: { if (audio) audio.muted = !audio.muted; }
        }

        SettingRow {
            id: brightnessRow

            icon: "\uf185" // sun
            value: brightness.value
            // Never let the screen go fully dark.
            minimum: 0.01
            onMoved: value => brightness.set(value)
        }
    }
}
