import QtQuick
import "Icons.js" as Icons

// angelOS's pixel icons (Icons.js, copied from widgets/), coloured by the theme.
Image {
    property string name: "heart"
    property int pixel: Theme.u
    property color ink: Theme.dark ? Theme.text : Theme.edge
    property color fill: Theme.accent
    property color light: "#ffffff"
    readonly property var _svg: Icons.svg(name, {
        "#": Theme.hex(ink),
        "o": Theme.hex(fill),
        "x": Theme.hex(Theme.accent2),
        "y": Theme.hex(Theme.accent3),
        "w": Theme.hex(light),
        "f": Theme.hex(Theme.dark ? Theme.faceAlt : Theme.sunken),
        "r": Theme.hex(Theme.danger)
    }, false)

    source: _svg.url
    width: _svg.width * pixel
    height: _svg.height * pixel
    sourceSize: Qt.size(width, height)
    smooth: false
}
