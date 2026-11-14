local VehicleFile <const> = {}

local FIELDS <const> = { 'name', 'brand', 'category', 'price', 'type', 'shops', 'image', 'enabled' }

---@param value unknown
---@return string
local function literal(value)
    if type(value) == 'string' then return ('%q'):format(value) end

    if type(value) == 'table' then
        local items <const> = {}

        for i, item in ipairs(value) do items[i] = literal(item) end

        return '{ ' .. table.concat(items, ', ') .. ' }'
    end

    return tostring(value)
end

---@param model string
---@return string
local function key(model)
    if model:match('^[%a_][%w_]*$') then return model end

    return ('[%q]'):format(model)
end

---@param entry SharedVehicle
---@return string
local function line(entry)
    local fields <const> = {}

    for _, field in ipairs(FIELDS) do
        local value <const> = entry[field]

        if value ~= nil and not (field == 'enabled' and value == true) then
            fields[#fields + 1] = ('%s = %s'):format(field, literal(value))
        end
    end

    return '{ ' .. table.concat(fields, ', ') .. ' }'
end

---@param vehicles table<string, SharedVehicle>
---@return string
function VehicleFile.serialise(vehicles)
    local models <const> = {}

    for model in pairs(vehicles) do models[#models + 1] = model end

    table.sort(models)

    local lines <const> = { '---@type table<string, SharedVehicle>', 'return {' }

    for _, model in ipairs(models) do
        lines[#lines + 1] = ('    %s = %s,'):format(key(model), line(vehicles[model]))
    end

    lines[#lines + 1] = '}'

    return table.concat(lines, '\n') .. '\n'
end

return VehicleFile
