//@ pragma UseQApplication
import QtQuick
import Quickshell
import qs.bar

ShellRoot {
    // A bar for every screen Quickshell knows about; hotplug adds and removes them.
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    // toasts and the history panel; also starts the notification daemon
    Notifications {}
}
