pragma Singleton

import QtQuick
import Quickshell

// One look for every widget. Accents match the Hyprland border gradient.
// Qt colour strings with alpha are #AARRGGBB, not CSS #RRGGBBAA.
Singleton {
    // colours
    readonly property color bg: "#e61a1a1a"      // alpha 0.9, above Hyprland's ignore_alpha 0.3 so blur shows
    readonly property color surface: "#262626"
    readonly property color fg: "#e6e6e6"
    readonly property color muted: "#8c8c8c"
    readonly property color accent: "#33ccff"
    readonly property color accentText: "#1a1a1a"  // text and icons on an accent fill
    readonly property color accent2: "#00ff99"
    readonly property color warn: "#ffb84d"
    readonly property color crit: "#ff5c5c"

    // sizes (logical px)
    readonly property int barHeight: 30
    readonly property int radius: 8
    readonly property int spacing: 8
    readonly property int padding: 10
    readonly property int iconSize: 16

    // fonts: text and Nerd Font icons from one family
    readonly property string fontFamily: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13

    // motion: Hyprland has no_anim on qs: layers, so every open/close animates here
    readonly property int animDuration: 150
    readonly property int animEasing: Easing.OutCubic
}
