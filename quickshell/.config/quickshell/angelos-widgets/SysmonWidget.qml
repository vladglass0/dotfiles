pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// angelOS's system monitor (modules/desktop/widgets/SysmonWidget.qml, size M): CPU, GPU, RAM and
// VRAM as pixel meters, the network under them. A reading every 2 s; the GPU comes from
// angelOS's scripts/gpu-stats.sh (NVIDIA or AMD), run from the AngelOS-Dotfiles checkout.
Column {
    id: root
    width: Theme.u * 130
    spacing: Theme.u * 3

    readonly property string angelos: Quickshell.env("HOME") + "/code/AngelOS-Dotfiles/.config/quickshell/angelos"
    property real cpu: 0
    property real cpuTemp: -1
    property real ram: 0
    property string ramText: ""
    property real gpu: -1
    property real gpuTemp: -1
    property real vram: 0
    property string vramText: ""
    property real rx: 0
    property real tx: 0
    property var _cpuLast: null
    property var _netLast: null
    property string cpuTempPath: ""

    function human(bps) {
        const k = bps / 1024;
        return k < 1024 ? k.toFixed(0) + " КБ/с" : (k / 1024).toFixed(1) + " МБ/с";
    }
    function load(v, t) {
        return Math.round(v * 100) + "%" + (t > 0 ? "  " + Math.round(t) + "°" : "");
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload();
            mem.reload();
            net.reload();
            if (root.cpuTempPath)
                temp.reload();
        }
    }
    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = f[3] + f[4], total = f.reduce((a, b) => a + b, 0);
            if (root._cpuLast && total > root._cpuLast.t)
                root.cpu = 1 - (idle - root._cpuLast.i) / (total - root._cpuLast.t);
            root._cpuLast = {
                "t": total,
                "i": idle
            };
        }
    }
    FileView {
        id: mem
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const g = k => parseInt((t.match(new RegExp(k + ":\\s+(\\d+)")) || [0, 0])[1]);
            const total = g("MemTotal"), avail = g("MemAvailable");
            root.ram = 1 - avail / Math.max(1, total);
            root.ramText = ((total - avail) / 1048576).toFixed(1) + " / " + (total / 1048576).toFixed(0) + " ГБ";
        }
    }
    FileView {
        id: net
        path: "/proc/net/dev"
        onLoaded: {
            let rx = 0, tx = 0;
            for (const l of text().split("\n").slice(2)) {
                const m = l.trim().split(/[:\s]+/);
                if (!m[0] || m[0] === "lo" || m[0].startsWith("veth") || m[0].startsWith("docker"))
                    continue;
                rx += parseInt(m[1]) || 0;
                tx += parseInt(m[9]) || 0;
            }
            const now = Date.now();
            if (root._netLast) {
                const dt = (now - root._netLast.at) / 1000;
                root.rx = Math.max(0, (rx - root._netLast.rx) / dt);
                root.tx = Math.max(0, (tx - root._netLast.tx) / dt);
            }
            root._netLast = {
                "rx": rx,
                "tx": tx,
                "at": now
            };
        }
    }
    FileView {
        id: temp
        path: root.cpuTempPath
        printErrors: false
        onLoaded: root.cpuTemp = parseInt(text()) / 1000
    }
    // the CPU sensor, found once (k10temp / coretemp / zenpower)
    Process {
        running: true
        command: ["sh", "-c", "for h in /sys/class/hwmon/hwmon*; do case $(cat $h/name) in k10temp|coretemp|zenpower|cpu_thermal) echo $h/temp1_input; exit;; esac; done"]
        stdout: StdioCollector {
            onStreamFinished: root.cpuTempPath = text.trim()
        }
    }
    // one line every 2 s: "load %,temp °C,VRAM used MiB,VRAM total MiB"
    Process {
        running: true
        command: ["sh", root.angelos + "/scripts/gpu-stats.sh", "--watch", "2"]
        stdout: SplitParser {
            onRead: line => {
                const v = line.split(",").map(s => parseFloat(s));
                if (v.length >= 4 && !isNaN(v[0])) {
                    root.gpu = v[0] / 100;
                    root.gpuTemp = v[1];
                    if (v[3] > 0) {
                        root.vram = v[2] / v[3];
                        root.vramText = (v[2] / 1024).toFixed(1) + " / " + (v[3] / 1024).toFixed(0) + " ГБ";
                    }
                }
            }
        }
    }

    readonly property var readings: [
        {
            "k": "CPU",
            "v": cpu,
            "t": load(cpu, cpuTemp),
            "c": Theme.accent
        },
        {
            "k": "GPU",
            "v": Math.max(0, gpu),
            "t": gpu < 0 ? "—" : load(gpu, gpuTemp),
            "c": Theme.accent2
        },
        {
            "k": "ОЗУ",
            "v": ram,
            "t": ramText,
            "c": Theme.accent4
        },
        {
            "k": "VRAM",
            "v": vram,
            "t": vramText || "—",
            "c": Theme.accent3
        }
    ]

    Repeater {
        model: root.readings.length
        Column {
            id: r
            required property int index
            readonly property var reading: root.readings[index]
            width: root.width
            spacing: Theme.u
            Row {
                width: parent.width
                PxText {
                    width: parent.width / 2
                    text: r.reading.k
                    font.bold: true
                }
                PxText {
                    width: parent.width / 2
                    horizontalAlignment: Text.AlignRight
                    text: r.reading.t
                    dim: true
                }
            }
            Meter {
                width: parent.width
                value: r.reading.v
                lit: r.reading.c
            }
        }
    }
    Row {
        width: root.width
        PxText {
            width: parent.width * 0.3
            text: "Сеть"
            font.bold: true
        }
        PxText {
            width: parent.width * 0.35
            horizontalAlignment: Text.AlignRight
            text: "↓ " + root.human(root.rx)
            dim: true
        }
        PxText {
            width: parent.width * 0.35
            horizontalAlignment: Text.AlignRight
            text: "↑ " + root.human(root.tx)
            dim: true
        }
    }
}
