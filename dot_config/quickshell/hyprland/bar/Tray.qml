import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs

// System tray, on the focused monitor's bar only so apps don't show twice.
// Left: activate (or menu for menu-only items). Middle: secondary action. Right: menu.
Row {
    id: root

    required property HyprlandMonitor monitor

    visible: monitor !== null && monitor === Hyprland.focusedMonitor
    spacing: Theme.spacing

    Repeater {
        model: SystemTray.items.values

        Item {
            id: cell

            required property SystemTrayItem modelData

            implicitWidth: Theme.iconSize
            implicitHeight: Theme.barHeight

            IconImage {
                anchors.centerIn: parent
                implicitSize: Theme.iconSize
                source: cell.modelData.icon
            }

            QsMenuAnchor {
                id: menu
                menu: cell.modelData.menu
                anchor.item: cell
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: event => {
                    const item = cell.modelData;
                    if (event.button === Qt.MiddleButton)
                        item.secondaryActivate();
                    else if (event.button === Qt.RightButton || item.onlyMenu) {
                        if (item.hasMenu)
                            menu.open();
                    } else
                        item.activate();
                }
                onWheel: event => cell.modelData.scroll(event.angleDelta.y / 120, false)
            }
        }
    }
}
