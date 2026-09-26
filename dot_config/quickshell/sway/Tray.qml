import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.SystemTray
import Quickshell.Widgets

RowLayout {
    id: root

    // The bar window, needed to position context menus.
    required property QsWindow bar
    // true: only the applets drawn as glyphs (network, bluetooth), in that
    // order. false: every other tray item.
    property bool applets: false

    spacing: 8

    // Tray items drawn as Font Awesome glyphs to match the rest of the bar,
    // keyed by item id. Clicking them still opens the applet's menu.
    readonly property var glyphs: ({
        "nm-applet": network,
        "blueman": bluetooth,
    })

    QtObject {
        id: network

        readonly property var devices: Networking.devices.values
        readonly property bool wired: devices.some(d => d.type === DeviceType.Wired && d.connected)
        readonly property bool wifi: devices.some(d => d.type === DeviceType.Wifi && d.connected)

        readonly property real strength: devices.find(d => d.type === DeviceType.Wifi && d.connected)
            ?.networks.values.find(n => n.connected)?.signalStrength ?? 0

        // Signal bars, unless on ethernet.
        readonly property bool bars: !wired
        readonly property string text: "\uf796" // ethernet
        readonly property string family: Theme.iconFont
        readonly property color color: Theme.fg
    }

    QtObject {
        id: bluetooth

        readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false
        readonly property bool connected: Bluetooth.devices.values.some(d => d.connected)

        readonly property string text: "\uf294" // bluetooth-b
        readonly property string family: "Font Awesome 6 Brands"
        readonly property color color: !enabled ? Theme.muted : connected ? Theme.accent : Theme.fg
    }

    Repeater {
        model: {
            const items = SystemTray.items.values;
            if (!root.applets)
                return items.filter(item => !(item.id in root.glyphs));
            return Object.keys(root.glyphs)
                .map(id => items.find(item => item.id === id))
                .filter(item => item);
        }

        MouseArea {
            id: item

            required property SystemTrayItem modelData
            readonly property var glyph: root.glyphs[modelData.id] ?? null

            implicitWidth: glyph?.bars ? wifiBars.implicitWidth : glyph ? icon.implicitWidth : 16
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
                visible: !item.glyph
                anchors.fill: parent
                source: item.modelData.icon
            }

            Icon {
                id: icon
                visible: item.glyph !== null && !item.glyph.bars
                anchors.centerIn: parent
                text: item.glyph?.text ?? ""
                color: item.glyph?.color ?? Theme.fg
                font.family: item.glyph?.family ?? Theme.iconFont
                // Brands only has a regular face.
                font.weight: item.glyph?.family === Theme.iconFont ? Font.Black : Font.Normal
            }

            WifiBars {
                id: wifiBars
                visible: item.glyph?.bars ?? false
                anchors.centerIn: parent
                strength: network.strength
                connected: network.wifi
            }
        }
    }
}
