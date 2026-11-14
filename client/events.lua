RegisterNetEvent('cobalt_core:Client:OnPlayerLoaded', function()
    local ped <const> = cache.ped
    local pd <const> = Cobalt.Functions.GetPlayerData()
    local maxHp <const> = GetEntityMaxHealth(ped)
    local savedHp <const> = pd and pd.metadata and pd.metadata.health
    if savedHp and savedHp > 0 and savedHp <= maxHp then
        SetEntityHealth(ped, savedHp)
    else
        SetEntityHealth(ped, maxHp)
    end
    if pd and pd.metadata and (pd.metadata.armor or 0) > 0 then
        SetPedArmour(ped, pd.metadata.armor)
    end
    local pvp <const> = GlobalState.pvp == true
    SetCanAttackFriendly(ped, pvp, false)
    NetworkSetFriendlyFireOption(pvp)
end)

RegisterNetEvent('cobalt_core:Client:PvpHasToggled', function(pvp_state)
    SetCanAttackFriendly(cache.ped, pvp_state, false)
    NetworkSetFriendlyFireOption(pvp_state)
end)

---@param hash integer
---@return string
local function vehicleTypeOf(hash)
    if IsThisModelABike(hash) or IsThisModelABicycle(hash) or IsThisModelAQuadbike(hash) then return 'bike' end
    if IsThisModelAHeli(hash) then return 'heli' end
    if IsThisModelAPlane(hash) then return 'plane' end
    if IsThisModelABoat(hash) or IsThisModelAJetski(hash) then return 'boat' end
    if IsThisModelATrain(hash) then return 'train' end
    if GetVehicleClassFromName(hash) == 14 then return 'submarine' end

    return 'automobile'
end

lib.callback.register('cobalt_core:client:vehicleType', function(model)
    local hash <const> = type(model) == 'string' and joaat(model) or 0

    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then return end

    return vehicleTypeOf(hash)
end)

RegisterNetEvent('cobalt_core:Command:DeleteVehicle', function()
    local ped <const> = cache.ped
    local veh <const> = GetVehiclePedIsUsing(ped)
    if veh ~= 0 then
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
    else
        local pcoords <const> = GetEntityCoords(ped)
        local vehicles <const> = GetGamePool('CVehicle')
        for _, v in pairs(vehicles) do
            if #(pcoords - GetEntityCoords(v)) <= 5.0 then
                SetEntityAsMissionEntity(v, true, true)
                DeleteVehicle(v)
            end
        end
    end
end)

RegisterNetEvent('cobalt_core:Client:VehicleInfo', function(info)
    local plate <const> = Cobalt.Functions.GetPlate(info.vehicle)

    local data <const> = {
        vehicle = info.vehicle,
        seat = info.seat,
        name = info.name,
        plate = plate,
        driver = GetPedInVehicleSeat(info.vehicle, -1),
        inseat = GetPedInVehicleSeat(info.vehicle, info.seat),
        haskeys = info.haskeys == true
    }

    TriggerEvent('cobalt_core:Client:' .. info.event .. 'Vehicle', data)
end)

RegisterNetEvent('cobalt_core:Player:SetPlayerData', function(val)
    Cobalt.PlayerData = val
end)

RegisterNetEvent('cobalt_core:Client:OnPlayerUnload', function()
    Cobalt.PlayerData = {}
end)

RegisterNetEvent('cobalt_core:Player:UpdatePlayerData', function(changes, cleared)
    for field, value in pairs(changes) do
        Cobalt.PlayerData[field] = value
    end

    for _, field in ipairs(cleared) do
        Cobalt.PlayerData[field] = nil
    end

    TriggerEvent('cobalt_core:Player:SetPlayerData', Cobalt.PlayerData)
end)

RegisterNetEvent('cobalt_core:Notify', Cobalt.Functions.Notify)

AddStateBagChangeHandler('cobalt:jobs', 'global', function(_, _, value)
    if value then Cobalt.Shared.Jobs = value end
    TriggerEvent('cobalt_core:Client:UpdateObject')
end)

AddStateBagChangeHandler('cobalt:gangs', 'global', function(_, _, value)
    if value then Cobalt.Shared.Gangs = value end
    TriggerEvent('cobalt_core:Client:UpdateObject')
end)

RegisterNetEvent('cobalt_core:Client:OnSharedUpdate', function(tableName, key, value)
    Cobalt.Shared[tableName][key] = value
    TriggerEvent('cobalt_core:Client:UpdateObject')
end)

RegisterNetEvent('cobalt_core:Client:OnSharedUpdateMultiple', function(tableName, values)
    for key, value in pairs(values) do
        Cobalt.Shared[tableName][key] = value
    end
    TriggerEvent('cobalt_core:Client:UpdateObject')
end)

