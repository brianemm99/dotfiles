import QtQuick

// Four rising signal-strength bars; unlit bars are dimmed.
Row {
    id: root

    property real strength: 0 // 0..1
    property bool connected: false

    readonly property int maxHeight: Theme.fontSize

    spacing: 2
    height: maxHeight

    Repeater {
        model: 4

        Rectangle {
            required property int index

            // The first bar is lit whenever connected, then one more per quarter.
            readonly property bool lit: root.connected && (index === 0 || root.strength > index / 4)

            y: root.maxHeight - height
            width: 3
            height: root.maxHeight * (index + 1) / 4
            radius: 1
            color: lit ? Theme.fg : Theme.border
        }
    }
}
