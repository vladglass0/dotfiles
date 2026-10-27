pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Claude Code's plan limits (the same numbers as /usage): the 5-hour window and the weeks, how
// much is LEFT and when it resets. angelOS's plugins/claude-companion (Usage.qml + Limits.qml).
// Reads the OAuth token Claude Code keeps in ~/.claude/.credentials.json and sends it only to
// api.anthropic.com; never touches the refresh token. Every 5 minutes, backs off on 429; the
// last answer is cached so a restart doesn't ask again.
Column {
    id: root
    width: Theme.u * 130
    spacing: Theme.u * 4

    property var five: null        // {used, left, resetsAt}
    property var week: null
    property var weekOpus: null
    property var weekSonnet: null
    property string status: "idle" // idle | loading | ok | limited | expired | auth | offline | nologin
    property string plan: ""
    property date updated
    readonly property int intervalSec: 300
    property real notBefore: 0      // backoff after 429 (ms since epoch)
    // stale numbers stay on show while Anthropic rate-limits us or the network is down
    readonly property bool ok: (status === "ok" || status === "limited" || status === "loading" || status === "offline") && !!five
    property string _token: ""
    property real _expires: 0

    function window(w) {
        if (!w || w.utilization === null || w.utilization === undefined)
            return null;
        const used = Math.max(0, Math.min(100, w.utilization));
        return {
            "used": used,
            "left": Math.round(100 - used),
            "resetsAt": w.resets_at ? new Date(w.resets_at) : null
        };
    }
    function untilText(d) {
        const m = Math.max(0, Math.round((d.getTime() - Date.now()) / 60000));
        if (m < 60)
            return m + " мин";
        const h = Math.floor(m / 60);
        return h < 48 ? h + " ч " + (m % 60) + " мин" : Math.floor(h / 24) + " д " + (h % 24) + " ч";
    }
    function colorFor(left) {
        return left <= 15 ? Theme.danger : left <= 40 ? Theme.accent3 : Theme.ok;
    }
    function apply(d, when) {
        five = window(d.five_hour);
        week = window(d.seven_day);
        weekOpus = window(d.seven_day_opus);
        weekSonnet = window(d.seven_day_sonnet);
        updated = when;
    }
    function refresh() {
        const now = Date.now();
        if (now < notBefore || (five && now - updated.getTime() < (intervalSec - 10) * 1000))
            return;
        if (!_token) {
            status = "nologin";
            return;
        }
        if (_expires && _expires < now) {
            status = "expired";   // Claude Code refreshes it on its next run
            return;
        }
        if (status !== "ok")
            status = "loading";
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status === 200) {
                try {
                    const d = JSON.parse(xhr.responseText);
                    root.apply(d, new Date());
                    root.status = "ok";
                    cache.setText(JSON.stringify({
                        "at": Date.now(),
                        "data": d
                    }));
                } catch (e) {
                    root.status = "offline";
                }
            } else if (xhr.status === 429) {
                const ra = parseInt(xhr.getResponseHeader("retry-after") || "0");
                root.notBefore = Date.now() + Math.max(600, ra || 0) * 1000;
                root.status = "limited";
            } else {
                root.status = xhr.status === 401 || xhr.status === 403 ? "auth" : "offline";
            }
        };
        xhr.open("GET", "https://api.anthropic.com/api/oauth/usage");
        xhr.setRequestHeader("Authorization", "Bearer " + _token);
        xhr.setRequestHeader("anthropic-beta", "oauth-2025-04-20");
        xhr.setRequestHeader("User-Agent", "angelos-widgets");
        xhr.send();
    }

    Timer {
        interval: root.intervalSec * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
    // the countdowns move between answers
    Timer {
        interval: 60000
        running: root.ok
        repeat: true
        onTriggered: root.five = Object.assign({}, root.five)
    }
    FileView {
        id: cache
        path: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/angelos-widgets/claude-usage.json"
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                const c = JSON.parse(text());
                if (c && c.data && !root.five) {
                    root.apply(c.data, new Date(c.at));
                    root.status = "ok";
                }
            } catch (e) {}
        }
    }
    FileView {
        path: (Quickshell.env("CLAUDE_CONFIG_DIR") || Quickshell.env("HOME") + "/.claude") + "/.credentials.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const o = JSON.parse(text()).claudeAiOauth || {};
                const changed = o.accessToken !== root._token;
                root._token = o.accessToken || "";
                root._expires = o.expiresAt || 0;
                root.plan = o.subscriptionType || "";
                if (changed)
                    Qt.callLater(root.refresh);
            } catch (e) {
                root._token = "";
                root.status = "nologin";
            }
        }
        onLoadFailed: root.status = "nologin"
    }

    readonly property var rows: [
        {
            "label": "5 часов",
            "w": five
        },
        {
            "label": "неделя",
            "w": week
        },
        {
            "label": "неделя Opus",
            "w": weekOpus
        },
        {
            "label": "неделя Sonnet",
            "w": weekSonnet
        }
    ].filter(r => !!r.w)

    PxText {
        visible: !root.ok
        width: root.width
        wrapMode: Text.Wrap
        dim: true
        text: ({
                "idle": "…",
                "loading": "узнаю лимиты…",
                "expired": "токен Claude Code истёк — обновится при следующем запуске claude",
                "auth": "Anthropic не принял токен (401) — перелогинься в claude",
                "offline": "нет связи с api.anthropic.com",
                "nologin": "не нашёл ~/.claude/.credentials.json — войди в Claude Code"
            })[root.status] || root.status
    }
    Repeater {
        model: root.ok ? root.rows : []
        Column {
            id: r
            required property var modelData
            readonly property color c: root.colorFor(modelData.w.left)
            width: root.width
            spacing: Theme.u
            Row {
                width: parent.width
                PxText {
                    width: parent.width / 2
                    text: r.modelData.label
                    dim: true
                }
                PxText {
                    width: parent.width / 2
                    horizontalAlignment: Text.AlignRight
                    text: "осталось " + r.modelData.w.left + "%"
                    color: r.c
                    font.bold: true
                }
            }
            // blocky meter: the filled blocks are what's left
            PxBox {
                width: parent.width
                height: Theme.u * 8
                color: Theme.sunken
                sunken: true
                Row {
                    anchors.fill: parent
                    spacing: Math.max(1, Theme.u / 2)
                    Repeater {
                        model: 20
                        Rectangle {
                            required property int index
                            width: parent ? (parent.width - 19 * parent.spacing) / 20 : 0
                            height: parent ? parent.height : 0
                            color: index < Math.round(r.modelData.w.left / 5) ? r.c : "transparent"
                        }
                    }
                }
            }
            PxText {
                visible: !!r.modelData.w.resetsAt
                text: r.modelData.w.resetsAt ? "сброс через " + root.untilText(r.modelData.w.resetsAt) + "  (" + Qt.locale("ru_RU").toString(r.modelData.w.resetsAt, "ddd HH:mm") + ")" : ""
                kind: "tiny"
                dim: true
            }
        }
    }
    PxText {
        visible: root.ok
        text: "план: " + (root.plan || "?") + " · обновлено " + Qt.formatTime(root.updated, "HH:mm") + (root.status === "limited" ? " · API просит подождать" : root.status === "offline" ? " · нет связи" : "")
        kind: "tiny"
        dim: true
    }
}
