function registerTool(tool) {
    py.setHandler("toolcall__"+tool.name, tool.trigger)
    py.call2('register_tool', [tool.name, tool.description, tool.parameters, tool.required, tool.expectReturn])
}

function registerTools(tools) {
    for (var i=0; i<tools.length; i++)
        registerTool(tools[i])
}

function createTool(name, description, trigger, parameters, req, expectReturn) {
    return {
        'name': name, // snake-case function name
        'description': description,
        'trigger': trigger,
        'parameters': typeof parameters === 'undefined' ? {} : parameters, // name: {'type': type, 'description': description}
        'required': typeof req === 'undefined' ? [] : req, // names of required parameters
        'expectReturn': typeof expectReturn === 'undefined' ? false : expectReturn, // currently you have to manually specify the return type yourself in docstring
    }
}
