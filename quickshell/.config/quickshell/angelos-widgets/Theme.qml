pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// angelOS's look for the desktop widgets, in Caelestia's colours: the palette
// ~/.local/bin/caelestia-angelos-theme writes on every wallpaper change (watched, so the
// widgets recolour on the fly). Sizes and fonts are angelOS's defaults (config/Theme.qml).
Singleton {
    id: root

    property var pal: ({})
    function c(key, fallback) {
        return pal[key] || fallback;
    }

    readonly property bool dark: pal.mode !== "light"
    readonly property color face: c("face", "#241432")
    readonly property color faceAlt: c("faceAlt", "#2f1a42")
    readonly property color sunken: c("sunken", "#150b1e")
    readonly property color text: c("text", "#ffe1f1")
    readonly property color textDim: c("textDim", "#a987b8")
    readonly property color hi: c("hi", "#4a2c63")
    readonly property color lo: c("lo", "#0e0716")
    readonly property color edge: c("edge", "#07030b")
    readonly property color accent: c("accent", "#ff5cad")
    readonly property color accent2: c("accent2", "#4fe3ff")
    readonly property color accent3: c("accent3", "#ffe066")
    readonly property color accent4: c("accent4", "#a57cff")
    readonly property color danger: c("danger", "#ff4f6d")
    readonly property color ok: c("ok", "#57e3a2")
    readonly property color shadow: c("shadow", "#000000")
    readonly property color menuHeader: mix(faceAlt, accent, dark ? 0.16 : 0.10)
    readonly property color panel: Qt.alpha(face, 0.88)

    readonly property int u: 2                     // one art pixel
    readonly property int pad: u * 5
    readonly property string fontTitle: "Pixeloid Sans"
    readonly property string fontBody: "CozetteVector"
    readonly property string fontMono: "Pixeloid Mono"
    // pixel fonts stay crisp only at multiples of their native size
    function fontPx(base, family) {
        const n = family === fontTitle || family === fontMono ? 9 : family === fontBody ? 13 : 0;
        return n > 0 ? n * Math.max(1, Math.round(base / n)) : base;
    }
    readonly property int sizeTiny: fontPx(9, fontTitle)
    readonly property int sizeBody: fontPx(13, fontBody)
    readonly property int sizeTitle: fontPx(18, fontTitle)

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
    }
    function hex(col) {
        const h = v => ("0" + Math.round(v * 255).toString(16)).slice(-2);
        return "#" + h(col.r) + h(col.g) + h(col.b);
    }

    FileView {
        path: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/angelos/palette.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.pal = JSON.parse(text());
            } catch (e) {}
        }
    }
}
