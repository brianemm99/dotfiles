import QtQuick
import Quickshell
import qs
import qs.components

// Date and time, updated on the minute. Click opens the calendar (build step 9).
IconText {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {} // step 9: open qs:calendar
    }
}
