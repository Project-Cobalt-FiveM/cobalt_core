local qb <const> = {}

---@param coords? vector3 | { x: number, y: number, z: number }
---@return vector3
local function toCoords(coords)
    if not coords then return GetEntityCoords(cache.ped) end

    return vec3(coords.x, coords.y, coords.z)
end

---@param name string
---@param cb fun(reply: fun(...), ...)
function qb.CreateClientCallback(name, cb)
    lib.callback.register(name, function(...)
        local p <const> = promise.new()
        local handled = false

        local function reply(...)
            if handled then return end
            handled = true
            p:resolve({ ... })
        end

        cb(reply, ...)

        return table.unpack(Citizen.Await(p))
    end)
end

---@param name string
---@return ...
function qb.TriggerCallback(name, ...)
    local args <const> = { ... }

    if type(args[1]) == 'function' then
        local cb <const> = table.remove(args, 1)
        return lib.callback(name, false, cb, table.unpack(args))
    end

    return lib.callback.await(name, false, ...)
end

qb.TriggerServerCallback = qb.TriggerCallback

qb.LoadModel = lib.requestModel
qb.RequestAnimDict = lib.requestAnimDict
qb.LoadAnimSet = lib.requestAnimSet
qb.LoadParticleDictionary = lib.requestNamedPtfxAsset
qb.GetVehicleProperties = lib.getVehicleProperties
qb.SetVehicleProperties = lib.setVehicleProperties

---@param coords vector3
---@return StreetName
function qb.GetStreetNametAtCoords(coords)
    return Cobalt.Functions.GetStreetNameAtCoords(coords)
end

---@param coords? vector3
---@param distance? number
---@return integer[] players player indices, the local player included
function qb.GetPlayersFromCoords(coords, distance)
    local players <const> = {}

    for i, nearby in ipairs(lib.getNearbyPlayers(toCoords(coords), distance or 5, true)) do
        players[i] = nearby.id
    end

    return players
end

---@param coords? vector3
---@return integer player, number distance -1 and -1 when nobody is within 5 meters
function qb.GetClosestPlayer(coords)
    local origin <const> = toCoords(coords)
    local player <const>, _, playerCoords <const> = lib.getClosestPlayer(origin, 5, false)
    if not player then return -1, -1 end

    return player, #(playerCoords - origin)
end

---@param coords? vector3
---@param ignoreList? integer[]
---@return integer ped, number distance -1 and -1 when there is none
function qb.GetClosestPed(coords, ignoreList)
    local origin <const> = toCoords(coords)
    local closestPed, closestDistance = -1, -1

    for _, ped in ipairs(Cobalt.Functions.GetPeds(ignoreList)) do
        local distance <const> = #(GetEntityCoords(ped) - origin)

        if closestDistance == -1 or distance < closestDistance then
            closestPed, closestDistance = ped, distance
        end
    end

    return closestPed, closestDistance
end

---@param coords? vector3
---@return integer vehicle, number distance -1 and -1 when there is none
function qb.GetClosestVehicle(coords)
    local origin <const> = toCoords(coords)
    local vehicle <const>, vehicleCoords <const> = lib.getClosestVehicle(origin, math.huge, true)
    if not vehicle then return -1, -1 end

    return vehicle, #(vehicleCoords - origin)
end

---@param coords? vector3
---@return integer object, number distance -1 and -1 when there is none
function qb.GetClosestObject(coords)
    local origin <const> = toCoords(coords)
    local object <const>, objectCoords <const> = lib.getClosestObject(origin, math.huge)
    if not object then return -1, -1 end

    return object, #(objectCoords - origin)
end

---@param ped integer
---@param model integer | string
---@param boneId integer
---@param vertex? boolean
---@return integer prop
function qb.AttachProp(ped, model, boneId, x, y, z, xR, yR, zR, vertex)
    local modelHash <const> = lib.requestModel(model)
    local prop <const> = CreateObject(modelHash, 1.0, 1.0, 1.0, true, true, false)

    local bone <const> = GetPedBoneIndex(ped, boneId)

    AttachEntityToEntity(prop, ped, bone, x, y, z, xR, yR, zR, true, true, false, true, vertex and 0 or 2, true)
    SetModelAsNoLongerNeeded(modelHash)

    return prop
end

return qb
