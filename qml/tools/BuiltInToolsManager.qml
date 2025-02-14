import QtQuick 2.0
import Nemo.DBus 2.0
//import Connman 0.2
import 'ToolRegistry.js' as ToolRegistry
//import com.jolla.settings 1.0
//import com.jolla.connection 1.0

Item {
    visible: false
    property bool initialized

    DBusInterface {
        id: flashlight
        bus: DBus.SessionBus
        service: "com.jolla.settings.system.flashlight"
        path: "/com/jolla/settings/system/flashlight"
        iface: "com.jolla.settings.system.flashlight"

        function toggle() { call('toggleFlashlight') }
    }


    /*ConnectionAgent { id: ca }
    NetworkManager { id: nm }
    NetworkTechnology {
        id: nt
        path: nm.WifiTechnology
        /*function toggle(technology) {
            //nm.WifiTechnology
            path = technology
            if (tethering) {
                notifier.showError(qsTr("Could not enable %1 because of tethering").arg(technology))
                return
            }
            powered = !powered
            console.log(powered, path)
        }/
        Component.onCompleted: {
            console.log(powered)
            powered = false
            console.log(powered)
        }
    }*/

    /*FavoritesModel {
        id: simpleFavModel
        filter: 'grid_favorites_simple'
        key: '/desktop/lipstick-jolla-home/topmenu_shortcuts'
        userModifiedKey: '/desktop/lipstick-jolla-home/topmenu_shortcuts_user'
    }

    Repeater {
        model: simpleFavModel
        delegate: Item {
            Component.onCompleted: console.log(model)
        }
    }*/

    /*Loader {
        source: Qt.resolvedUrl('/usr/share/jolla-settings/pages/wlan/WlanSwitch.qml')
        id: wlan
        onStatusChanged: if (status == Loader.Ready) {
                             item.onToggled.connect(function() {console.log("Hi There!")})
                             console.log(item.active, item.checked, item.icon.source)
                             item.toggled()
                             console.log(item.active, item.checked, item.icon.source)
                         } else console.log(status, Loader.Error)
    }*/

    //Component.onCompleted: console.log(nt.toggle(nm.WifiTechnology))

    function registerTools() {
        if (initialized) return
        initialized = true

        shared.createTool('toggle_flashlight', 'Toggles flashlight', flashlight.toggle)
        shared.createTool('open_website', 'Opens the specified website in the web browser', function(args) {
            if (typeof args.website != 'undefined') Qt.openUrlExternally(args.website)
        }, {'website': {'description': 'The website URL to open'}}, ['website'])
        shared.createTool('get_datetime', "Get current time in user's locale format\n\nReturns:\n\tstring: the current time",
                          function(args, i, returnCount) {
                              ToolRegistry.addToolContent(new Date().toLocaleString(), i, returnCount)
                          }, {}, [], true)
        //shared.createTool('toggle_wlan', "Enables or disables WLAN connection", function() {
            //nt.toggle(nm.WifiTechnology)
            /*if (nt.tethering) ca.stopTethering("wifi", true)
            else {
                nt.powered = !nt.powered
            }*/
            //wlan.item.toggled()
        //})
    }
}
