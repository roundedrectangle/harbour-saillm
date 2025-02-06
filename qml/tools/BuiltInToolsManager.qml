import QtQuick 2.0
import Nemo.DBus 2.0
import Connman 0.2

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

    /*NetworkManager { id: nm }

    NetworkTechnology {
        id: nt
        function toggle(technology) {

        }
    }*/

    function registerTools() {
        if (initialized) return
        initialized = true

        shared.createTool('toggle_flashlight', 'Toggles flashlight', flashlight.toggle)
        shared.createTool('open_website', 'Opens the specified website in the web browser', function(args) {
            if (typeof args.website != 'undefined') Qt.openUrlExternally(args.website)
        }, {'website': {'description': 'The website URL to open'}}, ['website'])
        shared.createTool('get_time', "Get current time in user's locale format\n\nReturns:\n\tstring: the current time",
                          function(args, i, returnCount) {
                              shared.pagedViewReference.itemAt(i).chatModel.append({role: 3, content: new Date().toLocaleString()})
                              if (returnCount > 1) { // VERY not ideal, but works for now, i guess?..
                                  var cnt = 0
                                  var full = shared.pagedViewReference.itemAt(i).chatModel-1
                                  while (cnt != returnCount) {
                                      if (shared.pagedViewReference.itemAt(i).chatModel.get(full).role === 3) cnt++
                                      else return;
                                      full--
                                  }
                              }
                              shared.pagedViewReference.itemAt(i).generate()
                          }, {}, [], true)
    }
}
