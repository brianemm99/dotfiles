import QtQuick
import Quickshell
import qs
import qs.components
import qs.services

// Date and time, updated on the minute. Click opens the calendar on this bar's screen.
IconText {
    id: root

    required property ShellScreen screen

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: CalendarState.toggle(root.screen)
    }
}
