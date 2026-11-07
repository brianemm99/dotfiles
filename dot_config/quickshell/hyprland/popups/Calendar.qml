import QtQuick
import Quickshell
import qs
import qs.components
import qs.services

// Month calendar, dropping from the clock (centered under the bar). SUPER + C or a clock click.
// Weeks start on Monday; today is an accent dot. Left/Right or scroll change the month,
// Up/Down the year, Home (or a click on the title) returns to today. No events.
DropDown {
    id: root

    readonly property int cell: 38
    readonly property int pad: 12

    property int year: 0
    property int month: 0               // 0..11

    readonly property date today: clock.date

    function goToday() {
        year = today.getFullYear();
        month = today.getMonth();
    }
    function shift(months) {
        const d = new Date(year, month + months, 1);
        year = d.getFullYear();
        month = d.getMonth();
    }

    // 6 weeks from the Monday on or before the 1st, so the grid never changes height
    readonly property var days: {
        const first = new Date(year, month, 1);
        const offset = (first.getDay() + 6) % 7;
        const out = [];
        for (let i = 0; i < 42; i++)
            out.push(new Date(year, month, 1 - offset + i));
        return out;
    }

    open: CalendarState.open
    screen: CalendarState.screen
    namespace: "qs:calendar"
    onCloseRequested: CalendarState.hide()
    onOpenChanged: if (open)
        goToday()

    // top only: the compositor centers it horizontally, right under the clock
    anchors.top: true
    implicitWidth: cell * 7 + pad * 2
    implicitHeight: body.implicitHeight + pad * 2

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    Item {
        anchors.fill: parent
        focus: true

        Keys.onLeftPressed: root.shift(-1)
        Keys.onRightPressed: root.shift(1)
        Keys.onUpPressed: root.shift(-12)
        Keys.onDownPressed: root.shift(12)
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Home) {
                root.goToday();
                event.accepted = true;
            }
        }

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => root.shift(event.angleDelta.y < 0 ? 1 : -1)
        }

        Column {
            id: body
            x: root.pad
            y: root.pad
            spacing: 6

            // ‹  November 2026  ›
            Item {
                width: root.cell * 7
                height: 30

                IconText {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\u{F0141}" // chevron left
                    color: prevArea.containsMouse ? Theme.accent : Theme.fg

                    MouseArea {
                        id: prevArea
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shift(-1)
                    }
                }

                IconText {
                    anchors.centerIn: parent
                    readonly property bool isCurrent: root.year === root.today.getFullYear() && root.month === root.today.getMonth()
                    text: `${Qt.locale().standaloneMonthName(root.month)} ${root.year}`
                    font.bold: true
                    color: titleArea.containsMouse && !isCurrent ? Theme.accent : Theme.fg

                    MouseArea {
                        id: titleArea
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: parent.isCurrent ? Qt.ArrowCursor : Qt.PointingHandCursor
                        onClicked: root.goToday()
                    }
                }

                IconText {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\u{F0142}" // chevron right
                    color: nextArea.containsMouse ? Theme.accent : Theme.fg

                    MouseArea {
                        id: nextArea
                        anchors.fill: parent
                        anchors.margins: -8
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.shift(1)
                    }
                }
            }

            // Mo Tu We Th Fr Sa Su
            Row {
                Repeater {
                    model: 7

                    IconText {
                        required property int index
                        width: root.cell
                        horizontalAlignment: Text.AlignHCenter
                        // Qt: 0 = Sunday … 6 = Saturday; start from Monday
                        text: Qt.locale().dayName((index + 1) % 7, Locale.ShortFormat).slice(0, 2)
                        font.pixelSize: Theme.fontSize - 2
                        color: index >= 5 ? Theme.muted : Theme.fg
                    }
                }
            }

            Grid {
                columns: 7

                Repeater {
                    model: root.days

                    Item {
                        id: day

                        required property date modelData
                        readonly property bool inMonth: modelData.getMonth() === root.month
                        readonly property bool isToday: modelData.getFullYear() === root.today.getFullYear()
                            && modelData.getMonth() === root.today.getMonth()
                            && modelData.getDate() === root.today.getDate()

                        width: root.cell
                        height: root.cell - 6

                        Rectangle {
                            anchors.centerIn: parent
                            width: 30
                            height: 30
                            radius: 15
                            color: Theme.accent
                            visible: day.isToday
                        }

                        IconText {
                            anchors.centerIn: parent
                            text: day.modelData.getDate()
                            font.bold: day.isToday
                            color: day.isToday ? Theme.accentText : day.inMonth ? Theme.fg : Qt.darker(Theme.muted, 1.4)
                        }
                    }
                }
            }
        }
    }
}
