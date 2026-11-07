import QtQuick
import Quickshell.Bluetooth
import qs
import qs.components
import qs.services

// Bluetooth icon, crossed out and muted while off; accent when a device is connected.
// Tooltip: connected devices. Click opens bluetui (turn the adapter on in quick settings).
Item {
    id: root

    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property var connected: adapter?.devices.values.filter(d => d.connected) ?? []

    readonly property bool powered: adapter?.enabled ?? false

    implicitWidth: label.implicitWidth
    implicitHeight: Theme.barHeight

    IconText {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        text: !root.powered ? "\u{F00B2}"                       // bluetooth off
            : root.connected.length > 0 ? "\u{F00B1}"         // bluetooth connect
            : "\u{F00AF}"                                     // bluetooth
        color: !root.powered ? Theme.muted : root.connected.length > 0 ? Theme.accent : Theme.fg
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Launch.run("ghostty -e bluetui")
    }

    Tooltip {
        target: root
        shown: mouse.containsMouse
        text: !root.powered ? "Bluetooth off"
            : root.connected.length > 0
            ? root.connected.map(d => d.batteryAvailable ? `${d.name}  ${Math.round(d.battery * 100)}%` : d.name).join("\n")
            : "No devices connected"
    }
}
