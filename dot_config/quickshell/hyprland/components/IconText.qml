import QtQuick
import qs

// Text or a Nerd Font glyph in the theme font; every label on the bar uses this.
Text {
    color: Theme.fg
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter
}
