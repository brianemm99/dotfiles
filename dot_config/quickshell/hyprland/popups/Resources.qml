import QtQuick
import Quickshell
import qs
import qs.components
import qs.services

// Larger resources view, dropping from the bar's rings: CPU and RAM, each a big ring with its
// percent and details, then a thin bar per volume (/, /home, /container) at the bottom. SUPER + I or a click on the rings. Esc or a click outside closes.
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
    implicitHeight: body.implicitHeight + pad * 2

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

    component VolumeRow: Column {
        id: vol

        property string mount
        property real pct
        property string detail
        readonly property color tint: pct >= 90 ? Theme.crit : pct >= 80 ? Theme.warn : Theme.accent

        width: parent.width
        spacing: 4

        Item {
            width: parent.width
            height: name.implicitHeight

            IconText {
                id: name
                text: vol.mount
            }
            IconText {
                anchors.right: parent.right
                text: `${Math.round(vol.pct)}%`
                font.pixelSize: Theme.fontSize - 1
                color: vol.pct >= 80 ? vol.tint : Theme.muted
            }
        }
        Rectangle {
            width: parent.width
            height: 6
            radius: 3
            color: Qt.lighter(Theme.surface, 1.8)   // same track as the rings

            Rectangle {
                width: Math.max(parent.height, parent.width * Math.min(100, vol.pct) / 100)
                height: parent.height
                radius: parent.radius
                color: vol.tint
                Behavior on width {
                    NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                }
            }
        }
        IconText {
            text: vol.detail
            font.pixelSize: Theme.fontSize - 2
            color: Theme.muted
        }
    }

    Item {
        anchors.fill: parent
        focus: true

        Column {
            id: body
            x: root.pad
            y: root.pad
            width: parent.width - root.pad * 2

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

            // storage: a thin bar per volume
            Rectangle {
                width: parent.width
                height: 1
                color: Theme.surface
            }
            Item {
                width: 1
                height: 12
            }
            Column {
                width: parent.width
                spacing: 12

                Repeater {
                    model: Sysinfo.volumes

                    VolumeRow {
                        required property var modelData
                        mount: modelData.mount
                        pct: modelData.pct
                        detail: `${Sysinfo.fmtBytes(modelData.used)} / ${Sysinfo.fmtBytes(modelData.total)} · ${Sysinfo.fmtBytes(modelData.free)} free`
                    }
                }
            }
        }
    }
}
