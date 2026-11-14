---@param name string
---@param callback fun(source: integer, args: string[], rawCommand: string)
---@return fun(source: integer, args: string[], rawCommand: string)
local function withPreExecution(name, callback)
    return function(source, args, rawCommand)
        TriggerEvent('QBCore:Server:PreCommandExecution', source, name, args, rawCommand)
        if WasEventCanceled() then return end

        callback(source, args, rawCommand)
    end
end

---@return table commands qb-core's QBCore.Commands over Cobalt.Commands
return function()
    local commands <const> = {}

    for key, value in pairs(Cobalt.Commands) do
        commands[key] = value
    end

    commands.Add = function(name, help, arguments, argsrequired, callback, permission, ...)
        return Cobalt.Commands.Add(name, help, arguments, argsrequired, withPreExecution(name, callback), permission, ...)
    end

    return commands
end
