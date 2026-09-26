import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight
    color: Theme.bg

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        spacing: 14

        PowerMenu {
            bar: root
        }

        Workspaces {
            output: root.screen?.name ?? ""
        }

        Item {
            Layout.fillWidth: true
        }

        MouseArea {
            id: volume

            readonly property PwNode sink: Pipewire.defaultAudioSink
            readonly property bool muted: sink?.audio?.muted ?? false
            readonly property real level: sink?.audio?.volume ?? 0
            readonly property color color: muted ? Theme.muted : Theme.fg

            visible: sink?.audio != null
            implicitWidth: volumeRow.implicitWidth
            implicitHeight: volumeRow.implicitHeight

            onClicked: sink.audio.muted = !sink.audio.muted
            onWheel: wheel => {
                const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + step));
            }

            // Pipewire nodes must be tracked for their audio properties to be populated.
            PwObjectTracker {
                objects: [volume.sink]
            }

            RowLayout {
                id: volumeRow
                anchors.fill: parent
                spacing: 5

                Icon {
                    // Fixed width so the percentage doesn't shift as the glyph changes.
                    Layout.preferredWidth: Theme.fontSize * 1.3
                    horizontalAlignment: Text.AlignLeft
                    text: Theme.volumeIcon(volume.level, volume.muted)
                    color: volume.color
                }

                BarText {
                    text: `${Math.round(volume.level * 100)}%`
                    color: volume.color
                }
            }
        }

        Tray {
            bar: root
            applets: true
        }

        RowLayout {
            id: battery

            readonly property var device: UPower.displayDevice
            readonly property bool charging: device.state === UPowerDeviceState.Charging
                || device.state === UPowerDeviceState.FullyCharged
            readonly property color color: !charging && device.percentage < 0.15 ? Theme.urgent : Theme.fg

            visible: device.isLaptopBattery
            spacing: 5

            Icon {
                // battery-empty .. battery-full, or a bolt while charging
                text: battery.charging ? "\uf0e7"
                    : ["\uf244", "\uf243", "\uf242", "\uf241", "\uf240"][Math.round(battery.device.percentage * 4)]
                color: battery.color
            }

            BarText {
                text: `${Math.round(battery.device.percentage * 100)}%`
                color: battery.color
            }
        }

        NotificationCenter {
            bar: root
        }

        SettingsMenu {
            bar: root
        }

        Tray {
            // Tray glyphs have no padding of their own, unlike the menu buttons.
            Layout.rightMargin: 6
            bar: root
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // The date drops down below the time on hover.
    BarText {
        id: time

        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "HH:mm")

        HoverHandler {
            id: timeHover
        }
    }

    // Anchored to the time rather than laid out with it, so the clock stays centred.
    Weather {
        bar: root
        anchors.right: time.left
        anchors.rightMargin: 10
        anchors.verticalCenter: time.verticalCenter
    }

    MediaPlayer {
        bar: root
        anchors.left: time.right
        anchors.leftMargin: 10
        anchors.verticalCenter: time.verticalCenter
    }

    PopupWindow {
        anchor.window: root
        anchor.rect.x: time.x + (time.width - width) / 2
        anchor.rect.y: root.height
        // Sized for the fully open dropdown so the window never resizes mid-animation.
        implicitWidth: date.width
        implicitHeight: date.fullHeight
        visible: timeHover.hovered || date.progress > 0
        color: "transparent"

        Dropdown {
            id: date

            open: timeHover.hovered

            BarText {
                leftPadding: 8
                rightPadding: 8
                height: Theme.barHeight - 6
                text: Qt.formatDateTime(clock.date, "ddd d MMM")
            }
        }
    }
}
