---@param model string
---@param vehicle SharedVehicle
return function(model, vehicle)
    local hash <const> = joaat(model)

    vehicle.model = model
    vehicle.spawncode = model
    vehicle.hash = hash
    vehicle.shop = vehicle.shops

    CobaltShared.VehicleHashes[hash] = vehicle
end
