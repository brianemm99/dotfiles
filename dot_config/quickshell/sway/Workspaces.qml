import QtQuick
import QtQuick.Layouts
import Quickshell.I3

RowLayout {
    id: root

    // Sway output name this bar is on; only its workspaces are shown.
    required property string output

    // Workspaces 1..persistent are always shown, even when sway hasn't
    // created them yet.
    readonly property int persistent: 5

    spacing: 2

    component Button: Rectangle {
        id: button

        required property string name
        // null when the workspace doesn't exist (empty, unfocused).
        property I3Workspace workspace: null

        readonly property bool focused: workspace?.focused ?? false
        readonly property bool urgent: workspace?.urgent ?? false
        readonly property bool visibleElsewhere: (workspace?.active ?? false) && !focused

        implicitWidth: Math.max(Theme.barHeight - 6, label.implicitWidth + 14)
        implicitHeight: Theme.barHeight - 6
        radius: Theme.radius
        color: focused ? Theme.accent
            : urgent ? Theme.urgent
            : visibleElsewhere ? Theme.border
            : "transparent"

        BarText {
            id: label
            anchors.centerIn: parent
            text: button.name
            color: button.focused ? Theme.bg
                : button.workspace ? Theme.fg
                : Theme.muted
        }

        // Marks workspaces that exist but aren't shown on any output.
        Rectangle {
            visible: button.workspace !== null && !button.workspace.active && !button.urgent
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 2
            width: 4
            height: 2
            radius: 1
            color: Theme.fg
        }

        MouseArea {
            anchors.fill: parent
            onClicked: button.workspace
                ? button.workspace.activate()
                : I3.dispatch(`workspace number ${button.name}`)
        }
    }

    Repeater {
        model: root.persistent

        Button {
            required property int index

            name: String(index + 1)
            workspace: I3.workspaces.values.find(w => w.number === index + 1) ?? null
            // Hide if it currently lives on another output.
            visible: !workspace || workspace.monitor?.name === root.output
        }
    }

    Repeater {
        model: I3.workspaces

        Button {
            required property I3Workspace modelData

            name: modelData.name
            workspace: modelData
            visible: (modelData.number < 1 || modelData.number > root.persistent)
                && modelData.monitor?.name === root.output
        }
    }
}
