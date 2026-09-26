import QtQuick
import QtQuick.Layouts

// An icon, a slider and the slider's percentage. Bind `value` to the real
// setting and apply changes in `onMoved`.
RowLayout {
    id: root

    required property string icon
    property real value: 0 // 0..1
    // Dims the row, e.g. when muted.
    property bool dimmed: false
    property bool iconClickable: false
    // Lowest value the slider can be dragged to.
    property real minimum: 0

    readonly property bool pressed: drag.pressed
    readonly property color color: dimmed ? Theme.muted : Theme.fg

    signal moved(real value)
    signal iconClicked

    function move(value: real): void {
        root.moved(Math.max(root.minimum, Math.min(1, value)));
    }

    spacing: 6

    Rectangle {
        implicitWidth: Theme.barHeight - 6
        implicitHeight: Theme.barHeight - 6
        radius: Theme.radius
        color: root.iconClickable && iconArea.containsMouse ? Theme.border : "transparent"

        Icon {
            anchors.centerIn: parent
            text: root.icon
            color: root.color
        }

        MouseArea {
            id: iconArea
            anchors.fill: parent
            enabled: root.iconClickable
            hoverEnabled: true
            onClicked: root.iconClicked()
        }
    }

    Item {
        id: slider

        implicitWidth: 168
        implicitHeight: Theme.barHeight - 6

        Rectangle {
            id: track
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 5
            radius: 2.5
            color: Theme.border

            Rectangle {
                width: track.width * Math.min(1, root.value)
                height: parent.height
                radius: parent.radius
                color: root.dimmed ? Theme.muted : Theme.accent
            }
        }

        Rectangle {
            id: knob
            anchors.verticalCenter: parent.verticalCenter
            x: (slider.width - width) * Math.min(1, root.value)
            width: 14
            height: 14
            radius: 7
            color: root.color
        }

        MouseArea {
            id: drag

            function moveTo(x: real): void {
                root.move((x - knob.width / 2) / (slider.width - knob.width));
            }

            anchors.fill: parent
            preventStealing: true
            onPressed: mouse => moveTo(mouse.x)
            onPositionChanged: mouse => moveTo(mouse.x)
            onWheel: wheel => root.move(root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
        }
    }

    BarText {
        // Wide enough for "100%" so the slider doesn't shift.
        Layout.preferredWidth: widest.width
        horizontalAlignment: Text.AlignRight
        text: `${Math.round(root.value * 100)}%`
        color: root.color

        TextMetrics {
            id: widest
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            text: "100%"
        }
    }
}
