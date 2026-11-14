Cobalt.Functions = {}

function Cobalt.Functions.GetPlayerData(cb)
    if not cb then return Cobalt.PlayerData end
    cb(Cobalt.PlayerData)
end

---Returns the full character name
---@return string
function Cobalt.Functions.GetName()
    local charinfo <const> = Cobalt.PlayerData.charinfo
    return charinfo.firstname .. ' ' .. charinfo.lastname
end

function Cobalt.Functions.IsWearingGloves()
    local ped <const> = cache.ped
    local armIndex <const> = GetPedDrawableVariation(ped, 3)
    local model <const> = GetEntityModel(ped)
    if model == `mp_m_freemode_01` then
        if Cobalt.Shared.MaleNoGloves[armIndex] then
            return false
        end
    else
        if Cobalt.Shared.FemaleNoGloves[armIndex] then
            return false
        end
    end
    return true
end

function Cobalt.Functions.GetVehicles()
    return GetGamePool('CVehicle')
end

function Cobalt.Functions.GetObjects()
    return GetGamePool('CObject')
end

function Cobalt.Functions.GetPlayers()
    return GetActivePlayers()
end

function Cobalt.Functions.GetPeds(ignoreList)
    local pedPool <const> = GetGamePool('CPed')
    local peds <const> = {}
    local ignoreTable <const> = {}
    ignoreList = ignoreList or {}
    for i = 1, #ignoreList do
        ignoreTable[ignoreList[i]] = true
    end
    for i = 1, #pedPool do
        if not ignoreTable[pedPool[i]] then
            peds[#peds + 1] = pedPool[i]
        end
    end
    return peds
end

function Cobalt.Functions.GetPlate(vehicle)
    if vehicle == 0 then return end
    return Cobalt.Shared.Trim(GetVehicleNumberPlateText(vehicle))
end

function Cobalt.Functions.GetVehicleLabel(vehicle)
    if vehicle == nil or vehicle == 0 then return end
    return GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
end

function Cobalt.Functions.DrawText(x, y, width, height, scale, r, g, b, a, text)
    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x - width / 2, y - height / 2 + 0.005)
end

function Cobalt.Functions.DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(x, y, z, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    local factor <const> = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

function Cobalt.Functions.GetStreetNameAtCoords(coords)
    local mainHash <const>, crossHash <const> = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    return { main = GetStreetNameFromHashKey(mainHash), cross = GetStreetNameFromHashKey(crossHash) }
end

function Cobalt.Functions.GetZoneAtCoords(coords)
    return GetLabelText(GetNameOfZone(coords))
end

function Cobalt.Functions.GetGroundHash(entity)
    local coords <const> = GetEntityCoords(entity)
    local num <const> = StartShapeTestCapsule(coords.x, coords.y, coords.z + 4, coords.x, coords.y, coords.z - 2.0, 1, 1, entity, 7)
    local retval, success, endCoords, surfaceNormal, materialHash, entityHit = GetShapeTestResultEx(num)
    return materialHash, entityHit, surfaceNormal, endCoords, success, retval
end

for functionName, func in pairs(Cobalt.Functions) do
    if type(func) == 'function' then
        exports(functionName, func)
    end
end
