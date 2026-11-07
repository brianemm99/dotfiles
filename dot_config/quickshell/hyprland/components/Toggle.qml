import QtQuick
import qs

// Quick-settings row: icon, label, one line of detail, and a switch on the right.
// The whole row is clickable.
Rectangle {
    id: row

    property string icon
    property string label
    property string detail
    property bool checked: false
    property bool enabled: true
    signal clicked

    implicitWidth: 308
    implicitHeight: 44
    radius: Theme.radius
    color: mouse.containsMouse && enabled ? Theme.surface : "transparent"
    opacity: enabled ? 1 : 0.45

    IconText {
        x: 10
        width: 22
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        text: row.icon
        font.pixelSize: 16
        color: row.checked ? Theme.accent : Theme.fg
    }

    Column {
        x: 44
        width: row.width - x - track.width - 22
        anchors.verticalCenter: parent.verticalCenter

        IconText {
            text: row.label
        }
        IconText {
            width: parent.width
            text: row.detail
            elide: Text.ElideRight
            font.pixelSize: Theme.fontSize - 2
            color: Theme.muted
            visible: text !== ""
        }
    }

    Rectangle {
        id: track
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        height: 20
        radius: 10
        color: row.checked ? Theme.accent : Qt.lighter(Theme.surface, 1.8)

        Behavior on color {
            ColorAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing }
        }

        Rectangle {
            y: 3
            x: row.checked ? parent.width - width - 3 : 3
            width: 14
            height: 14
            radius: 7
            color: row.checked ? Theme.accentText : Theme.fg

            Behavior on x {
                NumberAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        enabled: row.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.clicked()
    }
}
