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
        anchors.rightMargin: 10
        spacing: 14

        Workspaces {
            output: root.screen?.name ?? ""
        }

        Item {
            Layout.fillWidth: true
        }

        Tray {
            bar: root
        }

        BarText {
            id: volume

            readonly property PwNode sink: Pipewire.defaultAudioSink

            visible: sink?.audio != null
            text: !visible ? "" : sink.audio.muted ? "vol mute" : `vol ${Math.round(sink.audio.volume * 100)}%`

            // Pipewire nodes must be tracked for their audio properties to be populated.
            PwObjectTracker {
                objects: [volume.sink]
            }

            MouseArea {
                anchors.fill: parent
                onClicked: volume.sink.audio.muted = !volume.sink.audio.muted
                onWheel: wheel => {
                    const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                    volume.sink.audio.volume = Math.max(0, Math.min(1, volume.sink.audio.volume + step));
                }
            }
        }

        BarText {
            readonly property var battery: UPower.displayDevice
            readonly property bool charging: battery.state === UPowerDeviceState.Charging
                || battery.state === UPowerDeviceState.FullyCharged

            visible: battery.isLaptopBattery
            text: `bat ${Math.round(battery.percentage * 100)}%${charging ? "+" : ""}`
            color: !charging && battery.percentage < 0.15 ? Theme.urgent : Theme.fg
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    BarText {
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
    }
}
