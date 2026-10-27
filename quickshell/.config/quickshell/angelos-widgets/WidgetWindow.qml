import QtQuick

// angelOS's .exe window (widgets/PxWindow.qml, classic skin) around one desktop widget:
// a bevelled frame, the title bar in the menu colour with a heart, dragged by the title bar.
Item {
    id: root
    property string title: ""
    property string icon: "heart"
    default property alias content: body.data
    readonly property int titleHeight: Theme.sizeTitle + Theme.u * 5
    signal moved(real x, real y)

    implicitWidth: body.childrenRect.width + frame.inset * 2 + Theme.u * 2 + Theme.pad * 2
    implicitHeight: body.childrenRect.height + frame.inset * 2 + Theme.u * 2 + titleHeight + Theme.pad * 2

    PxBox {
        id: frame
        anchors.fill: parent
        color: Theme.panel
        shadow: true
    }
    Rectangle {
        id: bar
        x: frame.inset + Theme.u
        y: frame.inset + Theme.u
        width: root.width - 2 * x
        height: root.titleHeight
        color: Theme.menuHeader

        Row {
            anchors.left: parent.left
            anchors.leftMargin: Theme.u * 3
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u * 3
            PxIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.icon
                ink: Theme.edge
                fill: "#ffffff"
                light: Theme.accent3
            }
            PxText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.title
                kind: "title"
            }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: Theme.u * 5
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.u
            PxIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "heartSmall"
                fill: "#ffffff"
                ink: Qt.alpha(Theme.edge, 0.7)
            }
            PxIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: "sparkle"
                fill: "#ffffff"
                light: Theme.accent3
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            drag.target: root
            drag.minimumX: 0
            drag.minimumY: 0
            drag.maximumX: root.parent ? root.parent.width - root.width : 0
            drag.maximumY: root.parent ? root.parent.height - root.height : 0
            onReleased: root.moved(root.x, root.y)
        }
    }
    Item {
        id: body
        x: frame.inset + Theme.u + Theme.pad
        y: bar.y + bar.height + Theme.pad
    }
}
