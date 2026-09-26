import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root

    property bool open: false

    // Toggled from sway: `qs ipc call launcher toggle`
    IpcHandler {
        target: "launcher"

        function toggle(): void { root.open = !root.open; }
        function show(): void { root.open = true; }
        function hide(): void { root.open = false; }
    }

    function search(query: string): list<var> {
        const q = query.trim().toLowerCase();
        const scored = [];
        for (const app of DesktopEntries.applications.values) {
            if (app.noDisplay)
                continue;
            const name = app.name.toLowerCase();
            let score;
            if (q === "")
                score = 0;
            else if (name.startsWith(q))
                score = 0;
            else if (name.includes(q))
                score = 1;
            else if ([app.genericName, app.comment, ...app.keywords].some(s => s && s.toLowerCase().includes(q)))
                score = 2;
            else
                continue;
            scored.push({ app, score });
        }
        scored.sort((a, b) => a.score - b.score || a.app.name.localeCompare(b.app.name));
        return scored.map(s => s.app);
    }

    function launch(app: DesktopEntry): void {
        root.open = false;
        const quote = s => `'${s.replace(/'/g, "'\\''")}'`;
        let cmd = app.command.map(quote).join(" ");
        if (app.runInTerminal)
            cmd = `ghostty -e ${cmd}`;
        if (app.workingDirectory)
            cmd = `cd ${quote(app.workingDirectory)} && ${cmd}`;
        // Launch through sway so the app gets its own scope instead of living
        // in quickshell.service's cgroup (and dying when quickshell restarts).
        Quickshell.execDetached(["swaymsg", "exec", "--", cmd]);
    }

    PanelWindow {
        visible: root.open
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore
        color: "#80000000"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-launcher"

        onVisibleChanged: {
            if (visible) {
                input.text = "";
                list.currentIndex = 0;
                input.forceActiveFocus();
            }
        }

        // Click outside the box to close.
        MouseArea {
            anchors.fill: parent
            onClicked: root.open = false
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height / 5
            width: 520
            height: box.implicitHeight + 24
            radius: Theme.radius
            color: Theme.surface
            border.width: 1
            border.color: Theme.border

            // Swallow clicks so they don't reach the close area behind.
            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                id: box
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                TextInput {
                    id: input

                    Layout.fillWidth: true
                    color: Theme.fg
                    selectionColor: Theme.accent
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 3
                    focus: true
                    onTextChanged: list.currentIndex = 0

                    BarText {
                        visible: input.text === ""
                        text: "Search applications"
                        color: Theme.muted
                        font.pixelSize: input.font.pixelSize
                    }

                    Keys.onPressed: event => {
                        const ctrl = event.modifiers & Qt.ControlModifier;
                        if (event.key === Qt.Key_Escape) {
                            root.open = false;
                        } else if (event.key === Qt.Key_Down || (ctrl && event.key === Qt.Key_J)) {
                            list.incrementCurrentIndex();
                        } else if (event.key === Qt.Key_Up || (ctrl && event.key === Qt.Key_K)) {
                            list.decrementCurrentIndex();
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (list.currentItem)
                                root.launch(list.currentItem.modelData);
                        } else {
                            return;
                        }
                        event.accepted = true;
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Theme.border
                }

                ListView {
                    id: list

                    Layout.fillWidth: true
                    implicitHeight: Math.min(contentHeight, 10 * 36)
                    clip: true
                    model: root.search(input.text)
                    highlightMoveDuration: 0

                    highlight: Rectangle {
                        radius: Theme.radius
                        color: Theme.border
                    }

                    delegate: MouseArea {
                        id: entry

                        required property DesktopEntry modelData
                        required property int index

                        width: ListView.view.width
                        height: 36
                        hoverEnabled: true
                        onEntered: list.currentIndex = index
                        onClicked: root.launch(modelData)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10

                            IconImage {
                                implicitSize: 22
                                source: Quickshell.iconPath(entry.modelData.icon, "application-x-executable")
                            }

                            BarText {
                                Layout.fillWidth: true
                                text: entry.modelData.name
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
