import QtQuick
import qs
import qs.components

// Opens the power menu. Stub until PowerMenu.qml exists (build step 8).
IconText {
    text: "⏻"
    color: mouse.containsMouse ? Theme.accent : Theme.fg

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {} // step 8: open qs:power
    }
}
