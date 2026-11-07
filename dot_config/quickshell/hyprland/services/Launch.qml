pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Starts apps through Hyprland, never as Quickshell's children: anything Quickshell spawns
// lives in quickshell.service's cgroup and dies when Quickshell restarts.
// hyprctl itself exits at once, so nothing is left behind.
// Also counts launches per desktop entry, for the launcher's ordering.
Singleton {
    id: root

    readonly property string terminal: "ghostty -e"
    readonly property string countsPath: Quickshell.env("HOME") + "/.local/state/quickshell/launches.json"
    property var counts: ({})          // desktop entry id -> launches

    // command: a shell command line, e.g. "ghostty -e bluetui"
    function run(command) {
        const lua = command.replace(/\\/g, "\\\\").replace(/"/g, "\\\"");
        Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.exec_cmd("${lua}")`]);
    }

    // a DesktopEntry: its parsed command, shell-quoted, field codes (%u, %F …) dropped
    function entry(e) {
        const quote = a => /^[\w@%+=:,./-]+$/.test(a) ? a : `'${a.replace(/'/g, "'\\''")}'`;
        const args = e.command.filter(a => !/^%[a-zA-Z]$/.test(a)).map(quote);
        if (args.length === 0)
            return;
        run((e.runInTerminal ? `${terminal} ` : "") + args.join(" "));

        const c = Object.assign({}, counts);
        c[e.id] = (c[e.id] ?? 0) + 1;
        counts = c;
        store.setText(JSON.stringify(c));
    }

    FileView {
        id: store
        path: root.countsPath
        printErrors: false // missing until the first launch
        onLoaded: {
            try {
                root.counts = JSON.parse(text()) ?? {};
            } catch (e) {
                root.counts = {};
            }
        }
    }

    // the state directory may not exist on a fresh install
    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", Quickshell.env("HOME") + "/.local/state/quickshell"])
}
