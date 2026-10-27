pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// angelOS's music widget (modules/desktop: MusicWidget size L = MusicPlayer over MusicSpectrum):
// the current MPRIS player's pixelated cover, track, progress and buttons; under it cava's
// spectrum in pixel blocks. The sound comes through angelOS's scripts/audio-tap.py (what the
// computer plays, never the microphone), run from the AngelOS-Dotfiles checkout, only while
// something plays.
Column {
    id: root
    width: Theme.u * 150
    spacing: Theme.u * 4

    readonly property string angelos: Quickshell.env("HOME") + "/code/AngelOS-Dotfiles/.config/quickshell/angelos"
    // the playing player, else the first one there is
    readonly property var p: {
        const all = Mpris.players.values;
        return all.find(x => x.isPlaying) || all[0] || null;
    }
    readonly property bool playing: !!p && p.isPlaying
    readonly property bool hasTrack: !!p && !!p.trackTitle
    property real pos: 0

    function clock(sec) {
        if (!(sec >= 0) || !isFinite(sec))
            return "0:00";
        const s = Math.floor(sec);
        return Math.floor(s / 60) + ":" + ("0" + s % 60).slice(-2);
    }

    Timer {
        interval: 1000
        running: root.playing
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.p.positionChanged();
            root.pos = root.p.position;
        }
    }

    // ---- the player ----
    Item {
        width: root.width
        height: Theme.u * 40

        PxText {
            visible: !root.hasTrack
            anchors.centerIn: parent
            text: "ничего не играет ♡"
            dim: true
        }
        Row {
            visible: root.hasTrack
            anchors.fill: parent
            spacing: Theme.u * 5

            PxBox {
                width: parent.height
                height: parent.height
                color: Theme.sunken
                sunken: true
                Image {
                    anchors.fill: parent
                    source: root.p ? root.p.trackArtUrl : ""
                    sourceSize: Qt.size(Theme.u * 24, Theme.u * 24)   // tiny source + no smoothing = pixel cover
                    fillMode: Image.PreserveAspectCrop
                    smooth: false
                    asynchronous: true
                }
            }
            Column {
                width: parent.width - parent.height - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.u * 2
                PxText {
                    width: parent.width
                    text: root.p ? root.p.trackTitle : ""
                    font.bold: true
                    elide: Text.ElideRight
                }
                PxText {
                    width: parent.width
                    text: root.p ? root.p.trackArtist : ""
                    dim: true
                    elide: Text.ElideRight
                }
                PxBox {
                    width: parent.width
                    height: Theme.u * 4
                    color: Theme.sunken
                    sunken: true
                    Rectangle {
                        height: parent.height
                        width: root.p && root.p.length > 0 ? parent.width * Math.min(1, root.pos / root.p.length) : 0
                        color: Theme.accent
                    }
                }
                Row {
                    spacing: Theme.u * 2
                    PxButton {
                        icon: "prev"
                        onClicked: root.p.previous()
                    }
                    PxButton {
                        icon: root.playing ? "pause" : "play"
                        onClicked: root.p.togglePlaying()
                    }
                    PxButton {
                        icon: "next"
                        onClicked: root.p.next()
                    }
                    PxText {
                        anchors.verticalCenter: parent.verticalCenter
                        leftPadding: Theme.u * 2
                        text: root.clock(root.pos) + (root.p && root.p.length > 0 ? " / " + root.clock(root.p.length) : "")
                        kind: "tiny"
                        dim: true
                    }
                }
            }
        }
    }

    // ---- the spectrum ----
    Item {
        id: spectrum
        width: root.width
        height: rows * block + (rows - 1) * gap
        readonly property int bars: 32
        readonly property int rows: 14
        readonly property int block: Theme.u * 2
        readonly property int gap: Math.max(1, Theme.u / 2)
        readonly property int barW: Math.max(Theme.u, Math.floor((width - Theme.u * (bars - 1)) / bars))
        property var levels: []
        readonly property string conf: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/angelos-widgets-cava.conf"
        readonly property string fifo: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/angelos-widgets-cava.fifo"

        FileView {
            id: confFile
            path: spectrum.conf
            preload: false
            printErrors: false
            atomicWrites: true
            onSaved: cava.running = root.playing
            Component.onCompleted: setText(["[general]", "bars = " + spectrum.bars, "framerate = 30", "sensitivity = 70", "autosens = 1", "[input]", "method = fifo", "source = " + spectrum.fifo, "sample_rate = 22050", "sample_bits = 16", "[output]", "method = raw", "raw_target = /dev/stdout", "data_format = ascii", "ascii_max_range = 100", "bar_delimiter = 59", "frame_delimiter = 10", "channels = mono", "[smoothing]", "noise_reduction = 60", ""].join("\n"))
        }
        Process {
            id: cava
            command: ["python3", root.angelos + "/scripts/audio-tap.py", "run", "--conf", spectrum.conf, "--fifo", spectrum.fifo, ""]
            stdout: SplitParser {
                onRead: line => spectrum.levels = line.split(";").filter(s => s !== "").map(n => parseInt(n) / 100)
            }
        }
        // cava runs only while something plays; the bars fall flat when it stops
        Connections {
            target: root
            function onPlayingChanged() {
                cava.running = root.playing;
                if (!root.playing)
                    spectrum.levels = [];
            }
        }
        // restart a tap that died while the music goes on
        Timer {
            interval: 3000
            repeat: true
            running: root.playing && !cava.running
            onTriggered: cava.running = true
        }

        Row {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.u
            Repeater {
                model: spectrum.bars
                Column {
                    id: bar
                    required property int index
                    readonly property int lit: Math.round((spectrum.levels[index] || 0) * spectrum.rows)
                    spacing: spectrum.gap
                    Repeater {
                        model: spectrum.rows
                        Rectangle {
                            required property int index
                            // row 0 is the top block
                            readonly property bool on: spectrum.rows - index <= bar.lit
                            width: spectrum.barW
                            height: spectrum.block
                            color: !on ? Qt.alpha(Theme.text, 0.06) : index === spectrum.rows - bar.lit && bar.lit > spectrum.rows * 0.8 ? Theme.accent3 : Theme.accent
                        }
                    }
                }
            }
        }
    }
}
