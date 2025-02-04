function registerTool(tool) {
    py.call2('register_tool', [tool.name, tool.description])
}

function registerTools(tools) {
    for (var i=0; i<tools.length; i++) {
        py.setHandler("toolcall__"+tools[i].name, tools[i].trigger)
        registerTool(tools[i])
    }
}

function createTool(comp, name, description, trigger) {
    return comp.createObject(null, {'name': name, 'description': description, 'trigger': trigger})
}
