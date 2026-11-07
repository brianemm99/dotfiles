pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris

// Media sources for the bar's NowPlaying module and the media drop-down (popups/Media.qml).
// Two sources, detected independently from Mpris: Spotify and Browser (Brave; picture-in-picture
// is the same tab's player). Other players are ignored.
// Selection: the source that most recently started playing; if it pauses while the other is
// still playing, the one still playing; with nothing playing, the most recent stays. A manual
// pick in the drop-down holds until some player starts playing again.
Singleton {
    id: root

    // ---- drop-down open state (no keybind: only the bar module opens it) ----

    property bool open: false
    property ShellScreen screen: null
    property real anchorX: 0            // centre of the bar module, in bar coordinates

    function show(screen, x) {
        root.screen = screen ?? Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0];
        if (x !== undefined)
            anchorX = x;
        open = true;
    }
    function hide() {
        if (open)
            closedAt = Date.now();
        open = false;
    }
    // a click on the module while open first closes it (click outside); don't reopen on it
    property real closedAt: 0
    function toggle(screen, x) {
        if (open)
            hide();
        else if (Date.now() - closedAt > 300)
            show(screen, x);
    }

    // ---- sources ----

    // "brave.instance1234" from "org.mpris.MediaPlayer2.brave.instance1234"; what playerctl -p takes
    function busName(p) {
        return (p?.dbusName ?? "").replace("org.mpris.MediaPlayer2.", "");
    }
    function isSpotify(p) {
        return `${p.identity} ${p.desktopEntry} ${busName(p)}`.toLowerCase().includes("spotify");
    }
    function isBrowser(p) {
        const bus = busName(p).toLowerCase();
        return bus.startsWith("brave") || bus.startsWith("chromium") || `${p.identity} ${p.desktopEntry}`.toLowerCase().includes("brave");
    }

    // when each player last started playing, by bus name; rev makes bindings re-read it
    property var started: ({})
    property int rev: 0
    function stamp(p) {
        rev;
        return started[p?.dbusName] ?? 0;
    }
    function markStarted(p) {
        started[p.dbusName] = Date.now();
        manual = "";
        rev++;
    }

    Instantiator {
        model: Mpris.players

        delegate: Connections {
            required property MprisPlayer modelData
            target: modelData

            function onIsPlayingChanged() {
                if (modelData.isPlaying)
                    root.markStarted(modelData);
            }
            Component.onCompleted: if (modelData.isPlaying)
                root.markStarted(modelData)
        }
    }

    // the one to show from a set: playing ones first, then the most recent to start
    function newest(list) {
        const playing = list.filter(p => p.isPlaying);
        const pool = playing.length ? playing : list;
        return pool.reduce((a, b) => (a === null || stamp(b) > stamp(a)) ? b : a, null);
    }

    readonly property var all: Mpris.players.values
    readonly property MprisPlayer spotify: newest(all.filter(p => isSpotify(p)))
    readonly property MprisPlayer browser: newest(all.filter(p => !isSpotify(p) && isBrowser(p)))

    // "spotify" | "browser" | ""
    property string manual: ""
    readonly property string auto: {
        const best = newest([spotify, browser].filter(p => p !== null));
        return best === null ? "" : best === spotify ? "spotify" : "browser";
    }
    readonly property string source: (manual === "spotify" && spotify) || (manual === "browser" && browser) ? manual : auto
    readonly property MprisPlayer active: source === "spotify" ? spotify : source === "browser" ? browser : null

    function select(src) {
        if ((src === "spotify" && spotify) || (src === "browser" && browser))
            manual = src;
    }

    // ---- what to show ----

    function artUrl(p) {
        // older Spotify builds hand out open.spotify.com/image/<id>, which doesn't load
        return (p?.trackArtUrl ?? "").replace("https://open.spotify.com/image/", "https://i.scdn.co/image/");
    }
    function label(p) {
        if (!p)
            return "";
        const title = p.trackTitle || p.identity;
        return p.trackArtist ? `${title} | ${p.trackArtist}` : title;
    }

    // ---- controls: playerctl, aimed at the shown player ----

    function command(cmd) {
        if (active)
            Quickshell.execDetached(["playerctl", "-p", busName(active), cmd]);
    }
    function seek(seconds) {
        if (active?.canSeek && active.positionSupported)
            active.position = seconds;
    }
}
