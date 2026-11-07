import QtQuick
import qs

// Horizontal 0..1 slider. `value` is what the service reports; `moved` asks for a change.
// While dragging it shows the drag position, so a slow service doesn't make it jump back.
Item {
    id: slider

    property real value: 0
    property bool dimmed: false         // e.g. muted: drawn in muted colours
    signal moved(real value)

    readonly property real shown: area.pressed ? dragValue : Math.max(0, Math.min(1, value))
    property real dragValue: 0

    implicitWidth: 200
    implicitHeight: 20

    function at(x) {
        return Math.max(0, Math.min(1, x / width));
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.surface

        Rectangle {
            width: slider.shown * parent.width
            height: parent.height
            radius: parent.radius
            color: slider.dimmed ? Theme.muted : Theme.accent
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: slider.shown * (slider.width - width)
        width: 14
        height: 14
        radius: 7
        color: slider.dimmed ? Theme.muted : Theme.fg
    }

    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: event => {
            slider.dragValue = slider.at(event.x);
            slider.moved(slider.dragValue);
        }
        onPositionChanged: event => {
            if (!pressed)
                return;
            slider.dragValue = slider.at(event.x);
            slider.moved(slider.dragValue);
        }
        onWheel: event => slider.moved(Math.max(0, Math.min(1, slider.value + (event.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
