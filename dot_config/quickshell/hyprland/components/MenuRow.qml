import QtQuick
import qs

// One choice in a BarPopup: check mark when selected, highlight on hover.
Rectangle {
    id: row

    property string text
    property bool checked: false
    signal clicked

    implicitWidth: Math.max(170, content.implicitWidth + 16)
    implicitHeight: 28
    radius: Theme.radius / 2
    color: mouse.containsMouse ? Theme.surface : "transparent"

    Row {
        id: content
        x: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        IconText {
            width: 14
            text: row.checked ? "\u{F012C}" : "" // check
            color: Theme.accent
        }
        IconText {
            text: row.text
            color: row.checked ? Theme.accent : Theme.fg
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked()
    }
}
