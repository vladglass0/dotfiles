import QtQuick

// angelOS's pixel meter: a sunken box of 16 blocks, lit up to `value` (0…1).
PxBox {
    id: root
    property real value: 0
    property color lit: Theme.accent
    height: Theme.u * 6
    color: Theme.sunken
    sunken: true

    Row {
        anchors.fill: parent
        spacing: Math.max(1, Theme.u / 2)
        Repeater {
            model: 16
            Rectangle {
                required property int index
                width: (parent.width - 15 * parent.spacing) / 16
                height: parent.height
                color: index < Math.round(root.value * 16) ? root.lit : "transparent"
            }
        }
    }
}
