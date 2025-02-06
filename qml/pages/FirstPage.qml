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

        Label {
            y: Theme.paddingLarge
            id: modelText
            text: pagedView.currentItem.getModel()
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeLarge
            width: parent.width
            fontSizeMode: Text.Fit
            horizontalAlignment: Text.AlignHCenter
            minimumPixelSize: Theme.fontSizeExtraSmall

            Component {
                id: modelSelectionDialog
                Dialog {
                    canAccept: false
                    DialogHeader {
                        id: modelSelectionHeader
                        acceptTextVisible: false
                    }
                    SilicaListView {
                        model: modelsModel
                        width: parent.width
                        anchors.top: modelSelectionHeader.bottom
                        anchors.bottom: parent.bottom

                        delegate: ListItem {
                            Label {
                                width: parent.width - 2*Theme.paddingLarge
                                anchors.centerIn: parent
                                truncationMode: TruncationMode.Fade
                                text: _model
                            }

                            onClicked: {
                                pagedView.moveTo(index)
                                canAccept = true
                                accept()
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: pageStack.push(modelSelectionDialog)
            }
        }

        PagedView {
            id: pagedView
            anchors.fill: parent
            anchors.topMargin: modelText.height + Theme.paddingLarge
            model: modelsModel

            delegate: Item {
                width: PagedView.contentWidth
                height: PagedView.contentHeight
                property alias chatModel: chatModel

                function getModel() {return _model}

                SilicaListView {
                    anchors.top: parent.top
                    anchors.bottom: parent.children[1].top
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
                                generate()
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

                function generate() {
                    var history = shared.listModelToJSObject(chatModel)
                    console.log(history, JSON.stringify(history))
                    chatModel.append({role: 1, content: '', toolCalls: '[]'})
                    py.call2('chat', [_model, index, chatModel.count-1, history, toolsSwitch.checked])
                }

                Component.onCompleted: {
                    py.setHandler('chatStart'+_model, function() {modelsModel.get(index).answerPending = true})
                    py.setHandler('chatEnd'+_model, function() {modelsModel.get(index).answerPending = false})
                    py.setHandler('chunk'+_model, function(i, chunk) {chatModel.get(i).content += chunk; console.log(chunk);console.log(JSON.stringify(chatModel.get(i)))})
                    py.setHandler('tool'+_model, function(i, tool) {
                        var calls = JSON.parse(chatModel.get(i).toolCalls)
                        calls.push(tool)
                        chatModel.get(i).toolCalls = JSON.stringify(calls)
                        console.log(chatModel.get(i).toolCalls)

                        console.log(tool)
                        console.log(JSON.stringify(chatModel.get(i)))
                    })
                }
            }
        }
    }

    ListModel { id: modelsModel }

    Component.onCompleted: {
        py.setHandler('model', function(model) { modelsModel.append({_model: model, answerPending: false}) })
        py.initialize(pagedView, function() {
            py.call2('request_models')
        })
    }
}
