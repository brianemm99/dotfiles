//@ pragma UseQApplication
// no Qt platform theme here, so name the icon theme or only hicolor is searched
//@ pragma IconTheme Adwaita
import QtQuick
import Quickshell
import qs.bar
import qs.popups

ShellRoot {
    // A bar for every screen Quickshell knows about; hotplug adds and removes them.
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    // toasts and the history panel; also starts the notification daemon
    Notifications {}

    // SUPER + D
    Launcher {}

    // SUPER + Escape, ⏻ on the bar
    PowerMenu {}

    // SUPER + C, clock click
    Calendar {}

    // SUPER + I, the rings on the bar
    Resources {}
}
