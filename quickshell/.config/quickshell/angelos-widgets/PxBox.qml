import QtQuick

// angelOS's bevelled box (widgets/PxBox.qml): an outline, light on top-left, dark on bottom-right
// (the other way round when sunken).
Item {
    id: root
    property color color: Theme.face
    property bool sunken: false
    property bool shadow: false
    readonly property int bevel: Theme.u
    readonly property int inset: bevel * 2
    default property alias content: inner.data

    Rectangle {
        visible: root.shadow
        x: root.width
        y: Theme.u * 2
        width: Theme.u * 2
        height: root.height
        color: Qt.alpha(Theme.shadow, 0.35)
    }
    Rectangle {
        visible: root.shadow
        x: Theme.u * 2
        y: root.height
        width: root.width
        height: Theme.u * 2
        color: Qt.alpha(Theme.shadow, 0.35)
    }
    Rectangle {
        anchors.fill: parent
        color: root.color
        border.width: root.bevel
        border.color: Theme.edge
    }
    Rectangle {
        x: root.bevel
        y: root.bevel
        width: root.width - 2 * root.bevel
        height: root.bevel
        color: root.sunken ? Theme.lo : Theme.hi
    }
    Rectangle {
        x: root.bevel
        y: root.bevel
        width: root.bevel
        height: root.height - 2 * root.bevel
        color: root.sunken ? Theme.lo : Theme.hi
    }
    Rectangle {
        x: root.bevel * 2
        y: root.height - root.bevel * 2
        width: root.width - root.bevel * 3
        height: root.bevel
        color: root.sunken ? Theme.hi : Theme.lo
    }
    Rectangle {
        x: root.width - root.bevel * 2
        y: root.bevel * 2
        width: root.bevel
        height: root.height - root.bevel * 3
        color: root.sunken ? Theme.hi : Theme.lo
    }
    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: root.inset
    }
}
