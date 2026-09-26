import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

RowLayout {
    id: root

    // The bar window, needed to position context menus.
    required property QsWindow bar

    spacing: 8

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: item

            required property SystemTrayItem modelData

            implicitWidth: 16
            implicitHeight: 16
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton && !modelData.onlyMenu) {
                    modelData.activate();
                } else if (mouse.button === Qt.MiddleButton) {
                    modelData.secondaryActivate();
                } else if (modelData.hasMenu) {
                    const pos = item.mapToItem(null, 0, 0);
                    modelData.display(root.bar, pos.x, root.bar.height);
                }
            }
            onWheel: wheel => modelData.scroll(wheel.angleDelta.y, false)

            IconImage {
                anchors.fill: parent
                source: item.modelData.icon
            }
        }
    }
}
