pragma Singleton

import Quickshell

// Starts apps through Hyprland, never as Quickshell's children: anything Quickshell spawns
// lives in quickshell.service's cgroup and dies when Quickshell restarts.
// hyprctl itself exits at once, so nothing is left behind.
Singleton {
    // command: a shell command line, e.g. "ghostty -e bluetui"
    function run(command) {
        const lua = command.replace(/\\/g, "\\\\").replace(/"/g, "\\\"");
        Quickshell.execDetached(["hyprctl", "dispatch", `hl.dsp.exec_cmd("${lua}")`]);
    }
}
