import QtQuick 2.0
import Sailfish.Silica 1.0
import '../components'

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

        PagedView {
            id: pagedView
            anchors.fill: parent
            //anchors.topMargin: modelLabel.height + Theme.paddingLarge
            anchors.bottomMargin: textArea.height
            model: modelsModel

            delegate: Item {
                width: PagedView.contentWidth
                height: PagedView.contentHeight
                property alias chatModel: chatModel
                property bool _answerPending: answerPending
                property var modelName: _model

                Label {
                    id: modelLabel
                    y: Theme.paddingLarge
                    text: !!pagedView.currentItem ? pagedView.currentItem.modelName : qsTr("Loading")
                    color: Theme.highlightColor
                    font.pixelSize: Theme.fontSizeLarge
                    width: parent.width
                    fontSizeMode: Text.Fit
                    horizontalAlignment: Text.AlignHCenter
                    minimumPixelSize: Theme.fontSizeExtraSmall
                    height: implicitHeight + Theme.paddingLarge

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

                SilicaListView {
                    width: parent.width
                    anchors.bottom: parent.bottom
                    anchors.top: modelLabel.bottom
                    model: chatModel
                    clip: true
                    verticalLayoutDirection: ListView.BottomToTop

                    delegate: Message {
                        text: content
                        role: model.role
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
                    py.setHandler('chunk'+_model, function(i, chunk) {chatModel.get(chatModel.count-i).content += chunk})//; console.log(chunk);console.log(JSON.stringify(chatModel.get(chatModel.count-i)))})
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

            onCurrentIndexChanged: conf.lastModel = currentItem.modelName
        }

        Row {
            id: textArea
            anchors.bottom: parent.bottom
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
                enabled: !!pagedView.currentItem && !pagedView.currentItem._answerPending
                onClicked: {
                    pagedView.currentItem.chatModel.insert(0, {role: 0, content: askField.text})
                    pagedView.currentItem.generate()
                    askField.text = ""
                }
                anchors.bottom: parent.bottom
            }
        }
    }

    ListModel { id: modelsModel }

    Component.onCompleted: {
        py.setHandler('model', function(model) {
            modelsModel.append({_model: model, answerPending: false})
            if (conf.lastModel == model) pagedView.moveTo(modelsModel.count-1)
        })
        py.initialize(pagedView, function() {
            py.call2('request_models')
        })
    }
}
