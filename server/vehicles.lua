local VehicleFile <const> = require 'server.vehicle_file'
local indexVehicle <const> = require 'shared.vehicle'

local DATA_FILE <const> = 'data/vehicles.lua'
local FIELDS <const> = { 'name', 'brand', 'category', 'price', 'type', 'shops', 'image', 'enabled' }

---@param model unknown
---@return boolean
local function validModel(model)
    return type(model) == 'string' and #model <= 32 and model:match('^[%w_%-]+$') ~= nil
end

---Adds vehicles to data/vehicles.lua or changes fields on existing ones, then saves the file once.
---@param vehicles table<string, table> fields by model; only the listed fields change
---@return string[] changed the models that were added or updated
local function SetVehicles(vehicles)
    local changed <const> = {}

    if type(vehicles) ~= 'table' then return changed end

    for rawModel, fields in pairs(vehicles) do
        local model <const> = validModel(rawModel) and rawModel:lower()

        if model and type(fields) == 'table' then
            local vehicle <const> = CobaltShared.Vehicles[model] or {}

            for _, field in ipairs(FIELDS) do
                if fields[field] ~= nil then vehicle[field] = fields[field] end
            end

            if vehicle.name and vehicle.category and vehicle.price and vehicle.type then
                CobaltShared.Vehicles[model] = vehicle
                indexVehicle(model, vehicle)
                changed[#changed + 1] = model
            end
        end
    end

    if #changed > 0 then
        table.sort(changed)
        SaveResourceFile(cache.resource, DATA_FILE, VehicleFile.serialise(CobaltShared.Vehicles), -1)
    end

    return changed
end

Cobalt.Functions.SetVehicles = SetVehicles
