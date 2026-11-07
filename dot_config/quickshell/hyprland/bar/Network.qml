import QtQuick
import qs
import qs.components
import qs.services

// Wired, Wi-Fi strength, or disconnected, from iwd (services/Wifi). Tooltip: SSID.
// Wi-Fi on/off is in quick settings.
Item {
    id: root

    readonly property string icon: Wifi.wired ? "\u{F0200}"          // ethernet
        : !Wifi.available || !Wifi.powered ? "\u{F05AA}"              // wifi off
        : !Wifi.connected ? "\u{F092E}"                               // strength off outline
        : Wifi.signal >= -55 ? "\u{F0928}"                            // 4 bars
        : Wifi.signal >= -65 ? "\u{F0925}"
        : Wifi.signal >= -75 ? "\u{F0922}"
        : Wifi.signal >= -85 ? "\u{F091F}"
        : "\u{F092F}"                                                 // 0 bars

    implicitWidth: label.implicitWidth
    implicitHeight: Theme.barHeight

    IconText {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        color: Wifi.wired || Wifi.connected ? Theme.fg : Theme.muted
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
    }

    Tooltip {
        target: root
        shown: mouse.containsMouse
        text: {
            const wifi = Wifi.connected ? `${Wifi.ssid}  ${Wifi.signal} dBm`
                : !Wifi.available ? "iwd not running"
                : !Wifi.powered ? "Wi-Fi off"
                : Wifi.state === "disconnected" ? "Wi-Fi disconnected"
                : `Wi-Fi ${Wifi.state}`;
            return Wifi.wired ? `Wired\n${wifi}` : wifi;
        }
    }
}
