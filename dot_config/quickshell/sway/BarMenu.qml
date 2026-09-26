import QtQuick
import Quickshell
import Quickshell.Wayland

// An icon button for the bar that opens a Dropdown below it. Children are
// placed in the dropdown.
Item {
    id: root

    // The bar window; the dropdown opens on its screen, below it.
    required property PanelWindow bar
    required property string icon
    // Optional text after the icon.
    property string label: ""
    // Longer labels scroll. 0 means no limit.
    property int maxLabelChars: 0
    property color iconColor: Theme.fg

    // Which edge of the button the dropdown lines up with:
    // Qt.AlignLeft, Qt.AlignRight or Qt.AlignHCenter.
    property int align: Qt.AlignLeft

    property bool open: false

    default property alias contents: dropdown.contents

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight

    BarButton {
        id: button
        anchors.fill: parent
        icon: root.icon
        label: root.label
        maxLabelChars: root.maxLabelChars
        iconColor: root.iconColor
        active: root.open
        onClicked: root.open = !root.open
    }

    // Full-screen and transparent so clicks outside the dropdown (and Escape)
    // close it; sway has no popup focus grab.
    PanelWindow {
        screen: root.bar.screen
        visible: root.open || dropdown.progress > 0
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell-menu"

        onVisibleChanged: {
            if (visible)
                dropdown.forceActiveFocus();
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }

        Dropdown {
            id: dropdown

            open: root.open
            x: {
                // mapToItem isn't reactive; these re-run it when the bar lays out.
                root.x, root.bar.width;
                const x = root.mapToItem(null, 0, 0).x;
                return root.align === Qt.AlignRight ? x + root.width + padding - width
                    : root.align === Qt.AlignHCenter ? x + (root.width - width) / 2
                    : x - padding;
            }
            y: Theme.barHeight

            Keys.onEscapePressed: root.open = false
        }
    }
}
