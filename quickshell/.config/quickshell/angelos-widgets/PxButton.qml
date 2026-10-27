import QtQuick

// A small bevelled icon button that sinks while pressed.
PxBox {
    id: root
    property string icon: "play"
    signal clicked

    width: glyph.width + Theme.u * 8
    height: glyph.height + Theme.u * 8
    color: mouse.containsMouse ? Theme.mix(Theme.face, Theme.accent, 0.18) : Theme.face
    sunken: mouse.pressed

    PxIcon {
        id: glyph
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: mouse.pressed ? Theme.u : 0
        anchors.verticalCenterOffset: mouse.pressed ? Theme.u : 0
        name: root.icon
        pixel: Math.max(1, Theme.u - 1)
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
