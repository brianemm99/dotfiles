pragma Singleton
import QtQuick
import Quickshell

// Gruvbox dark, with the purple accent used by starship.
Singleton {
    readonly property color bg: "#1d2021"
    readonly property color surface: "#282828"
    readonly property color border: "#3c3836"
    readonly property color fg: "#ebdbb2"
    readonly property color muted: "#928374"
    readonly property color accent: "#d3869b"
    readonly property color urgent: "#fb4934"

    readonly property string font: "sans-serif"
    readonly property int fontSize: 13
    readonly property int barHeight: 28
    readonly property int radius: 6
}
