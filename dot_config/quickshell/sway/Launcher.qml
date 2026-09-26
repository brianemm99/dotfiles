import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

Scope {
    id: root

    property bool open: false
    // "apps" or "clipboard"; Tab switches between them.
    property string mode: "apps"

    // Toggled from sway: `qs -c sway ipc call launcher toggle` / `... clipboard`
    IpcHandler {
        target: "launcher"

        function toggle(): void { root.show("apps", !root.open); }
        function show(): void { root.show("apps", true); }
        function hide(): void { root.open = false; }
        function clipboard(): void { root.show("clipboard", !root.open || root.mode !== "clipboard"); }
    }

    function show(mode: string, open: bool): void {
        root.mode = mode;
        root.open = open;
        if (open && mode === "clipboard")
            clipList.running = true;
    }

    // Clipboard history from cliphist (see cliphist.service), newest first.
    readonly property string cliphist: `${Quickshell.env("HOME")}/.local/share/mise/shims/cliphist`
    property var clips: []

    Process {
        id: clipList
        command: [root.cliphist, "list"]
        stdout: StdioCollector {
            // One "<id>\t<preview>" line per entry.
            onStreamFinished: root.clips = this.text.split("\n").filter(line => line).map(line => ({
                line,
                text: line.slice(line.indexOf("\t") + 1),
                image: /^\[\[ binary data /.test(line.slice(line.indexOf("\t") + 1)),
            }))
        }
    }

    function results(query: string): list<var> {
        if (root.mode === "apps")
            return root.search(query);
        const q = query.trim().toLowerCase();
        return root.clips.filter(clip => clip.text.toLowerCase().includes(q));
    }

    function activate(item: var): void {
        if (root.mode === "apps")
            root.launch(item);
        else
            root.paste(item);
    }

    // Puts a history entry back on the clipboard.
    function paste(clip: var): void {
        root.open = false;
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$1" | "$0" decode | wl-copy', root.cliphist, clip.line]);
    }

    function forget(clip: var): void {
        root.clips = root.clips.filter(c => c !== clip);
        Quickshell.execDetached(["sh", "-c", 'printf "%s\\n" "$1" | "$0" delete', root.cliphist, clip.line]);
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
                        text: root.mode === "apps" ? "Search applications" : "Search clipboard"
                        color: Theme.muted
                        font.pixelSize: input.font.pixelSize
                    }

                    BarText {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.mode === "apps" ? "Tab: clipboard" : "Tab: apps  ·  Del: forget"
                        color: Theme.muted
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
                                root.activate(list.currentItem.modelData);
                        } else if (event.key === Qt.Key_Tab) {
                            root.show(root.mode === "apps" ? "clipboard" : "apps", true);
                            list.currentIndex = 0;
                        } else if (event.key === Qt.Key_Delete && root.mode === "clipboard") {
                            if (list.currentItem)
                                root.forget(list.currentItem.modelData);
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
                    model: root.results(input.text)
                    highlightMoveDuration: 0

                    highlight: Rectangle {
                        radius: Theme.radius
                        color: Theme.border
                    }

                    delegate: MouseArea {
                        id: entry

                        // A DesktopEntry, or a clipboard entry from root.clips.
                        required property var modelData
                        required property int index
                        readonly property bool clip: root.mode === "clipboard"

                        width: ListView.view.width
                        height: 36
                        hoverEnabled: true
                        onEntered: list.currentIndex = index
                        onClicked: root.activate(modelData)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10

                            IconImage {
                                visible: !entry.clip
                                implicitSize: 22
                                source: entry.clip ? "" : Quickshell.iconPath(entry.modelData.icon, "application-x-executable")
                            }

                            Icon {
                                visible: entry.clip
                                Layout.preferredWidth: 22
                                text: entry.modelData.image ? "\uf03e" : "\uf328" // image, clipboard
                                color: Theme.muted
                            }

                            BarText {
                                Layout.fillWidth: true
                                text: entry.clip ? entry.modelData.text : entry.modelData.name
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }
}
