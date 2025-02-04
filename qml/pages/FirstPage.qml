import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
    allowedOrientations: Orientation.All
    SilicaFlickable {
        anchors.fill: parent

        PullDownMenu {
            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
        }

        PagedView {
            anchors.fill: parent
            anchors.topMargin: Theme.paddingLarge
            model: modelsModel

            delegate: Item {
                width: PagedView.contentWidth
                height: PagedView.contentHeight
                Label {
                    text: model
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeLarge
                    width: parent.width
                    fontSizeMode: Text.Fit
                    horizontalAlignment: Text.AlignHCenter
                    minimumPixelSize: Theme.fontSizeExtraSmall
                }

                SilicaListView {
                    anchors.top: parent.children[0].bottom
                    anchors.bottom: parent.children[2].top
                    width: parent.width
                    model: chatModel
                    clip: true

                    delegate: Label {
                        width: parent.width
                        text: content
                        wrapMode: Text.Wrap
                        horizontalAlignment: role == 0 ? Text.AlignRight : (role == 1 ? Text.AlignLeft : Text.AlignHCenter)
                    }
                }

                Column {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    Row {
                        width: parent.width - Theme.paddingLarge
                        TextField {
                            id: askField
                            width: parent.width - askButton.width
                            label: qsTr("Ask me anything...")
                        }
                        IconButton {
                            id: askButton
                            icon.source: "image://theme/icon-m-chat"
                            enabled: !answerPending
                            onClicked: {
                                chatModel.append({role: 0, content: askField.text})
                                var history = shared.listModelToJSObject(chatModel)
                                console.log(history, JSON.stringify(history))
                                chatModel.append({role: 1, content: ''})
                                py.call2('chat', [model, history, toolsSwitch.checked])
                                askField.text = ""
                            }
                        }
                    }
                    Row {
                        Button {
                            text: qsTr("Clear")
                            onClicked: chatModel.clear()
                        }
                        Switch {
                            id: toolsSwitch
                            icon.source: "image://theme/icon-m-attach"
                        }
                    }
                }

                ListModel {
                    id: chatModel
                }
                property bool answerPending

                Component.onCompleted: {
                    py.setHandler('chat_start', function() {answerPending = true;console.log("chat-start")})
                    py.setHandler('chat_end', function() {answerPending = false;console.log("chat-end")})
                    py.setHandler('chunk'+model, function(chunk) {chatModel.get(chatModel.count-1).content += chunk; console.log(chunk);console.log(JSON.stringify(chatModel.get(chatModel.count-1)))})
                }
            }
        }
    }

    ListModel {
        id: modelsModel
    }

    Component.onCompleted: {
        py.setHandler('model', function(model) { modelsModel.append({model: model}) })
        py.initialize(function() {
            py.call2('request_models')
        })
    }
}
