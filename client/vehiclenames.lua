---@param vehicle SharedVehicle
---@return string
local function displayName(vehicle)
    local name <const>, brand <const> = vehicle.name, vehicle.brand

    if not brand or brand == '' then return name end

    local first <const>, last <const> = name:lower():find(brand:lower(), 1, true)

    if not first then return name end

    local model <const> = (name:sub(1, first - 1) .. name:sub(last + 1)):gsub('%s+', ' '):match('^%s*(.-)%s*$')

    return ('%s %s'):format(brand, model)
end

for _, vehicle in pairs(CobaltShared.Vehicles) do
    if vehicle.hash and vehicle.hash ~= 0 then
        AddTextEntryByHash(vehicle.hash, displayName(vehicle))
    end
end
