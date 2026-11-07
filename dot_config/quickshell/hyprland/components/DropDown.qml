import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs

// A drop-down below the bar, as a layer surface rather than an xdg popup, so a keybind can
// open it and it can take the keyboard. Animates in (Hyprland has no_anim on qs: layers),
// and asks to close (closeRequested) on Esc or a click outside.
// Place it with anchors/margins and size it with implicitWidth/implicitHeight. Children go
// inside a FocusScope over the rounded box; give the one that handles keys `focus: true`.
PanelWindow {
    id: win

    property bool open: false
    property string namespace: "qs:popup"
    signal closeRequested

    default property alias content: scope.data

    property real shown: open ? 1 : 0
    Behavior on shown {
        NumberAnimation { duration: Theme.animDuration; easing.type: Theme.animEasing }
    }

    visible: open || shown > 0

    // below the bar: the bar's exclusive zone pushes it down; it reserves nothing itself
    margins.top: 4
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.namespace: namespace
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onOpenChanged: if (open)
        scope.forceActiveFocus()

    HyprlandFocusGrab {
        windows: [win]
        active: win.open
        onCleared: win.closeRequested()
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.bg
        border.width: 1
        border.color: Theme.surface
        opacity: win.shown
        transform: Translate {
            y: -8 * (1 - win.shown) // drops in from the bar
        }

        FocusScope {
            id: scope
            anchors.fill: parent
            Keys.onEscapePressed: win.closeRequested()
        }
    }
}
