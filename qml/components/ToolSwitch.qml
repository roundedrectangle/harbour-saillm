import QtQuick 2.0
import Sailfish.Silica 1.0

IconTextSwitch {
    property string key
    checked: !!toolsConfiguration.value(key)
    onCheckedChanged: toolsConfiguration.setValue(key, checked)
}
