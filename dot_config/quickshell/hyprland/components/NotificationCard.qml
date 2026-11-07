import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets
import qs
import qs.services

// One notification: icon, app and age, summary, body, action buttons, close.
// Clicking the card runs the default action. Used by toasts and the history panel.
Rectangle {
    id: card

    required property Notification notification
    property bool toast: false
    signal closeClicked                 // toast: hide it; history: dismiss it
    signal activated                    // an action ran (card click with a default action, or a button)
    readonly property bool hovered: mouse.containsMouse

    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property string iconSource: {
        const img = notification.image;
        if (img)
            return img.startsWith("/") ? `file://${img}` : img;
        const icon = notification.appIcon;
        if (!icon)
            return "";
        return icon.startsWith("/") ? `file://${icon}` : icon.includes("://") ? icon : Quickshell.iconPath(icon, true);
    }

    implicitWidth: 360
    implicitHeight: content.implicitHeight + 20
    radius: Theme.radius
    color: toast ? Theme.bg : mouse.containsMouse ? Qt.lighter(Theme.surface, 1.25) : Theme.surface
    border.width: critical ? 1 : toast ? 1 : 0
    border.color: critical ? Theme.crit : Theme.surface

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (Notifs.activate(card.notification)) card.activated()
    }

    Row {
        id: content
        x: 10
        y: 10
        width: parent.width - 20
        spacing: 10

        IconImage {
            visible: card.iconSource !== ""
            implicitSize: 36
            source: card.iconSource
            asynchronous: true
        }

        Column {
            width: parent.width - (card.iconSource !== "" ? 46 : 0)
            spacing: 2

            // app · age                                        ×
            Item {
                width: parent.width
                height: 18

                IconText {
                    anchors.left: parent.left
                    anchors.right: close.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: [card.notification.appName, Notifs.age(card.notification)].filter(s => s).join("  ·  ")
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSize - 2
                    color: Theme.muted
                }

                IconText {
                    id: close
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\u{F0156}" // close
                    color: closeArea.containsMouse ? Theme.fg : Theme.muted

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.closeClicked()
                    }
                }
            }

            IconText {
                width: parent.width
                text: card.notification.summary
                font.bold: true
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: card.critical ? Theme.crit : Theme.fg
            }

            IconText {
                width: parent.width
                visible: text !== ""
                text: card.notification.body
                textFormat: Text.StyledText // the subset of HTML the spec allows: b, i, u, a, img
                wrapMode: Text.Wrap
                maximumLineCount: card.toast ? 4 : 8
                elide: Text.ElideRight
                linkColor: Theme.accent
                onLinkActivated: link => Qt.openUrlExternally(link)
            }

            // buttons for every action except the default one (the card click runs that)
            Flow {
                width: parent.width
                spacing: 6
                topPadding: 4
                visible: buttons.count > 0

                Repeater {
                    id: buttons
                    model: card.notification.actions.filter(a => a.identifier !== "default" && a.text)

                    Rectangle {
                        required property NotificationAction modelData
                        implicitWidth: label.implicitWidth + 20
                        implicitHeight: 26
                        radius: Theme.radius / 2
                        color: buttonArea.containsMouse ? Theme.accent : Qt.lighter(Theme.surface, 1.6)

                        IconText {
                            id: label
                            anchors.centerIn: parent
                            text: parent.modelData.text
                            font.pixelSize: Theme.fontSize - 1
                            color: buttonArea.containsMouse ? Theme.accentText : Theme.fg
                        }

                        MouseArea {
                            id: buttonArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                parent.modelData.invoke();
                                card.activated();
                            }
                        }
                    }
                }
            }
        }
    }
}
