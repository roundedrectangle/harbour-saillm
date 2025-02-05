function registerTool(tool) {
    py.call2('register_tool', [tool.name, tool.description, tool.parameters, tool.required])
}

function registerTools(tools) {
    for (var i=0; i<tools.length; i++) {
        py.setHandler("toolcall__"+tools[i].name, tools[i].trigger)
        registerTool(tools[i])
    }
}

function createTool(name, description, trigger, parameters, req) {
    return {
        'name': name, // snake-case function name
        'description': description,
        'trigger': trigger,
        'parameters': typeof parameters === 'undefined' ? {} : parameters, // name: {'type': type, 'description': description}
        'required': typeof req === 'undefined' ? [] : req, // names of required parameters
    }
}
