function registerTool(tool) {
    py.setHandler("toolcall__"+tool.name, tool.trigger)
    py.call2('register_tool', [tool.name, tool.description, tool.parameters, tool.required, tool.expectReturn])
}

function registerTools(tools) {
    for (var i=0; i<tools.length; i++)
        registerTool(tools[i])
}

function addToolContent(content, i, returnCount, generateAtEnd) {
    shared.pagedViewReference.itemAt(i).chatModel.append({role: 3, content: content})
    if (returnCount > 1) { // VERY not ideal, but works for now, i guess?..
        var cnt = 0
        var full = shared.pagedViewReference.itemAt(i).chatModel-1
        while (cnt != returnCount) {
            if (shared.pagedViewReference.itemAt(i).chatModel.get(full).role === 3) cnt++
            else return;
            full--
        }
    }
    if (typeof generateAtEnd == 'undefined' ? true : generateAtEnd)
        shared.pagedViewReference.itemAt(i).generate()
}

function createTool(name, description, trigger, parameters, req, expectReturn) {
    return {
        'name': name, // snake-case function name
        'description': description,
        'trigger': function(args, i, returnCount) {
            trigger.apply(null, arguments)
            if (typeof expectReturn === 'undefined')
                addToolContent('success for '+name, i, returnCount, false)
        },
        'parameters': typeof parameters === 'undefined' ? {} : parameters, // name: {'type': type, 'description': description}
        'required': typeof req === 'undefined' ? [] : req, // names of required parameters
        'expectReturn': typeof expectReturn === 'undefined' ? true : expectReturn, // currently you have to manually specify the return type yourself in docstring
    }
}
