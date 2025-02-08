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
            MenuItem {
                text: qsTr("Clear")
                onClicked: pagedView.currentItem.chatModel.clear()
                visible: !!pagedView.currentItem
                enabled: visible && !pagedView.currentItem._answerPending && pagedView.currentItem.chatModel.count != 0
            }
        }

        Label {
            y: Theme.paddingLarge
            id: modelText
            text: !!pagedView.currentItem ? pagedView.currentItem.getModel() : qsTr("Loading")
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
                        acceptText: ""
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
                property bool _answerPending: answerPending

                function getModel() {return _model}

                SilicaListView {
                    anchors.top: parent.top
                    anchors.bottom: parent.children[1].top
                    width: parent.width
                    model: chatModel
                    clip: true
                    verticalLayoutDirection: ListView.BottomToTop

                    delegate: Label {
                        width: parent.width
                        text: content
                        wrapMode: Text.Wrap
                        horizontalAlignment: role == 0 ? Text.AlignRight : (role == 1 ? Text.AlignLeft : Text.AlignHCenter)
                        visible: !settings.hideSystem || role == 0 || role == 1
                    }
                }

                Column {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    Row {
                        width: parent.width - Theme.paddingLarge
                        TextArea {
                            id: askField
                            width: parent.width - askButton.width - toolsButton.width
                            label: qsTr("Ask me anything...")

                            hideLabelOnEmptyField: false
                            labelVisible: false
                        }
                        IconButton {
                            id: toolsButton
                            visible: settings.manualTools
                            icon.source: "image://theme/icon-m-game-controller"
                            onClicked: settings.toolsSupport = !settings.toolsSupport
                            icon.opacity: settings.toolsSupport ? 1.0 : Theme.opacityHigh
                            width: visible ? Theme.itemSizeSmall : 0
                            anchors.bottom: parent.bottom
                        }
                        IconButton {
                            id: askButton
                            icon.source: "image://theme/icon-m-chat"
                            enabled: !answerPending
                            onClicked: {
                                chatModel.insert(0, {role: 0, content: askField.text})
                                generate()
                                askField.text = ""
                            }
                            anchors.bottom: parent.bottom
                        }
                    }
                }

                ListModel {
                    id: chatModel
                }

                function generate() {
                    var history = shared.listModelToJSObject(chatModel)
                    console.log(history, JSON.stringify(history))
                    chatModel.insert(0, {role: 1, content: '', toolCalls: '[]'})
                    py.call2('chat', [_model, index, chatModel.count, history, settings.toolsSupport])
                }

                Component.onCompleted: {
                    py.setHandler('chatStart'+_model, function() {modelsModel.get(index).answerPending = true})
                    py.setHandler('chatEnd'+_model, function() {modelsModel.get(index).answerPending = false})
                    py.setHandler('chunk'+_model, function(i, chunk) {chatModel.get(chatModel.count-i).content += chunk; console.log(chunk);console.log(JSON.stringify(chatModel.get(chatModel.count-i)))})
                    py.setHandler('tool'+_model, function(i, tool) {
                        var calls = JSON.parse(chatModel.get(chatModel.count-i).toolCalls)
                        calls.push(tool)
                        chatModel.get(chatModel.count-i).toolCalls = JSON.stringify(calls)
                        console.log(chatModel.get(chatModel.count-i).toolCalls)

                        console.log(tool)
                        console.log(JSON.stringify(chatModel.get(chatModel.count-i)))
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
