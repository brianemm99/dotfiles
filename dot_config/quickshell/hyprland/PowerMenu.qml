import QtQuick
import Quickshell
import qs
import qs.components
import qs.services

// Power menu: a drop-down under ⏻ at the left end of the bar, on that bar's screen.
// SUPER + Escape opens it on the focused screen; open state in services/Power.
// Up/Down or Tab/Shift+Tab move, Enter or a click picks, Esc or a click outside closes.
// Reboot and Shut down ask for a second press. hypridle locks the session before any sleep.
DropDown {
    id: root

    readonly property var actions: [
        { label: "Sleep", icon: "\u{F04B2}", command: ["systemctl", "suspend"], confirm: false },
        { label: "Hibernate", icon: "\u{F0717}", command: ["systemctl", "hibernate"], confirm: false },
        { label: "Reboot", icon: "\u{F0709}", command: ["systemctl", "reboot"], confirm: true },
        { label: "Shut down", icon: "\u{F0425}", command: ["systemctl", "poweroff"], confirm: true },
    ]

    property int selected: 0
    property int armed: -1              // index waiting for its confirming second press

    function move(delta) {
        selected = (selected + delta + actions.length) % actions.length;
        armed = -1;
    }
    function pick(i) {
        const a = actions[i];
        if (a.confirm && armed !== i) {
            selected = i;
            armed = i;
            return;
        }
        Power.hide();
        Quickshell.execDetached(a.command);
    }

    open: Power.open
    screen: Power.screen
    namespace: "qs:power"
    onCloseRequested: Power.hide()
    onOpenChanged: if (open) {
        selected = 0;
        armed = -1;
    }

    // top-left, under ⏻
    anchors {
        top: true
        left: true
    }
    margins.left: Theme.barEdgePadding - 6
    implicitWidth: 220
    implicitHeight: list.implicitHeight + hint.implicitHeight + 24

    Item {
        anchors.fill: parent
        focus: true

        Keys.onUpPressed: root.move(-1)
        Keys.onDownPressed: root.move(1)
        Keys.onTabPressed: root.move(1)
        Keys.onBacktabPressed: root.move(-1)
        Keys.onReturnPressed: root.pick(root.selected)
        Keys.onEnterPressed: root.pick(root.selected)

        Column {
            id: list
            x: 8
            y: 8
            width: parent.width - 16
            spacing: 2

            Repeater {
                model: root.actions

                Rectangle {
                    id: row

                    required property var modelData
                    required property int index
                    readonly property bool current: index === root.selected
                    readonly property bool isArmed: index === root.armed

                    width: list.width
                    height: 36
                    radius: Theme.radius / 2
                    color: isArmed ? Theme.crit : current ? Theme.surface : "transparent"

                    Row {
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        IconText {
                            width: 20
                            horizontalAlignment: Text.AlignHCenter
                            text: row.modelData.icon
                            font.pixelSize: 16
                            color: row.isArmed ? Theme.accentText : row.current ? Theme.accent : Theme.fg
                        }
                        IconText {
                            text: row.isArmed ? `${row.modelData.label}? Press again` : row.modelData.label
                            color: row.isArmed ? Theme.accentText : row.current ? Theme.accent : Theme.fg
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: if (root.selected !== row.index) {
                            root.selected = row.index;
                            root.armed = -1;
                        }
                        onClicked: root.pick(row.index)
                    }
                }
            }
        }

        IconText {
            id: hint
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            text: "↑/↓ · Enter · Esc"
            font.pixelSize: Theme.fontSize - 2
            color: Theme.muted
        }
    }
}
