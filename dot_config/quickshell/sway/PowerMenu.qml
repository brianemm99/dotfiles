import QtQuick
import Quickshell

// Power button with an icon-only dropdown for sleep, reboot and shutdown.
BarMenu {
    id: root

    icon: ""

    component Action: Rectangle {
        id: action

        required property string icon
        property bool danger: false
        signal clicked

        width: root.width
        height: root.height
        radius: Theme.radius
        color: hover.containsMouse ? Theme.border : "transparent"

        Icon {
            anchors.centerIn: parent
            text: action.icon
            color: hover.containsMouse
                ? (action.danger ? Theme.urgent : Theme.accent)
                : Theme.fg
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                root.open = false;
                action.clicked();
            }
        }
    }

    Column {
        spacing: 2

        Action {
            icon: ""
            onClicked: Quickshell.execDetached(["systemctl", "suspend"])
        }

        Action {
            icon: ""
            danger: true
            onClicked: Quickshell.execDetached(["systemctl", "reboot"])
        }

        Action {
            icon: ""
            danger: true
            onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
        }
    }
}
