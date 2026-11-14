---@type table<string, integer> GTA vehicle class of each vehicle category
local CATEGORY_CLASSES <const> = {
    compacts = 0,
    sedans = 1,
    suvs = 2,
    suv = 2,
    coupes = 3,
    muscle = 4,
    sportsclassics = 5,
    sportsclassic = 5,
    sports = 6,
    super = 7,
    motorcycles = 8,
    offroad = 9,
    industrial = 10,
    utility = 11,
    vans = 12,
    cycles = 13,
    boats = 14,
    helicopters = 15,
    planes = 16,
    service = 17,
    emergency = 18,
    military = 19,
    commercial = 20,
    trains = 21,
    openwheel = 22,
}

---@param model string
---@param vehicle SharedVehicle
return function(model, vehicle)
    local hash <const> = joaat(model)

    vehicle.model = model
    vehicle.spawncode = model
    vehicle.hash = hash
    vehicle.shop = vehicle.shops
    vehicle.class = CATEGORY_CLASSES[vehicle.category]

    CobaltShared.VehicleHashes[hash] = vehicle
end
