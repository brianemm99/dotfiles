import QtQuick

// A rounded bar button: an icon, optionally followed by text.
Rectangle {
    id: root

    required property string icon
    // Optional text after the icon.
    property string label: ""
    // Longer labels scroll. 0 means no limit.
    property int maxLabelChars: 0
    property color iconColor: Theme.fg
    // Highlighted, e.g. while its menu is open.
    property bool active: false

    signal clicked

    implicitWidth: label ? row.implicitWidth + 14 : Theme.barHeight - 6
    implicitHeight: Theme.barHeight - 6
    radius: Theme.radius
    color: active ? Theme.accent : mouse.containsMouse ? Theme.border : "transparent"

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            text: root.icon
            color: root.active ? Theme.bg : root.iconColor
        }

        Marquee {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.label !== ""
            width: root.maxLabelChars > 0 ? Math.min(implicitWidth, limit.advanceWidth) : implicitWidth
            text: root.label
            color: root.active ? Theme.bg : Theme.fg

            // Width of the first maxLabelChars characters.
            TextMetrics {
                id: limit
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                text: root.label.slice(0, root.maxLabelChars)
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
