local config <const> = require 'config.server'
local sharedConfig <const> = require 'config.shared'
local toggleDuty <const> = require 'server.duty'
local stateIds <const> = require 'server.stateid'

AddEventHandler('chatMessage', function(_, _, message)
    if string.sub(message, 1, 1) == '/' then
        CancelEvent()
        return
    end
end)

AddEventHandler('playerDropped', function()
    local src <const> = source
    if not Cobalt.Players[src] then return end
    local Player <const> = Cobalt.Players[src]
    TriggerEvent('cobalt_core:Server:PlayerDropped', Player)

    local ok <const>, err <const> = pcall(Player.Functions.Save)

    if not ok then lib.print.error(('drop save failed for %s: %s'):format(src, err)) end

    local PlayerData <const> = Player.PlayerData

    Cobalt.Player_Buckets[PlayerData.license] = nil
    Cobalt.Players[src] = nil

    if Cobalt.PlayersByCid[PlayerData.citizenid] == Player then
        Cobalt.PlayersByCid[PlayerData.citizenid] = nil
    end

    if Cobalt.PlayersByLicense[PlayerData.license] == Player then
        Cobalt.PlayersByLicense[PlayerData.license] = nil
    end
end)

AddEventHandler("onResourceStop", function(resName)
    if resName == cache.resource then Cobalt.Player.SaveAll(true) end
end)

AddEventHandler('txAdmin:events:serverShuttingDown', function()
    Cobalt.Player.SaveAll()
end)

---@param event { secondsRemaining: integer }
AddEventHandler('txAdmin:events:scheduledRestart', function(event)
    if event.secondsRemaining > 60 then return end

    Cobalt.Player.SaveAll()
end)

local databaseConnected, bansTableExists = false, false

MySQL.ready(function()
    while GlobalState['cobalt:migrated:cobalt_core'] ~= true do Wait(50) end

    databaseConnected = true
    bansTableExists = true
end)

local function onPlayerConnecting(name, _, deferrals)
    local src <const> = source
    deferrals.defer()

    if config.closed and not IsPlayerAceAllowed(src, 'admin') then
        return deferrals.done(config.closedReason)
    end

    if not databaseConnected then
        return deferrals.done(Lang:t('error.connecting_database_error'))
    end

    if config.whitelist then
        Wait(0)
        deferrals.update(Lang:t('info.checking_whitelisted', { name = name }))
        if not Cobalt.Functions.IsWhitelisted(src) then
            return deferrals.done(Lang:t('error.not_whitelisted'))
        end
    end

    Wait(0)
    deferrals.update(Lang:t('info.checking_license', { name = name }))
    local license <const> = Cobalt.Functions.GetIdentifier(src, 'license')

    if not license then
        return deferrals.done(Lang:t('error.no_valid_license'))
    elseif config.checkDuplicateLicense and Cobalt.Functions.IsLicenseInUse(license) then
        return deferrals.done(Lang:t('error.duplicate_license'))
    end

    Wait(0)
    deferrals.update(Lang:t('info.checking_ban', { name = name }))

    if not bansTableExists then
        return deferrals.done(Lang:t('error.ban_table_not_found'))
    end

    local success, isBanned, reason = pcall(Cobalt.Functions.IsPlayerBanned, src)
    if not success then return deferrals.done(Lang:t('error.connecting_database_error')) end
    if isBanned then return deferrals.done(reason) end

    if not pcall(stateIds.claim, license) then
        return deferrals.done(Lang:t('error.connecting_database_error'))
    end

    Wait(0)
    deferrals.update(Lang:t('info.join_server', { name = name }))
    deferrals.done()
end

AddEventHandler('playerConnecting', onPlayerConnecting)

RegisterNetEvent('cobalt_core:Server:CloseServer', function(reason)
    local src <const> = source
    if Cobalt.Functions.HasPermission(src, 'admin') then
        reason = reason or Lang:t('info.no_reason')
        config.closed = true
        config.closedReason = reason
        for k in pairs(Cobalt.Players) do
            if not Cobalt.Functions.HasPermission(k, config.whitelistPermission) then
                Cobalt.Functions.Kick(k, reason, nil, nil)
            end
        end
    else
        Cobalt.Functions.Kick(src, Lang:t('error.no_permission'), nil, nil)
    end
end)

RegisterNetEvent('cobalt_core:Server:OpenServer', function()
    local src <const> = source
    if Cobalt.Functions.HasPermission(src, 'admin') then
        config.closed = false
    else
        Cobalt.Functions.Kick(src, Lang:t('error.no_permission'), nil, nil)
    end
end)

---@param Player table
local function decayNeeds(Player)
    local metadata <const> = Player.PlayerData.metadata
    local hunger <const> = math.max(metadata.hunger - sharedConfig.status.hungerRate, 0)
    local thirst <const> = math.max(metadata.thirst - sharedConfig.status.thirstRate, 0)

    metadata.hunger = hunger
    metadata.thirst = thirst
    Player:UpdatePlayerData({ 'metadata' })
    TriggerClientEvent('hud:client:UpdateNeeds', Player.PlayerData.source, hunger, thirst)
end

SetInterval(function()
    local sources <const> = {}

    for source in pairs(Cobalt.Players) do sources[#sources + 1] = source end

    for i = 1, #sources do
        local Player <const> = Cobalt.Players[sources[i]]

        if Player then
            local ok <const>, err <const> = pcall(decayNeeds, Player)

            if not ok then lib.print.error(('needs decay failed for %s: %s'):format(sources[i], err)) end

            Wait(0)
        end
    end
end, sharedConfig.status.decayMinutes * 60000)

local MIN_SAVE_SECONDS <const> = 10

SetInterval(function()
    Cobalt.Player.SaveAll()
end, math.max(GetConvarInt('player_save_interval', 60), MIN_SAVE_SECONDS) * 1000)

RegisterNetEvent('cobalt_core:ToggleDuty', function()
    local src <const> = source
    local onDuty <const> = toggleDuty(src)

    if onDuty == nil then return end

    TriggerEvent('cobalt_core:Server:SetDuty', src, onDuty)
    TriggerClientEvent('cobalt_core:Client:SetDuty', src, onDuty)
end)

---@param source integer
---@param netId? integer
---@return boolean
local function holdsKey(source, netId)
    if GetResourceState('cobalt_vehiclekeys') ~= 'started' then return true end

    local entity <const> = math.type(netId) == 'integer' and NetworkGetEntityFromNetworkId(netId) or 0

    if entity == 0 then return false end

    return exports.cobalt_vehiclekeys:HasKey(source, entity)
end

RegisterServerEvent('baseevents:enteringVehicle', function(veh, seat, modelName, netId)
    local src <const> = source
    local data <const> = {
        vehicle = veh,
        seat = seat,
        name = modelName,
        event = 'Entering',
        haskeys = holdsKey(src, netId),
    }
    TriggerClientEvent('cobalt_core:Client:VehicleInfo', src, data)
end)

RegisterServerEvent('baseevents:enteredVehicle', function(veh, seat, modelName, netId)
    local src <const> = source
    local data <const> = {
        vehicle = veh,
        seat = seat,
        name = modelName,
        event = 'Entered',
        haskeys = holdsKey(src, netId),
    }
    TriggerClientEvent('cobalt_core:Client:VehicleInfo', src, data)
end)

RegisterServerEvent('baseevents:enteringAborted', function()
    local src <const> = source
    TriggerClientEvent('cobalt_core:Client:AbortVehicleEntering', src)
end)

RegisterServerEvent('baseevents:leftVehicle', function(veh, seat, modelName)
    local src <const> = source
    local data <const> = {
        vehicle = veh,
        seat = seat,
        name = modelName,
        event = 'Left'
    }
    TriggerClientEvent('cobalt_core:Client:VehicleInfo', src, data)
end)

RegisterNetEvent('cobalt_core:CallCommand', function(command, args)
    local src <const> = source
    if not Cobalt.Commands.List[command] then return end
    local Player <const> = Cobalt.Functions.GetPlayer(src)
    if not Player then return end
    local hasPerm <const> = Cobalt.Functions.HasPermission(src, 'command.' .. Cobalt.Commands.List[command].name)
    if hasPerm then
        if Cobalt.Commands.List[command].argsrequired and #Cobalt.Commands.List[command].arguments ~= 0 and not args[#Cobalt.Commands.List[command].arguments] then
            Cobalt.Functions.Notify(src, { description = Lang:t('error.missing_args2'), type = 'error' })
        else
            Cobalt.Commands.List[command].callback(src, args)
        end
    else
        Cobalt.Functions.Notify(src, { description = Lang:t('error.no_access'), type = 'error' })
    end
end)

