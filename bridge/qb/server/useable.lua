---@class QbUseableItem
---@field func fun(source: integer, item: table)
---@field resource? string

local Useable <const> = {}

---@type table<string, QbUseableItem>
Useable.items = {}

---@param data unknown
---@return function?
local function callbackOf(data)
    if type(data) == 'function' then return data end

    if type(data) ~= 'table' then return end

    if rawget(data, '__cfx_functionReference') then return data end

    local nested <const> = data.cb or data.callback

    if type(nested) == 'table' and rawget(nested, '__cfx_functionReference') then return nested end
end

---@param name string
---@param data function | table
function Useable.create(name, data)
    local func <const> = callbackOf(data)

    if not func then return end

    Useable.items[name] = { func = func, resource = GetInvokingResource() }
end

---@param name string
---@return QbUseableItem?
function Useable.find(name)
    return Useable.items[name]
end

---@param source integer
---@param item string | table
function Useable.use(source, item)
    local useable <const> = Useable.items[type(item) == 'table' and item.name or item]

    if useable then useable.func(source, item) end
end

AddEventHandler('onResourceStop', function(resource)
    for name, useable in pairs(Useable.items) do
        if useable.resource == resource then
            Useable.items[name] = nil
        end
    end
end)

return Useable
