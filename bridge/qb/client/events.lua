local qbShared <const> = require 'bridge.qb.shared.main'

qbShared.reemit({
    ['cobalt_core:Client:OnPlayerUnload'] = 'QBCore:Client:OnPlayerUnload',
    ['cobalt_core:Client:OnJobUpdate'] = 'QBCore:Client:OnJobUpdate',
    ['cobalt_core:Client:OnGangUpdate'] = 'QBCore:Client:OnGangUpdate',
    ['cobalt_core:Client:OnMoneyChange'] = 'QBCore:Client:OnMoneyChange',
    ['cobalt_core:Client:PvpHasToggled'] = 'QBCore:Client:PvpHasToggled',
    ['cobalt_core:Client:VehicleInfo'] = 'QBCore:Client:VehicleInfo',
    ['cobalt_core:Client:AbortVehicleEntering'] = 'QBCore:Client:AbortVehicleEntering',
    ['cobalt_core:Client:OnSharedUpdate'] = 'QBCore:Client:OnSharedUpdate',
    ['cobalt_core:Client:OnSharedUpdateMultiple'] = 'QBCore:Client:OnSharedUpdateMultiple',
    ['cobalt_management:dutyChanged'] = 'QBCore:Client:SetDuty',
}, RegisterNetEvent)

qbShared.reemit({
    ['cobalt_core:Client:UpdateObject'] = 'QBCore:Client:UpdateObject',
    ['cobalt_core:Client:EnteringVehicle'] = 'QBCore:Client:EnteringVehicle',
    ['cobalt_core:Client:EnteredVehicle'] = 'QBCore:Client:EnteredVehicle',
    ['cobalt_core:Client:LeftVehicle'] = 'QBCore:Client:LeftVehicle',
}, AddEventHandler)

qbShared.reemit({
    ['QBCore:Command:TeleportToPlayer'] = 'cobalt_core:Command:TeleportToPlayer',
    ['QBCore:Command:TeleportToCoords'] = 'cobalt_core:Command:TeleportToCoords',
    ['QBCore:Command:GoToMarker'] = 'cobalt_core:Command:GoToMarker',
    ['QBCore:Command:DeleteVehicle'] = 'cobalt_core:Command:DeleteVehicle',
}, RegisterNetEvent)

RegisterNetEvent('cobalt_core:Player:SetPlayerData', function(playerData)
    local view <const> = qbShared.playerData(playerData)

    TriggerEvent('QBCore:Player:SetPlayerData', view)
    TriggerEvent('QBCore:Client:OnPlayerUpdated', 'all', view)
end)

local awaitingMembership = false

RegisterNetEvent('cobalt_core:Client:OnPlayerLoaded', function()
    if GetResourceState('cobalt_management') ~= 'started' then
        return TriggerEvent('QBCore:Client:OnPlayerLoaded')
    end

    awaitingMembership = true
end)

RegisterNetEvent('cobalt_management:membershipChanged', function()
    if not awaitingMembership then return end

    awaitingMembership = false
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
end)

AddEventHandler('cobalt_core:Client:OnPlayerUnload', function()
    awaitingMembership = false
end)

RegisterNetEvent('QBCore:Notify', function(text, notifyType, length)
    Cobalt.Functions.Notify(text, notifyType, length)
end)
