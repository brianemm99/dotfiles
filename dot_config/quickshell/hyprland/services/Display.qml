pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Display mode as published by hypr/monitors/init.lua in $XDG_RUNTIME_DIR/hypr-display.json.
// Hyprland owns the decision; this only shows it and asks for an override.
Singleton {
    id: root

    property string mode: "laptop"      // laptop, dual, external
    property string override: ""        // "" = automatic, else the overriding mode
    property bool lidClosed: false
    property var externals: []
    readonly property bool hasExternal: externals.length > 0

    // "" goes back to automatic. A refused override changes nothing; the file shows the real state.
    function setOverride(mode) {
        Quickshell.execDetached(["hyprctl", "eval",
            mode ? `Display.set_override("${mode}")` : "Display.set_override(nil)"]);
    }

    // clear any override and re-apply from scratch (same as SUPER + CTRL + P)
    function redetect() {
        Quickshell.execDetached(["hyprctl", "eval", "Display.redetect()"]);
    }

    FileView {
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/hypr-display.json"
        watchChanges: true // the file is replaced atomically (write + rename)
        onFileChanged: reload()
        onLoaded: {
            try {
                const s = JSON.parse(text());
                root.mode = s.mode ?? "laptop";
                root.override = s.override ?? "";
                root.lidClosed = s.lid === "closed";
                root.externals = s.externals ?? [];
            } catch (e) {
                console.warn("hypr-display.json:", e);
            }
        }
    }
}
