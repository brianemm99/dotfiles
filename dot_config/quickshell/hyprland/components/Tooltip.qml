import QtQuick
import qs

// Hover text under a bar item. Set `shown` from the item's MouseArea.containsMouse.
BarPopup {
    id: tip

    property string text
    property bool shown: false

    interactive: false
    onShownChanged: shown ? delay.restart() : (delay.stop(), visible = false)

    Timer {
        id: delay
        interval: 400
        onTriggered: tip.visible = tip.text !== ""
    }

    IconText {
        text: tip.text
    }
}
