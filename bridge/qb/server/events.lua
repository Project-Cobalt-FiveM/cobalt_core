local qbShared <const> = require 'bridge.qb.shared.main'
local allowCallback <const> = require 'server.callbacklimit'
local callbacks <const> = require 'bridge.qb.server.callbacks'
local qbPlayer <const> = require 'bridge.qb.server.player'
local toggleDuty <const> = require 'server.duty'

qbShared.reemit({
    ['cobalt_core:Server:OnPlayerUnload'] = 'QBCore:Server:OnPlayerUnload',
    ['cobalt_core:Server:OnGangUpdate'] = 'QBCore:Server:OnGangUpdate',
    ['cobalt_core:Server:OnMoneyChange'] = 'QBCore:Server:OnMoneyChange',
    ['cobalt_core:Server:UpdateObject'] = 'QBCore:Server:UpdateObject',
    ['cobalt_management:dutyChanged'] = 'QBCore:Server:SetDuty',
}, AddEventHandler)

AddEventHandler('cobalt_core:Player:SetPlayerData', function(playerData)
    local view <const> = qbShared.playerData(playerData)

    TriggerEvent('QBCore:Player:SetPlayerData', view)
    TriggerEvent('QBCore:Server:OnPlayerUpdated', view.source, 'all', view)
end)

---@type table<integer, true>
local awaitingMembership <const> = {}

---@param source integer
local function playerLoaded(source)
    TriggerEvent('QBCore:Server:PlayerLoaded', qbPlayer.from(Cobalt.Functions.GetPlayer(source)))
end

AddEventHandler('cobalt_core:Server:PlayerLoaded', function(player)
    local source <const> = player.PlayerData.source

    if GetResourceState('cobalt_management') ~= 'started' then
        return playerLoaded(source)
    end

    awaitingMembership[source] = true
end)

AddEventHandler('cobalt_management:membershipChanged', function(source, job)
    if awaitingMembership[source] then
        awaitingMembership[source] = nil
        return playerLoaded(source)
    end

    TriggerEvent('QBCore:Server:OnJobUpdate', source, job)
end)

AddEventHandler('cobalt_core:Server:OnPlayerUnload', function(source)
    awaitingMembership[source] = nil
end)

AddEventHandler('playerDropped', function()
    local src <const> = source

    awaitingMembership[src] = nil
    TriggerEvent('QBCore:Server:PlayerDropped', src)
end)

RegisterNetEvent('QBCore:ToggleDuty', function()
    toggleDuty(source)
end)

RegisterNetEvent('QBCore:Server:TriggerCallback', function(name, ...)
    local src <const> = source
    local callback <const> = callbacks.handlers[name]
    if not allowCallback(src, name, callback ~= nil) then return end

    callback(src, function(...)
        TriggerClientEvent('QBCore:Client:TriggerCallback', src, name, ...)
    end, ...)
end)

RegisterNetEvent('QBCore:CallCommand', function(command, args)
    local src <const> = source
    local entry <const> = Cobalt.Commands.List[command]
    if not entry or type(args) ~= 'table' then return end

    if not Cobalt.Functions.GetPlayer(src) then return end

    if not Cobalt.Functions.HasPermission(src, 'command.' .. entry.name) then
        return Cobalt.Functions.Notify(src, { description = Lang:t('error.no_access'), type = 'error' })
    end

    if entry.argsrequired and #entry.arguments ~= 0 and not args[#entry.arguments] then
        return Cobalt.Functions.Notify(src, { description = Lang:t('error.missing_args2'), type = 'error' })
    end

    entry.callback(src, args)
end)
