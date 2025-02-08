import QtQuick 2.0
import Sailfish.Silica 1.0

ListItem {
    id: root
    property bool isOutbound
    property alias text: label.text
    property int role
    contentHeight: container.height

    Item {
        id: topLevelContainer
        x: role == 0 ? null : Theme.horizontalPageMargin
        y: Theme.paddingMedium
        width: parent.width - 2*x
        height: container.height + 2*y

        RoundedRect {
            id: background
            radius: Theme.paddingLarge
            anchors { fill: container; margins: 2*Theme.paddingMedium/3 }
            roundedCorners: isOutbound ? bottomLeft | topRight : bottomRight | topLeft
            color: down ? Theme.highlightBackgroundColor : Theme.secondaryColor
            opacity: down ?
                         (isOutbound ? 0.7*Theme.opacityFaint : 1.0*Theme.opacityFaint) :
                         (isOutbound ? 0.4*Theme.opacityFaint : 0.8*Theme.opacityFaint)
        }

        Item {
            id: container
            width: Math.min(parent.width, Math.max(label.implicitWidth, Theme.itemSizeSmall)+2*label.x+2*Theme.paddingMedium)
            height: label.height + 2*Theme.paddingMedium
            anchors.right: role == 0 ? parent.right : undefined
            anchors.horizontalCenter: (role != 0 && role != 1) ? parent.horizontalCenter : undefined
            Label {
                id: label
                x: Theme.paddingMedium
                y: x
                width: parent.width - 2*x
                wrapMode: Text.Wrap
                visible: !settings.hideSystem || role == 0 || role == 1
                height: implicitHeight + 2*y
            }
        }
    }

    /*Item {
        id: container
        x: Theme.horizontalPageMargin
        width: parent.width - 2*x
        height: innerContainer.height + 2*Theme.paddingLarge
        Item {
            id: innerContainer
            x: Theme.paddingLarge
            width: parent.width - 2*x
            height: label.height
            Label {
                id: label
                width: Math.min(implicitWidth + 2*Theme.paddingLarge, parent.width)
                wrapMode: Text.Wrap
                anchors.right: role == 0 ? parent.right : undefined
                anchors.horizontalCenter: (role != 0 && role != 1) ? parent.horizontalCenter : undefined
                horizontalAlignment: role == 0 ? Text.AlignRight : (role == 1 ? Text.AlignLeft : Text.AlignHCenter)
                visible: !settings.hideSystem || role == 0 || role == 1
                height: Math.max(implicitHeight, Theme.itemSizeSmall)
            }
        }
    }*/

    menu: Component { ContextMenu {
        MenuItem {
            text: qsTr("Copy")
            onClicked: Clipboard.text = label.text
        }
    } }
}
