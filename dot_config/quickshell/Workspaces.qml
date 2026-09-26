import QtQuick
import QtQuick.Layouts
import Quickshell.I3

RowLayout {
    id: root

    // Sway output name this bar is on; only its workspaces are shown.
    required property string output

    spacing: 2

    Repeater {
        model: I3.workspaces

        Rectangle {
            id: ws

            required property I3Workspace modelData

            visible: modelData.monitor?.name === root.output
            implicitWidth: Math.max(Theme.barHeight - 6, label.implicitWidth + 14)
            implicitHeight: Theme.barHeight - 6
            radius: Theme.radius
            color: modelData.focused ? Theme.accent
                : modelData.urgent ? Theme.urgent
                : modelData.active ? Theme.border
                : "transparent"

            BarText {
                id: label
                anchors.centerIn: parent
                text: ws.modelData.name
                color: ws.modelData.focused ? Theme.bg : Theme.fg
            }

            MouseArea {
                anchors.fill: parent
                onClicked: ws.modelData.activate()
            }
        }
    }
}
