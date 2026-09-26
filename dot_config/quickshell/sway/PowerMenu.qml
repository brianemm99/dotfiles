import QtQuick
import Quickshell

// Power button with an icon-only dropdown for sleep, reboot and shutdown.
BarMenu {
    id: root

    readonly property list<var> actions: [
        { icon: "\uf186", command: ["systemctl", "suspend"], danger: false },
        { icon: "\uf2f9", command: ["systemctl", "reboot"], danger: true },
        { icon: "\uf011", command: ["systemctl", "poweroff"], danger: true },
    ]

    function run(command: list<string>): void {
        root.open = false;
        Quickshell.execDetached(command);
    }

    icon: "\uf011"

    Column {
        spacing: 2

        Repeater {
            model: root.actions

            Rectangle {
                id: action

                required property var modelData

                width: root.width
                height: root.height
                radius: Theme.radius
                color: hover.containsMouse ? Theme.border : "transparent"

                Icon {
                    anchors.centerIn: parent
                    text: action.modelData.icon
                    color: hover.containsMouse
                        ? (action.modelData.danger ? Theme.urgent : Theme.accent)
                        : Theme.fg
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.run(action.modelData.command)
                }
            }
        }
    }
}
