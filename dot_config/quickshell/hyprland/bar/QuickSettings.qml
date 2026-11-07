import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import qs
import qs.components
import qs.services

// Quick settings: a drop-down from the bar, opened by clicking its icon (no keybind).
// Switches for Wi-Fi, Bluetooth, airplane mode, Tailscale and the charge limit; volume and brightness
// sliders; display mode.
Item {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property var btConnected: adapter?.devices.values.filter(d => d.connected) ?? []
    readonly property int contentWidth: 308

    implicitWidth: icon.implicitWidth
    implicitHeight: Theme.barHeight

    IconText {
        id: icon
        anchors.verticalCenter: parent.verticalCenter
        text: "\u{F0493}" // cog
        color: panel.visible ? Theme.accent : Theme.fg
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: panel.toggle()
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    BarPopup {
        id: panel
        target: root

        // hang from the icon's right edge and grow to the left, so it stays on screen
        anchor.edges: Edges.Bottom | Edges.Right
        anchor.gravity: Edges.Bottom | Edges.Left

        onVisibleChanged: if (visible) {
            Wifi.refresh();
            Radio.refresh();
            Brightness.refresh();
            ChargeLimit.refresh();
            Tailscale.refresh();
        }

        // brightness keys don't notify; follow them while open
        Timer {
            running: panel.visible
            interval: 1000
            repeat: true
            onTriggered: Brightness.refresh()
        }

        // tailscale has no events either
        Timer {
            running: panel.visible
            interval: 3000
            repeat: true
            onTriggered: Tailscale.refresh()
        }

        Column {
            width: root.contentWidth

            Toggle {
                icon: Wifi.powered && !Radio.wifiBlocked ? "\u{F05A9}" : "\u{F05AA}" // wifi / wifi off
                label: "Wi-Fi"
                detail: !Wifi.available ? "Unavailable"
                    : Radio.wifiBlocked || !Wifi.powered ? "Off"
                    : Wifi.connected ? Wifi.ssid
                    : "Not connected"
                enabled: Wifi.available
                checked: Wifi.powered && !Radio.wifiBlocked
                onClicked: Wifi.setPowered(!checked)
            }

            Toggle {
                icon: checked ? "\u{F00AF}" : "\u{F00B2}" // bluetooth / bluetooth off
                label: "Bluetooth"
                detail: !root.adapter ? "Unavailable"
                    : !checked ? "Off"
                    : root.btConnected.length > 0 ? root.btConnected.map(d => d.name).join(", ")
                    : "On"
                enabled: root.adapter !== null
                checked: (root.adapter?.enabled ?? false) && !Radio.bluetoothBlocked
                onClicked: {
                    if (checked)
                        root.adapter.enabled = false;
                    else
                        Quickshell.execDetached(["sh", "-c", "rfkill unblock bluetooth; sleep 0.5; bluetoothctl power on"]);
                }
            }

            Toggle {
                icon: "\u{F001D}" // airplane
                label: "Airplane"
                detail: checked ? "All radios off" : "Off"
                checked: Radio.airplane
                onClicked: Radio.setAirplane(!checked)
            }

            Toggle {
                icon: "\u{F0582}" // vpn
                label: "Tailscale"
                detail: !Tailscale.available ? "Unavailable"
                    : Tailscale.error ? Tailscale.error
                    : Tailscale.running ? Tailscale.address
                    : Tailscale.state === "NeedsLogin" ? "Needs login: sudo tailscale up"
                    : Tailscale.state === "Stopped" ? "Off"
                    : Tailscale.state
                enabled: Tailscale.available
                checked: Tailscale.running
                onClicked: Tailscale.set(!checked)
            }

            Toggle {
                icon: "\u{F0084}" // battery heart
                label: "Charge limit"
                detail: !ChargeLimit.available ? "Unavailable (sudoers rule missing?)" : `Max ${ChargeLimit.limit}%`
                enabled: ChargeLimit.available
                checked: ChargeLimit.enabled
                onClicked: ChargeLimit.set(!checked)
            }
        }

        Item {
            width: 1
            height: 8
        }

        // volume: icon toggles mute
        Row {
            spacing: 10
            visible: root.sink !== null

            readonly property real volume: root.sink?.audio?.volume ?? 0
            readonly property bool muted: root.sink?.audio?.muted ?? false

            IconText {
                width: 20
                anchors.verticalCenter: parent.verticalCenter
                text: parent.muted ? "\u{F075F}" : "\u{F057E}"
                font.pixelSize: 16
                color: parent.muted ? Theme.muted : Theme.fg

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
                }
            }
            Slider {
                width: root.contentWidth - 20 - 44 - 20
                anchors.verticalCenter: parent.verticalCenter
                value: parent.volume
                dimmed: parent.muted
                onMoved: v => {
                    if (root.sink?.audio)
                        root.sink.audio.volume = Math.round(v * 100) / 100;
                }
            }
            IconText {
                width: 44
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                text: `${Math.round(parent.volume * 100)}%`
                color: parent.muted ? Theme.muted : Theme.fg
            }
        }

        // brightness: laptop panel only, so hidden while it is off
        Row {
            spacing: 10
            visible: Brightness.available && Display.mode !== "external"

            IconText {
                width: 20
                anchors.verticalCenter: parent.verticalCenter
                text: "\u{F00DF}" // brightness 6
                font.pixelSize: 16
            }
            Slider {
                width: root.contentWidth - 20 - 44 - 20
                anchors.verticalCenter: parent.verticalCenter
                value: Brightness.value
                onMoved: v => Brightness.set(v)
            }
            IconText {
                width: 44
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                text: `${Math.round(Brightness.value * 100)}%`
            }
        }

        Item {
            width: 1
            height: 8
        }

        IconText {
            text: `Display  ·  ${Display.mode}`
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 2
            leftPadding: 4
            bottomPadding: 2
        }

        MenuRow {
            width: root.contentWidth
            visible: Display.hasExternal
            text: "Auto"
            checked: Display.override === ""
            onClicked: Display.setOverride("")
        }
        MenuRow {
            width: root.contentWidth
            visible: Display.hasExternal
            text: "External only"
            checked: Display.override === "external"
            onClicked: Display.setOverride("external")
        }
        MenuRow {
            width: root.contentWidth
            text: "Re-detect screens"
            onClicked: Display.redetect()
        }
    }
}
