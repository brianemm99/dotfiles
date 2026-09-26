import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

// Popups in the top right. When one times out it stays in the notification
// centre, unless it's transient (e.g. volume feedback), which just expires.
Scope {
    PanelWindow {
        anchors {
            top: true
            right: true
        }
        margins {
            top: 8
            right: 8
        }
        exclusiveZone: 0
        implicitWidth: 380
        implicitHeight: popups.implicitHeight
        color: "transparent"
        visible: NotificationService.popups.length > 0

        ColumnLayout {
            id: popups
            width: parent.width
            spacing: 8

            Repeater {
                model: NotificationService.popups

                NotificationCard {
                    id: card

                    // -1 (or unset) means "server default"; 0 means never expire.
                    readonly property int timeout: modelData.expireTimeout > 0 ? modelData.expireTimeout
                        : modelData.expireTimeout === 0 || critical ? 0 : 5000

                    Layout.fillWidth: true

                    Timer {
                        running: card.timeout > 0 && !card.hovered
                        // Cards are recreated whenever the popup list changes, so count
                        // from arrival rather than from creation.
                        interval: Math.max(1, card.timeout - (Date.now() - NotificationService.received[card.modelData.id]))
                        onTriggered: {
                            if (NotificationService.isTransient(card.modelData))
                                card.modelData.expire();
                            else
                                NotificationService.hidePopup(card.modelData);
                        }
                    }
                }
            }
        }
    }
}
