pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

// angelOS's disks widget (modules/desktop/widgets/DisksWidget.qml, size M): every disk, how full,
// `df` once a minute. A btrfs volume mounted many times (/, /home, /var/log…) is one disk;
// the boot partition and the system's own mounts are left out.
Column {
    id: root
    width: Theme.u * 124
    spacing: Theme.u * 3

    property var disks: []

    function gb(b) {
        const g = b / 1e9;
        return g >= 1000 ? (g / 1000).toFixed(1) + " ТБ" : Math.round(g) + " ГБ";
    }
    function nameOf(target) {
        if (target === "/")
            return "Система";
        if (target === "/home")
            return "Дом";
        return target.slice(target.lastIndexOf("/") + 1) || target;
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: if (!df.running)
            df.running = true
    }
    Process {
        id: df
        command: ["df", "-B1", "--output=source,fstype,size,used,target", "-x", "tmpfs", "-x", "devtmpfs", "-x", "efivarfs", "-x", "overlay", "-x", "squashfs", "-x", "ramfs", "-x", "fuse.portal", "-x", "autofs"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seenSrc = {};
                const out = [];
                for (const l of text.split("\n").slice(1)) {
                    const f = l.trim().split(/\s+/);
                    if (f.length < 5)
                        continue;
                    const target = f.slice(4).join(" ");
                    if (/^\/(boot|efi)(\/|$)/.test(target) || /^\/(var\/lib\/(docker|containers)|snap|run\/(user|credentials))/.test(target) || +f[2] <= 0)
                        continue;
                    const prev = seenSrc[f[0]];
                    if (prev) {
                        if (target.length < prev.target.length) {
                            prev.target = target;
                            prev.name = root.nameOf(target);
                        }
                        continue;
                    }
                    const d = {
                        "name": root.nameOf(target),
                        "size": +f[2],
                        "used": +f[3],
                        "target": target
                    };
                    seenSrc[f[0]] = d;
                    out.push(d);
                }
                out.sort((a, b) => (a.target === "/" ? -1 : b.target === "/" ? 1 : b.size - a.size));
                root.disks = out.slice(0, 5);
            }
        }
    }

    Repeater {
        model: root.disks
        Column {
            id: d
            required property var modelData
            readonly property real v: modelData.used / Math.max(1, modelData.size)
            width: root.width
            spacing: Theme.u
            Row {
                width: parent.width
                spacing: Theme.u * 2
                PxIcon {
                    id: hdd
                    anchors.verticalCenter: parent.verticalCenter
                    name: "hdd"
                    pixel: Math.max(1, Theme.u - 1)
                }
                PxText {
                    width: parent.width / 2 - hdd.width - Theme.u * 2
                    anchors.verticalCenter: parent.verticalCenter
                    text: d.modelData.name
                    elide: Text.ElideRight
                }
                PxText {
                    width: parent.width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    text: root.gb(d.modelData.used) + " / " + root.gb(d.modelData.size)
                    dim: true
                }
            }
            Meter {
                width: parent.width
                height: Theme.u * 5
                value: d.v
                // a nearly full disk turns red
                lit: d.v > 0.9 ? Theme.danger : Theme.accent
            }
        }
    }
    PxText {
        visible: root.disks.length === 0
        text: "смотрю диски…"
        kind: "tiny"
        dim: true
    }
}
