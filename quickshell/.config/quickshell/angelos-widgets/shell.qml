//@ pragma UseQApplication
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// angelOS's desktop widgets beside Caelestia: `qs -c angelos-widgets`. One layer on the main
// screen, under the windows and over Caelestia's wallpaper; only the widgets take the pointer.
// A widget is moved by its title bar; where each one stands is kept in
// ~/.local/state/angelos-widgets/layout.json.
ShellRoot {
    id: shell

    readonly property string screenName: "DP-1"
    readonly property string statePath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/angelos-widgets/layout.json"
    // where each widget starts before it was ever moved (pixels from the top-left corner)
    readonly property var defaults: ({
            "clock": [60, 60],
            "sysmon": [60, 260],
            "disks": [60, 640],
            "music": [2180, 60],
            "claude": [2180, 330]
        })
    property var layout: ({})
    function at(id) {
        return layout[id] || defaults[id];
    }
    function save(id, x, y) {
        const next = Object.assign({}, layout);
        next[id] = [Math.round(x), Math.round(y)];
        layout = next;
        layoutFile.setText(JSON.stringify(layout, null, 1) + "\n");
    }

    FileView {
        id: layoutFile
        path: shell.statePath
        printErrors: false
        onLoaded: {
            try {
                shell.layout = JSON.parse(text());
            } catch (e) {}
        }
    }
    // the state and cache folders may not exist yet
    Process {
        running: true
        command: ["mkdir", "-p", shell.statePath.slice(0, shell.statePath.lastIndexOf("/")), (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/angelos-widgets"]
    }

    PanelWindow {
        id: desk
        screen: Quickshell.screens.find(s => s.name === shell.screenName) || Quickshell.screens[0]
        color: "transparent"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "angelos-widgets"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        // only the widgets take clicks; the rest of the screen stays the desktop's
        mask: Region {
            Region {
                item: clockWin
            }
            Region {
                item: sysmonWin
            }
            Region {
                item: disksWin
            }
            Region {
                item: musicWin
            }
            Region {
                item: claudeWin
            }
        }

        Item {
            id: stage
            anchors.fill: parent

            WidgetWindow {
                id: clockWin
                title: "часы.exe"
                icon: "heart"
                x: shell.at("clock")[0]
                y: shell.at("clock")[1]
                width: implicitWidth
                height: implicitHeight
                onMoved: (x, y) => shell.save("clock", x, y)
                ClockWidget {}
            }
            WidgetWindow {
                id: sysmonWin
                title: "система.exe"
                icon: "chip"
                x: shell.at("sysmon")[0]
                y: shell.at("sysmon")[1]
                width: implicitWidth
                height: implicitHeight
                onMoved: (x, y) => shell.save("sysmon", x, y)
                SysmonWidget {}
            }
            WidgetWindow {
                id: disksWin
                title: "диски.exe"
                icon: "hdd"
                x: shell.at("disks")[0]
                y: shell.at("disks")[1]
                width: implicitWidth
                height: implicitHeight
                onMoved: (x, y) => shell.save("disks", x, y)
                DisksWidget {}
            }
            WidgetWindow {
                id: musicWin
                title: "музыка.exe"
                icon: "music"
                x: shell.at("music")[0]
                y: shell.at("music")[1]
                width: implicitWidth
                height: implicitHeight
                onMoved: (x, y) => shell.save("music", x, y)
                MusicWidget {}
            }
            WidgetWindow {
                id: claudeWin
                title: "claude.exe"
                icon: "bot"
                x: shell.at("claude")[0]
                y: shell.at("claude")[1]
                width: implicitWidth
                height: implicitHeight
                onMoved: (x, y) => shell.save("claude", x, y)
                ClaudeWidget {}
            }
        }
    }
}
