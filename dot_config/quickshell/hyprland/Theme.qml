pragma Singleton

import QtQuick
import Quickshell

// One look for every widget, taken from the wallpaper (red-orange-space.png): warm near-black
// with a red-orange glow. Accents match the Hyprland border gradient.
// Qt colour strings with alpha are #AARRGGBB, not CSS #RRGGBBAA.
Singleton {
    // colours
    readonly property color bg: "#e6140a08"      // alpha 0.9, above Hyprland's ignore_alpha 0.3 so blur shows
    readonly property color surface: "#2c1712"
    readonly property color fg: "#f2e4de"
    readonly property color muted: "#9a827b"
    readonly property color accent: "#cc6866"      // the glow
    readonly property color accentText: "#1a0905"  // text and icons on an accent fill
    readonly property color accent2: "#d19a89"     // ember: charging, connected, playing
    readonly property color warn: "#ffcc4d"
    readonly property color crit: "#ff2e63"        // pink-red, apart from the orange accent

    // sizes (logical px)
    readonly property int barHeight: 30
    readonly property int radius: 8
    readonly property int spacing: 8
    readonly property int padding: 10
    readonly property int barEdgePadding: 16   // bar ends: ⏻ on the left, tray on the right
    readonly property int iconSize: 16

    // fonts: text and Nerd Font icons from one family
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13

    // motion: Hyprland has no_anim on qs: layers, so every open/close animates here
    readonly property int animDuration: 150
    readonly property int animEasing: Easing.OutCubic
}
