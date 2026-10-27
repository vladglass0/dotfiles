import QtQuick
import Quickshell
import Quickshell.Io

// angelOS's desktop clock (modules/desktop/widgets/ClockWidget.qml, size M): the time in big
// pixel letters, a heart and the date under it, the weather in the corner.
// The weather is angelOS's services/Weather.qml: Open-Meteo (no key) every 30 minutes, for the
// place Caelestia's own weather uses (services.weatherLocation in ~/.config/caelestia/shell.json:
// "lat,lon" or a city), else where the IP says; the last answer is cached, so a restart or
// no network still shows it.
Row {
    id: root
    spacing: Theme.u * 8

    readonly property var locale: Qt.locale("ru_RU")
    property string where: ""      // Caelestia's weatherLocation
    property var place: null       // {name, lat, lon, from}
    property var wx: null          // {temp, code, day, at}
    property bool busy: false
    readonly property int refreshMs: 30 * 60 * 1000

    function kind(code) {
        const c = code === undefined || code === null ? -1 : code;
        if (c === 0 || c === 1)
            return "clear";
        if (c === 2)
            return "partly";
        if (c === 3)
            return "cloudy";
        if (c === 45 || c === 48)
            return "fog";
        if (c >= 51 && c <= 67 || c >= 80 && c <= 82)
            return "rain";
        if (c >= 71 && c <= 77 || c === 85 || c === 86)
            return "snow";
        return c >= 95 ? "storm" : "cloudy";
    }
    function icon(code, day) {
        const k = kind(code);
        return k === "clear" ? (day === false ? "moon" : "sun") : ({
                "partly": "cloudSun",
                "cloudy": "cloud",
                "fog": "fog",
                "rain": "rain",
                "snow": "snow",
                "storm": "storm"
            })[k];
    }
    function words(code) {
        return ({
                "clear": "ясно",
                "partly": "переменная облачность",
                "cloudy": "облачно",
                "fog": "туман",
                "rain": "дождь",
                "snow": "снег",
                "storm": "гроза"
            })[kind(code)];
    }
    function deg(t) {
        if (t === undefined || t === null || isNaN(t))
            return "—";
        const r = Math.round(t);
        return (r > 0 ? "+" : r < 0 ? "−" : "") + Math.abs(r) + "°";
    }
    function get(url, done) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            let body = null;
            try {
                body = xhr.status === 200 ? JSON.parse(xhr.responseText) : null;
            } catch (e) {}
            done(body);
        };
        xhr.open("GET", url);
        xhr.send();
    }
    // the place first (Caelestia's coordinates or city, else the IP's), then the weather
    function refresh() {
        if (busy)
            return;
        busy = true;
        const want = where || "ip";
        if (place && place.from === want) {
            fetchWeather();
            return;
        }
        const ll = want.match(/^\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*$/);
        if (ll) {
            place = {
                "name": "",
                "lat": +ll[1],
                "lon": +ll[2],
                "from": want
            };
            fetchWeather();
        } else if (want !== "ip") {
            get("https://geocoding-api.open-meteo.com/v1/search?count=1&format=json&language=ru&name=" + encodeURIComponent(want), b => {
                const r = b && b.results && b.results[0];
                if (!r) {
                    busy = false;
                    return;
                }
                place = {
                    "name": r.name,
                    "lat": r.latitude,
                    "lon": r.longitude,
                    "from": want
                };
                fetchWeather();
            });
        } else {
            get("http://ip-api.com/json/?fields=status,city,lat,lon", b => {
                if (!b || b.status !== "success") {
                    busy = false;
                    return;
                }
                place = {
                    "name": b.city,
                    "lat": b.lat,
                    "lon": b.lon,
                    "from": "ip"
                };
                fetchWeather();
            });
        }
    }
    function fetchWeather() {
        get("https://api.open-meteo.com/v1/forecast?latitude=" + place.lat + "&longitude=" + place.lon + "&current=temperature_2m,weather_code,is_day&timezone=auto", b => {
            busy = false;
            const c = b && b.current;
            if (!c)
                return;
            wx = {
                "temp": c.temperature_2m,
                "code": c.weather_code,
                "day": c.is_day !== 0,
                "at": Date.now()
            };
            cache.setText(JSON.stringify({
                "place": place,
                "now": wx
            }));
        });
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
    Timer {
        interval: root.refreshMs
        running: true
        repeat: true
        // a fresh cached answer waits for the next turn
        onTriggered: if (!root.wx || Date.now() - (root.wx.at || 0) > root.refreshMs - 60000 || !root.place || root.place.from !== (root.where || "ip"))
            root.refresh()
    }
    FileView {
        id: cache
        path: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/angelos-widgets/weather.json"
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                const c = JSON.parse(text());
                if (c.place && !root.place)
                    root.place = c.place;
                if (c.now && !root.wx)
                    root.wx = c.now;
            } catch (e) {}
        }
    }
    FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/caelestia/shell.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.where = ((JSON.parse(text()).services || {}).weatherLocation || "").trim();
            } catch (e) {}
            Qt.callLater(() => {
                if (!root.wx || !root.place || root.place.from !== (root.where || "ip") || Date.now() - (root.wx.at || 0) > root.refreshMs - 60000)
                    root.refresh();
            });
        }
        onLoadFailed: Qt.callLater(root.refresh)
    }

    Column {
        spacing: Theme.u * 2
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.date, "hh:mm")
            font.family: Theme.fontTitle
            font.pixelSize: Theme.fontPx(54, Theme.fontTitle)
            color: Theme.dark ? Theme.text : Theme.edge
            style: Text.Outline
            styleColor: Qt.alpha(Theme.accent, 0.6)
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.u * 3
            PxIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "heart"
            }
            PxText {
                text: root.locale.toString(clock.date, "dddd, d MMMM")
                kind: "title"
                dim: true
            }
        }
    }
    Column {
        visible: !!root.wx
        spacing: Theme.u * 2
        topPadding: Theme.u * 2
        PxIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: root.wx ? root.icon(root.wx.code, root.wx.day) : "cloud"
            pixel: Theme.u * 2
        }
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.wx ? root.deg(root.wx.temp) : ""
            kind: "title"
            font.bold: true
        }
        PxText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.wx ? root.words(root.wx.code) : ""
            kind: "tiny"
            dim: true
        }
    }
}
