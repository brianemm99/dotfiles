import QtQuick
import QtQuick.Shapes
import qs

// Circular gauge: a track and an arc from 12 o'clock, clockwise, for pct (0..100).
// Accent normally, warn from 80 %, crit from 90 %. labelSize > 0 shows the percent inside;
// percentSign: false drops the % so three digits fit in a small ring.
Item {
    id: ring

    property real pct: 0
    property int ringSize: 18
    property real stroke: 3
    property int labelSize: 0
    property bool percentSign: true

    readonly property real shownPct: Math.max(0, Math.min(100, animated))
    property real animated: pct
    Behavior on animated {
        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
    }

    readonly property color tint: pct >= 90 ? Theme.crit : pct >= 80 ? Theme.warn : Theme.accent

    implicitWidth: ringSize
    implicitHeight: ringSize

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Qt.lighter(Theme.surface, 1.8)
            strokeWidth: ring.stroke
            fillColor: "transparent"

            PathAngleArc {
                centerX: ring.ringSize / 2
                centerY: ring.ringSize / 2
                radiusX: (ring.ringSize - ring.stroke) / 2
                radiusY: radiusX
                startAngle: -90
                sweepAngle: 360
            }
        }

        ShapePath {
            strokeColor: ring.tint
            strokeWidth: ring.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: ring.ringSize / 2
                centerY: ring.ringSize / 2
                radiusX: (ring.ringSize - ring.stroke) / 2
                radiusY: radiusX
                startAngle: -90
                sweepAngle: 360 * ring.shownPct / 100
            }
        }
    }

    IconText {
        anchors.centerIn: parent
        visible: ring.labelSize > 0
        text: `${Math.round(ring.pct)}${ring.percentSign ? "%" : ""}`
        font.pixelSize: ring.labelSize
        font.bold: true
    }
}
