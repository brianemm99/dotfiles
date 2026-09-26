//@ pragma UseQApplication
// UseQApplication is required for tray icon context menus.
import QtQuick
import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {
            required property ShellScreen modelData
            screen: modelData
        }
    }

    Notifications {}
    Launcher {}
}
