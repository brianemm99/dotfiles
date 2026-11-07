import QtQuick
import Quickshell.Services.UPower
import qs
import qs.components

// Laptop battery from UPower. Click: time left and the power profile.
Item {
    id: root

    readonly property UPowerDevice dev: UPower.displayDevice
    // Quickshell reports 0..1; guard in case a backend reports 0..100
    readonly property int percent: Math.round(dev.percentage <= 1 ? dev.percentage * 100 : dev.percentage)
    readonly property bool charging: dev.state === UPowerDeviceState.Charging
        || dev.state === UPowerDeviceState.PendingCharge
    readonly property bool full: dev.state === UPowerDeviceState.FullyCharged

    readonly property color tint: charging || full ? Theme.accent2
        : percent <= 10 ? Theme.crit
        : percent <= 20 ? Theme.warn
        : Theme.fg

    // battery_10 … battery_90 and the charging set; index 0..9 by tens, 100 % is "full"
    readonly property var levels: ["\u{F007A}", "\u{F007B}", "\u{F007C}", "\u{F007D}", "\u{F007E}",
        "\u{F007F}", "\u{F0080}", "\u{F0081}", "\u{F0082}", "\u{F0079}"]
    readonly property var chargingLevels: ["\u{F089C}", "\u{F0086}", "\u{F0087}", "\u{F0088}", "\u{F089D}",
        "\u{F0089}", "\u{F089E}", "\u{F008A}", "\u{F008B}", "\u{F0085}"]
    readonly property string icon: (charging || full ? chargingLevels : levels)[Math.max(0, Math.min(9, Math.ceil(percent / 10) - 1))]

    function duration(seconds) {
        const m = Math.round(seconds / 60);
        return m >= 60 ? `${Math.floor(m / 60)} h ${m % 60} min` : `${m} min`;
    }

    visible: dev.isLaptopBattery
    implicitWidth: label.implicitWidth
    implicitHeight: Theme.barHeight

    IconText {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        text: `${root.icon} ${root.percent}%`
        color: root.tint
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.toggle()
    }

    BarPopup {
        id: popup
        target: root

        IconText {
            text: root.full ? `${root.percent}%  full`
                : root.charging ? (root.dev.timeToFull > 0 ? `${root.percent}%  full in ${root.duration(root.dev.timeToFull)}` : `${root.percent}%  charging`)
                : root.dev.timeToEmpty > 0 ? `${root.percent}%  ${root.duration(root.dev.timeToEmpty)} left`
                : `${root.percent}%`
            color: root.tint
            bottomPadding: 6
        }

        IconText {
            text: "Power profile"
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 2
            leftPadding: 4
        }

        Repeater {
            model: [
                { name: "Power saver", profile: PowerProfile.PowerSaver },
                { name: "Balanced", profile: PowerProfile.Balanced },
                { name: "Performance", profile: PowerProfile.Performance },
            ].filter(p => p.profile !== PowerProfile.Performance || PowerProfiles.hasPerformanceProfile)

            MenuRow {
                required property var modelData
                text: modelData.name
                checked: PowerProfiles.profile === modelData.profile
                onClicked: PowerProfiles.profile = modelData.profile
            }
        }
    }
}
