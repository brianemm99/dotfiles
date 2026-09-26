import QtQuick

// Single-line text that, when wider than `width`, pauses and then scrolls
// through to the start again, looping.
Item {
    id: root

    property string text
    property color color: Theme.fg
    property alias font: first.font

    readonly property bool overflowing: first.implicitWidth > width
    readonly property int gap: 40
    // Scroll speed, in pixels per second.
    readonly property int speed: 40

    implicitWidth: first.implicitWidth
    implicitHeight: first.implicitHeight
    clip: true

    onTextChanged: {
        row.x = 0;
        if (scroll.running)
            scroll.restart();
    }

    // Two copies, so the start of the text follows the end in.
    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.gap

        BarText {
            id: first
            text: root.text
            color: root.color
        }

        BarText {
            visible: root.overflowing
            text: root.text
            color: root.color
            font: first.font
        }
    }

    SequentialAnimation {
        id: scroll

        running: root.overflowing && root.visible
        loops: Animation.Infinite
        onRunningChanged: if (!running) row.x = 0

        PauseAnimation {
            duration: 2000
        }

        NumberAnimation {
            target: row
            property: "x"
            from: 0
            to: -(first.implicitWidth + root.gap)
            duration: (first.implicitWidth + root.gap) * 1000 / root.speed
        }
    }
}
