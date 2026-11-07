import QtQuick
import Quickshell
import qs
import qs.components
import qs.services

// Bell: accent with a badge when something arrived since the panel was last opened,
// crossed out while do-not-disturb is on. Click opens the history panel on this screen.
Item {
    id: root

    required property ShellScreen screen

    implicitWidth: label.implicitWidth
    implicitHeight: Theme.barHeight

    IconText {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        text: Notifs.dnd ? "\u{F009B}"             // bell off
            : Notifs.unread > 0 ? "\u{F116B}"      // bell badge
            : "\u{F009A}"                          // bell
        color: Notifs.dnd ? Theme.muted
            : Notifs.panelOpen || Notifs.unread > 0 ? Theme.accent
            : Theme.fg
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Notifs.togglePanel(root.screen)
    }
}
