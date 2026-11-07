pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications

// The notification daemon (org.freedesktop.Notifications) and the state the bar,
// toasts and history panel share. History keeps the newest 50 until Quickshell restarts.
Singleton {
    id: root

    readonly property int historyLimit: 50
    readonly property int defaultTimeout: 5000 // ms, when the app doesn't say

    // newest first
    readonly property var list: server.trackedNotifications.values.slice().reverse()
    property var toasts: []             // notifications currently shown as toasts
    property bool dnd: false            // do not disturb: no toasts, history still fills
    property int unread: 0              // arrived since the panel was last opened

    property bool panelOpen: false
    property ShellScreen panelScreen: null

    // arrival time by notification id; the protocol carries none
    property var times: ({})

    function openPanel(screen) {
        panelScreen = screen;
        panelOpen = true;
        unread = 0;
        toasts = [];
    }
    function closePanel() {
        if (panelOpen)
            closedAt = Date.now();
        panelOpen = false;
    }
    // A click on the bell while the panel is open first closes it (click outside), then
    // arrives here; without the guard that same click would open it again.
    property real closedAt: 0
    function togglePanel(screen) {
        if (panelOpen)
            closePanel();
        else if (Date.now() - closedAt > 300)
            openPanel(screen);
    }

    function hideToast(n) {
        toasts = toasts.filter(t => t !== n);
    }

    function clearAll() {
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
        toasts = [];
    }

    // run the default action if there is one; returns whether it did
    function activate(n) {
        const a = n.actions.find(a => a.identifier === "default");
        if (a)
            a.invoke();
        return !!a;
    }

    // ms a toast stays: the app's timeout, 5 s otherwise; 0 = until dismissed (critical)
    function timeoutOf(n) {
        if (n.urgency === NotificationUrgency.Critical)
            return 0;
        return n.expireTimeout > 0 ? n.expireTimeout * 1000 : defaultTimeout;
    }

    function age(n) {
        const t = times[n.id];
        if (!t)
            return "";
        const m = Math.floor((clock.date - t) / 60000);
        return m < 1 ? "now" : m < 60 ? `${m}m` : m < 1440 ? `${Math.floor(m / 60)}h` : Qt.formatDateTime(t, "d MMM");
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    NotificationServer {
        id: server

        keepOnReload: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            const t = Object.assign({}, root.times);
            t[n.id] = new Date();
            root.times = t;
            n.closed.connect(() => root.hideToast(n));

            const all = server.trackedNotifications.values;
            if (all.length > root.historyLimit)
                all.slice(0, all.length - root.historyLimit).forEach(old => old.dismiss());

            if (!root.panelOpen) {
                root.unread += 1;
                if (!root.dnd && !n.transient)
                    root.toasts = [n, ...root.toasts.filter(x => x.id !== n.id)].slice(0, 4);
            }
        }
    }

    // SUPER + N in hyprland.lua: qs ipc -c hyprland call notifications toggle
    IpcHandler {
        target: "notifications"

        function toggle(): void {
            const m = Hyprland.focusedMonitor;
            root.togglePanel(Quickshell.screens.find(s => s.name === m?.name) ?? Quickshell.screens[0]);
        }
    }
}
