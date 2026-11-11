import QtQuick
import Quickshell
import qs
import qs.components
import qs.services

// Opens the power menu on this bar's screen.
IconText {
    id: root

    required property ShellScreen screen

    text: "\uf303"  // Arch logo (Nerd Font nf-linux-archlinux)
    color: mouse.containsMouse ? Theme.accent : Theme.fg

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Power.toggle(root.screen)
    }
}
