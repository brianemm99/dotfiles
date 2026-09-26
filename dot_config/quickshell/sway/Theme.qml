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
    // Font Awesome ships with the Fedora Sway Atomic base image.
    readonly property string iconFont: "Font Awesome 6 Free"
    readonly property int fontSize: 13
    readonly property int barHeight: 28
    readonly property int radius: 6

    // volume-xmark, volume-off, volume-low, volume-high
    function volumeIcon(level: real, muted: bool): string {
        return muted ? "\uf6a9" : level === 0 ? "\uf026" : level < 0.5 ? "\uf027" : "\uf028";
    }
}
