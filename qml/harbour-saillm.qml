import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import io.thp.pyotherside 1.5
import Nemo.Configuration 1.0
import Nemo.DBus 2.0
import Nemo.Notifications 1.0
import 'tools/ToolRegistry.js' as ToolRegistry
import 'tools'

ApplicationWindow {
    initialPage: Component { FirstPage { } }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    Notification { // Notifies about app status
        id: notifier
        replacesId: 0
        onReplacesIdChanged: if (replacesId !== 0) replacesId = 0
        isTransient: !settings.infoInNotifications

        function showInfo(summary, text) {
            appIcon = "image://theme/icon-lock-information"
            notifier.summary = summary || ''
            body = text || ''
            publish()
        }

        function showError(summary, text) {
            appIcon = "image://theme/icon-lock-warning"
            notifier.summary = summary || ''
            body = text || ''
            publish()
            console.log(text)
        }
    }

    DBusInterface {
        id: globalProxy
        bus: DBus.SystemBus
        service: 'net.connman'
        path: '/'
        iface: 'org.sailfishos.connman.GlobalProxy'

        signalsEnabled: true
        function propertyChanged(name, value) { updateProxy() }

        property string url
        Component.onCompleted: updateProxy()

        function updateProxy() {
            // Sets the `url` to the global proxy URL, if enabled. Only manual proxy is supported, only the first address is used and excludes are not supported: FIXME
            // When passing only one parameter, you can pass it without putting it into an array (aka [] brackets)
            typedCall('GetProperty', {type: 's', value: 'Active'}, function (active){
                if (active) typedCall('GetProperty', {type: 's', value: 'Configuration'}, function(conf) {
                    if (conf['Method'] === 'manual') url = conf['Servers'][0]
                    else url=''
                }, function(e){url=''}); else url=''
            }, function(e){url=''})
        }
    }

    DBusInterface {
        id: flashlight
        bus: DBus.SessionBus
        service: "com.jolla.settings.system.flashlight"
        path: "/com/jolla/settings/system/flashlight"
        iface: "com.jolla.settings.system.flashlight"

        function toggle() { call('toggleFlashlight') }
    }

    Python {
        id: py
        property bool initialized: false

        onError: notifier.showError(qsTranslate("Errors", "Python error"), traceback)
        onReceived: console.log("got message from python: " + data)

        function call2(name, args, callback) { call('main.'+name, args, callback) }

        function initialize(callback) {
            if (initialized) return

            setHandler("toolsError", function(e) { notifier.showError(qsTranslate("Errors", "Model %1 does not support tools").arg(e)) })
            setHandler('argumentsParseError', function(e){ notifier.showError(qsTranslate("Errors", "Tool got invalid arguments, defaulting to empty", e)) })

            addImportPath(Qt.resolvedUrl('../python'))
            importModule('main', function() {
                call2('set_settings', [globalProxy.url, settings.noContent, settings.provider, {
                                          'ollama': {'host': settings.ollamaHost},
                                          'openai': {'host': settings.openaiHost, 'key': settings.openaiHost},
                                      }], function(result) {
                                        if (!result) {
                                            // todo: show that everything is broken
                                            notifier.showInfo(qsTr("failed"))
                                            return
                                        }
                                        notifier.showInfo(qsTr("good"))

                                        notifier.showInfo(qsTr("initializing tools"))
                                        ToolRegistry.registerTools(shared.tools)
                                        notifier.showInfo(qsTr("hope it works"))

                                        callback()
                                        initialized = true
                                      })
            })
        }
    }

    ConfigurationGroup {
        id: conf
        path: '/apps/harbour-saillm'

        ConfigurationGroup {
            id: settings
            path: "settings"

            property int provider: 0
            property bool noContent
            property bool infoInNotifications: false

            // ollama
            property string ollamaHost: ''

            // openai
            property string openaiHost: ''
            property string openaiKey: ''
        }

        ConfigurationGroup {
            id: toolsConfiguration
            path: "tools"
            // Add tools here if you want them to be enabled by default. Otherwise you can skip this

            property bool toggle_flashlight: true
            property bool open_website: true
        }
    }

    BuiltInToolsManager { id: defaultToolManager }

    QtObject {
        id: shared

        function listModelToJSObject(model) {
            var res = []
            for (var i=0; i<model.count; i++)
                res.push(eval(JSON.stringify(model.get(i))))
            return res
        }

        property var tools: []
        function createTool() {
            console.log(JSON.stringify(tools))
            if (!toolsConfiguration.value(arguments[0])) return
            //var args = Array.prototype.slice.call(arguments)
            tools.push(ToolRegistry.createTool.apply(null, arguments))
            console.log(JSON.stringify(tools))
        }

        Component.onCompleted: defaultToolManager.registerTools()
    }
}
