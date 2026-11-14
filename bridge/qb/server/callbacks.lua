local allowCallback <const> = require 'server.callbacklimit'

local callbacks <const> = {}

---@type table<string, fun(source: integer, reply: fun(...), ...)>
callbacks.handlers = {}

---@param name string
---@param cb fun(source: integer, reply: fun(...), ...)
function callbacks.create(name, cb)
    local first <const> = callbacks.handlers[name] == nil
    callbacks.handlers[name] = cb
    if not first then return end

    lib.callback.register(name, function(source, ...)
        local current <const> = callbacks.handlers[name]
        if not current then return end
        if not allowCallback(source, name, true) then return end

        local p <const> = promise.new()
        local handled = false

        local function reply(...)
            if handled then return end
            handled = true
            p:resolve({ ... })
        end

        current(source, reply, ...)

        return table.unpack(Citizen.Await(p))
    end)
end

---@param name string
---@param source integer
---@return ...
function callbacks.trigger(name, source, ...)
    if not source then return end

    local args <const> = { ... }

    if type(args[1]) == 'function' then
        local cb <const> = table.remove(args, 1)
        return lib.callback(name, source, cb, table.unpack(args))
    end

    return lib.callback.await(name, source, ...)
end

return callbacks
