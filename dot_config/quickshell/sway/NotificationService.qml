pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// The notification server. Notifications stay in `list` (the notification
// centre) until dismissed; `popups` are the ones currently shown as popups.
Singleton {
    id: root

    // Oldest first. Transient ones only ever show as popups.
    readonly property var list: server.trackedNotifications.values.filter(n => !isTransient(n))
    property var popups: []
    // Set by the notification centre; no popups while it's showing them all.
    property bool centerOpen: false
    // Do not disturb: only critical and transient notifications pop up.
    property bool dnd: false
    // Notification id -> Date it arrived.
    property var received: ({})

    function hidePopup(notif: Notification): void {
        root.popups = root.popups.filter(n => n !== notif);
    }

    function dismissAll(): void {
        for (const notif of [...root.list])
            notif.dismiss();
    }

    // Feedback like volume/brightness levels, which isn't kept in the centre.
    function isTransient(notif: Notification): bool {
        return notif.transient || !!notif.hints["x-canonical-private-synchronous"];
    }

    NotificationServer {
        id: server

        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            // Sway's volume/brightness keys tag their notifications with this hint;
            // replace the previous one instead of stacking a popup per keypress.
            const sync = notif.hints["x-canonical-private-synchronous"];
            if (sync) {
                for (const other of server.trackedNotifications.values) {
                    if (other.hints["x-canonical-private-synchronous"] === sync)
                        other.dismiss();
                }
            }
            notif.tracked = true;
            root.received[notif.id] = new Date();
            notif.closed.connect(() => root.hidePopup(notif));
            // Transient ones still pop up, since that's the only place they show.
            const critical = notif.urgency === NotificationUrgency.Critical;
            if (root.isTransient(notif) || (!root.centerOpen && (!root.dnd || critical)))
                root.popups = [...root.popups, notif];
        }
    }
}
