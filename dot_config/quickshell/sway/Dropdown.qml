import QtQuick

// A panel in the bar's colour that unrolls downward from the bar's bottom
// edge. Place it at the top of a window just below the bar.
Rectangle {
    id: root

    property bool open: false
    readonly property int padding: 3

    // 0 = closed, 1 = open. Keep the containing window mapped while this is
    // above 0 so closing animates too.
    property real progress: open ? 1 : 0
    Behavior on progress {
        NumberAnimation {
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    // Height when fully open.
    readonly property real fullHeight: content.implicitHeight + padding

    default property alias contents: content.data

    width: content.implicitWidth + padding * 2
    height: fullHeight * progress
    opacity: progress
    clip: true
    radius: Theme.radius
    color: Theme.bg

    // Squares off the top corners so it joins the bar seamlessly.
    Rectangle {
        width: parent.width
        height: Math.min(parent.height, Theme.radius)
        color: parent.color
    }

    Item {
        id: content
        x: root.padding
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }
}
