import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs

// One bar per screen; shell.qml's Variants creates and destroys it with the screen.
PanelWindow {
    id: bar

    required property ShellScreen modelData
    screen: modelData

    // Hyprland's view of this screen; null for a moment while a screen is added or removed.
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    exclusiveZone: Theme.barHeight
    color: Theme.bg

    WlrLayershell.namespace: "qs:bar"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Row {
        id: left
        anchors.left: parent.left
        anchors.leftMargin: Theme.barEdgePadding
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacing * 2.25 // ⏻ to workspaces

        PowerButton {
            screen: bar.screen
            anchors.verticalCenter: parent.verticalCenter
        }

        ResourceRings {
            screen: bar.screen
            anchors.verticalCenter: parent.verticalCenter
        }

        Workspaces {
            monitor: bar.monitor
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Clock {
        screen: bar.screen
        anchors.centerIn: parent
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: Theme.padding
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacing * 1.75

        Volume {}
        Network {}
        BluetoothIndicator {}
        DisplayMode {}
        NotificationBell {
            screen: bar.screen
        }
        QuickSettings {}
        Battery {}
        Tray {
            monitor: bar.monitor
        }
    }
}
