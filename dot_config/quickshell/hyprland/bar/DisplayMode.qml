import QtQuick
import qs
import qs.components
import qs.services

// laptop / dual / external, accent while an override is set. Only with an external screen.
// The menu asks Hyprland for an override; the icon follows hypr-display.json, not the click.
Item {
    id: root

    visible: Display.hasExternal
    implicitWidth: label.implicitWidth
    implicitHeight: Theme.barHeight

    IconText {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        text: Display.mode === "dual" ? "\u{F037A}"       // monitor multiple
            : Display.mode === "external" ? "\u{F0379}"   // monitor
            : "\u{F0322}"                                 // laptop
        color: Display.override ? Theme.accent : Theme.fg
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: menu.toggle()
    }

    BarPopup {
        id: menu
        target: root

        MenuRow {
            text: "Auto"
            checked: Display.override === ""
            onClicked: {
                Display.setOverride("");
                menu.visible = false;
            }
        }
        MenuRow {
            text: "External only"
            checked: Display.override === "external"
            onClicked: {
                Display.setOverride("external");
                menu.visible = false;
            }
        }
    }
}
