import QtQuick
import Quickshell
import qs

// Small popup hanging below a bar item: menus (interactive) and tooltips (not).
// An interactive one takes the pointer grab, so a click anywhere else closes it.
PopupWindow {
    id: popup

    required property Item target
    property bool interactive: true
    default property alias content: column.data

    function toggle() {
        visible = !visible;
    }

    anchor.item: target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    grabFocus: interactive
    visible: false
    color: "transparent"

    implicitWidth: column.implicitWidth + Theme.padding * 2
    implicitHeight: column.implicitHeight + Theme.padding * 2 + gap

    readonly property int gap: 4

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: popup.gap
        radius: Theme.radius
        color: Theme.bg
        border.width: 1
        border.color: Theme.surface

        focus: popup.interactive
        Keys.onEscapePressed: popup.visible = false

        Column {
            id: column
            x: Theme.padding
            y: Theme.padding
            spacing: 2
        }
    }
}
