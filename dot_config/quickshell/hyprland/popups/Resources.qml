import QtQuick
import Quickshell
import qs
import qs.components
import qs.services

// Larger resources view, dropping from the bar's rings: storage, CPU, RAM, each a big ring
// with its percent and details. SUPER + I or a click on the rings. Esc or a click outside closes.
DropDown {
    id: root

    readonly property int rowH: 92
    readonly property int pad: 16

    open: ResourcesState.open
    screen: ResourcesState.screen
    namespace: "qs:resources"
    onCloseRequested: ResourcesState.hide()

    // top-left, its left edge a little before the rings
    anchors {
        top: true
        left: true
    }
    margins.left: Math.max(0, ResourcesState.anchorX - root.pad)
    implicitWidth: 290
    implicitHeight: rowH * 3 + pad * 2

    component MetricRow: Item {
        id: metric

        property string label
        property real pct
        property string detail

        width: parent.width
        height: root.rowH

        Ring {
            id: big
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            ringSize: 68
            stroke: 7
            labelSize: 17
            pct: metric.pct
        }

        Column {
            anchors.left: big.right
            anchors.leftMargin: 16
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            IconText {
                text: metric.label
            }
            IconText {
                width: parent.width
                text: metric.detail
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSize - 2
                color: Theme.muted
            }
        }
    }

    Item {
        anchors.fill: parent
        focus: true

        Column {
            x: root.pad
            y: root.pad
            width: parent.width - root.pad * 2

            MetricRow {
                label: "Storage"
                pct: Sysinfo.diskPct
                detail: `${Sysinfo.fmtBytes(Sysinfo.diskFree)} free\n${Sysinfo.fmtBytes(Sysinfo.diskUsed)} / ${Sysinfo.fmtBytes(Sysinfo.diskTotal)} · ${Sysinfo.diskMount}`
            }
            MetricRow {
                label: "CPU"
                pct: Sysinfo.cpuPct
                detail: (Sysinfo.cpuTemp > 0 ? `${Sysinfo.cpuTemp.toFixed(0)}°C · ` : "")
                    + `load ${Sysinfo.load1.toFixed(2)}` + (Sysinfo.cores > 0 ? ` / ${Sysinfo.cores}` : "")
            }
            MetricRow {
                label: "RAM"
                pct: Sysinfo.memPct
                detail: `${Sysinfo.fmtBytes(Sysinfo.memUsed)} / ${Sysinfo.fmtBytes(Sysinfo.memTotal)}`
            }
        }
    }
}
