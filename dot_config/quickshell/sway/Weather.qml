import QtQuick
import QtQuick.Layouts

// Current temperature and conditions, with details and a 5 day forecast in
// the dropdown.
BarMenu {
    id: root

    readonly property var current: WeatherService.current

    icon: current ? WeatherService.icon(current.code, current.day) : "\uf0c2"
    label: current ? `${current.temp}°` : "--°"
    align: Qt.AlignHCenter

    ColumnLayout {
        spacing: 8

        // Current conditions
        RowLayout {
            Layout.topMargin: 6
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            spacing: 10
            visible: root.current !== null

            Icon {
                Layout.preferredWidth: Theme.fontSize * 2.6
                text: root.icon
                font.pixelSize: Theme.fontSize * 2
                color: Theme.accent
            }

            ColumnLayout {
                spacing: 0

                BarText {
                    text: root.current ? `${root.current.temp}°F  ${WeatherService.description(root.current.code)}` : ""
                    font.pixelSize: Theme.fontSize + 2
                }

                BarText {
                    text: root.current
                        ? `Feels ${root.current.feelsLike}°  ·  ${root.current.humidity}% humidity  ·  ${root.current.wind} mph`
                        : ""
                    color: Theme.muted
                }

                // Today's sunrise and sunset
                RowLayout {
                    readonly property var today: WeatherService.daily[0] ?? null

                    visible: today !== null
                    spacing: 5

                    Icon {
                        text: "\uf185" // sun
                        color: Theme.muted
                    }

                    BarText {
                        text: parent.today ? Qt.formatTime(parent.today.sunrise, "HH:mm") : ""
                        color: Theme.muted
                    }

                    Icon {
                        Layout.leftMargin: 8
                        text: "\uf186" // moon
                        color: Theme.muted
                    }

                    BarText {
                        text: parent.today ? Qt.formatTime(parent.today.sunset, "HH:mm") : ""
                        color: Theme.muted
                    }
                }
            }
        }

        BarText {
            Layout.margins: 8
            visible: root.current === null
            text: "Weather unavailable"
            color: Theme.muted
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            implicitHeight: 1
            color: Theme.border
            visible: WeatherService.daily.length > 0
        }

        // 5 day forecast: day, icon, rain chance, high, low
        ColumnLayout {
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            Layout.bottomMargin: 4
            spacing: 4

            Repeater {
                model: WeatherService.daily

                RowLayout {
                    id: day

                    required property var modelData
                    required property int index

                    spacing: 12

                    BarText {
                        Layout.preferredWidth: Theme.fontSize * 3.5
                        text: day.index === 0 ? "Today" : Qt.formatDate(day.modelData.date, "ddd")
                    }

                    Icon {
                        Layout.preferredWidth: Theme.fontSize * 1.6
                        text: WeatherService.icon(day.modelData.code, true)
                    }

                    BarText {
                        Layout.preferredWidth: Theme.fontSize * 2.8
                        horizontalAlignment: Text.AlignRight
                        text: `${day.modelData.precip}%`
                        color: Theme.muted
                    }

                    BarText {
                        Layout.preferredWidth: Theme.fontSize * 2.2
                        horizontalAlignment: Text.AlignRight
                        text: `${day.modelData.high}°`
                    }

                    BarText {
                        Layout.preferredWidth: Theme.fontSize * 2.2
                        horizontalAlignment: Text.AlignRight
                        text: `${day.modelData.low}°`
                        color: Theme.muted
                    }
                }
            }
        }
    }
}
