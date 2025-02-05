import QtQuick 2.0

QtObject {
    property string name // snake-style function name
    property string description
    property var parameters: ({}) // name: {'type': type, 'description': description}
    property var required: [] // names of required parameters
    property var trigger // signal?
}
