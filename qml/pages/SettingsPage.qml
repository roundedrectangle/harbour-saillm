import QtQuick 2.0
import Sailfish.Silica 1.0
import '../components'

Page {
    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height
        Column {
            id: column
            width: parent.width

            PageHeader { title: "SaiLLM" }

            IconComboBox {
                label: qsTr("Provider")
                description: qsTr("OpenAI might be broken")
                icon.source: "image://theme/icon-m-wizard"
                menu: ContextMenu {
                    MenuItem {
                        visible: false
                        text: qsTr("Unset")
                    }
                    MenuItem { text: qsTr("Ollama") }
                    MenuItem {
                        text: qsTr("OpenAI")
                    }
                }
                currentIndex: settings.provider
                onCurrentItemChanged: settings.provider = currentIndex
            }

            Column {
                width: parent.width
                visible: settings.provider === 2
                SectionHeader { text: qsTr("OpenAI") }
                TextField {
                    label: qsTr("API key")
                    text: settings.openaiKey
                    onTextChanged: settings.openaiKey = text
                }
                TextField {
                    label: qsTr("Base URL")
                    description: qsTr("Should be left empty in most cases")
                    text: settings.openaiHost
                    onTextChanged: settings.openaiHost = text
                }
            }

            Column {
                width: parent.width
                visible: settings.provider === 1
                SectionHeader { text: qsTr("Ollama") }
                TextField {
                    label: qsTr("Host")
                    text: settings.ollamaHost
                    onTextChanged: settings.ollamaHost = text
                }
            }

            SectionHeader { text: qsTr("Tools") }
            Label {
                width: parent.width - 2*x
                x: Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                text: qsTr("Applying tools settings requires app restart")
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
                bottomPadding: Theme.paddingMedium
            }
            ExpandingSectionGroup {
                ExpandingSection {
                    title: qsTr("Default tools")
                    content.sourceComponent: Column {
                        ToolSwitch {
                            key: 'toggle_flashlight'
                            icon.source: "image://theme/icon-m-flashlight"
                            text: qsTr("Flashlight")
                        }
                        ToolSwitch {
                            key: 'open_website'
                            icon.source: "image://theme/icon-m-website"
                            text: qsTr("Website opening")
                        }
                        ToolSwitch {
                            key: 'get_time'
                            //icon.source: "image://theme/icon-m-website"
                            text: qsTr("Time and date")
                        }
                    }
                }
                ExpandingSection {
                    title: qsTr("External tools")
                    content.sourceComponent: Column {
                        Label {
                            width: parent.width - 2*x
                            x: Theme.horizontalPageMargin
                            wrapMode: Text.Wrap
                            text: qsTr("Not yet supported")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                            bottomPadding: Theme.paddingMedium
                        }
                    }
                }
                ExpandingSection {
                    title: qsTr("Custom tools")
                    content.sourceComponent: Column {
                        Label {
                            width: parent.width - 2*x
                            x: Theme.horizontalPageMargin
                            wrapMode: Text.Wrap
                            text: qsTr("Not yet supported")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.secondaryHighlightColor
                            bottomPadding: Theme.paddingMedium
                        }
                    }
                }
            }

            SectionHeader { text: qsTr("Other") }
            TextSwitch {
                text: qsTr('Show when no content was supplied when a message is available as *No content*')
                checked: settings.noContent
                onCheckedChanged: settings.noContent = checked
            }

            SectionHeader { text: qsTr("Debugging") }
            TextSwitch {
                text: qsTr("Show info messages in notifications")
                checked: settings.infoInNotifications
                onCheckedChanged: settings.infoInNotifications = checked
            }
        }
    }
}
