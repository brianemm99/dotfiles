import QtQuick
import Quickshell
import qs
import qs.components
import qs.services

// Live rings on the bar: CPU, RAM (left to right), usage % inside. Storage is only in the drop-down. Click opens the larger
// resources drop-down right under them.
Item {
    id: root

    required property ShellScreen screen

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    component BarRing: Ring {
        ringSize: 24
        stroke: 2.5
        labelSize: 9
        percentSign: false
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        BarRing {
            pct: Sysinfo.cpuPct
        }
        BarRing {
            pct: Sysinfo.memPct
        }
    }

    // the whole cluster is one target
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: ResourcesState.toggle(root.screen, root.mapToItem(null, 0, 0).x)
    }
}
