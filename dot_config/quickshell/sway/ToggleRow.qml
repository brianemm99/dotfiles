import QtQuick
import QtQuick.Layouts

// An icon, a label and an on/off switch. Bind `checked` to the real state and
// change it in `onToggled`.
RowLayout {
    id: root

    required property string icon
    // For glyphs that only exist in Font Awesome's brands font.
    property bool brandIcon: false
    required property string label
    property bool checked: false

    signal toggled

    spacing: 8

    Icon {
        Layout.preferredWidth: Theme.fontSize * 1.3
        text: root.icon
        font.family: root.brandIcon ? "Font Awesome 6 Brands" : Theme.iconFont
        font.weight: root.brandIcon ? Font.Normal : Font.Black
        color: root.checked ? Theme.accent : Theme.muted
    }

    BarText {
        Layout.fillWidth: true
        text: root.label
        color: root.checked ? Theme.fg : Theme.muted
    }

    Rectangle {
        implicitWidth: 34
        implicitHeight: 18
        radius: height / 2
        color: root.checked ? Theme.accent : Theme.border

        Rectangle {
            x: root.checked ? parent.width - width - 2 : 2
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            radius: 7
            color: root.checked ? Theme.bg : Theme.fg

            Behavior on x {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.toggled()
        }
    }
}
