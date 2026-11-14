local config <const> = require 'config.server'

Cobalt.Functions = {}
Cobalt.Player_Buckets = {}
Cobalt.Entity_Buckets = {}

---Gets player identifier of the given type
---@param source any
---@param idtype string
---@return string?
function Cobalt.Functions.GetIdentifier(source, idtype)
    if GetConvarInt('sv_fxdkMode', 0) == 1 then return 'license:fxdk' end
    return GetPlayerIdentifierByType(source, idtype or 'license')
end

---Gets a players server id (source). Returns 0 if no player is found.
---@param identifier string
---@return number
function Cobalt.Functions.GetSource(identifier)
    for src, _ in pairs(Cobalt.Players) do
        local idens <const> = GetPlayerIdentifiers(src)
        for _, id in pairs(idens) do
            if identifier == id then
                return src
            end
        end
    end
    return 0
end

---Get player with given server id (source)
---@param source any
---@return table
function Cobalt.Functions.GetPlayer(source)
    if tonumber(source) ~= nil then
        return Cobalt.Players[tonumber(source)]
    else
        return Cobalt.Players[Cobalt.Functions.GetSource(source)]
    end
end

---Get an online player by citizen id
---@param citizenid string
---@return table?
function Cobalt.Functions.GetPlayerByCitizenId(citizenid)
    if not citizenid then return nil end
    return Cobalt.PlayersByCid[citizenid]
end

---Get offline player by citizen id
---@param citizenid string
---@return table?
function Cobalt.Functions.GetOfflinePlayerByCitizenId(citizenid)
    return Cobalt.Player.GetOfflinePlayer(citizenid)
end

---Get player by license
---@param license string
---@return table?
function Cobalt.Functions.GetPlayerByLicense(license)
    return Cobalt.Player.GetPlayerByLicense(license)
end

---Get the online player whose character owns the phone number in `players.phone_number`
---@param number string
---@return table?
function Cobalt.Functions.GetPlayerByPhone(number)
    if type(number) ~= 'string' or number == '' then return nil end

    local citizenid <const> = MySQL.scalar.await('SELECT citizenid FROM players WHERE phone_number = ? LIMIT 1', { number })

    return citizenid and Cobalt.PlayersByCid[citizenid] or nil
end


---Get player passing property and value to check exists
---@param property string
---@param value string
---@return table?
function Cobalt.Functions.GetPlayerByCharInfo(property, value)
    for src in pairs(Cobalt.Players) do
        local charinfo <const> = Cobalt.Players[src].PlayerData.charinfo
        if charinfo[property] ~= nil and charinfo[property] == value then
            return Cobalt.Players[src]
        end
    end
    return nil
end

---Get all players. Returns the server ids of all players.
---@return table
function Cobalt.Functions.GetPlayers()
    local sources <const> = {}
    for k in pairs(Cobalt.Players) do
        sources[#sources + 1] = k
    end
    return sources
end


---Online players whose cobalt_management job (`PlayerData.job`) has this name or type, and their count
---@param job string job name or type
---@param checkOnDuty? boolean only players on duty
---@return integer[] sources
---@return integer count
function Cobalt.Functions.GetPlayersByJob(job, checkOnDuty)
    local players <const> = {}
    local count = 0

    for src, Player in pairs(Cobalt.Players) do
        local playerJob <const> = Player.PlayerData.job
        local inJob <const> = playerJob and (playerJob.name == job or playerJob.type == job)

        if inJob and (playerJob.onduty or not checkOnDuty) then
            count += 1
            players[count] = src
        end
    end

    return players, count
end

---Returns the objects related to buckets, first returned value is the player buckets, second one is entity buckets
---@return table, table
function Cobalt.Functions.GetBucketObjects()
    return Cobalt.Player_Buckets, Cobalt.Entity_Buckets
end

---Will set the provided player id / source into the provided bucket id
---@param source any
---@param bucket any
---@return boolean
function Cobalt.Functions.SetPlayerBucket(source, bucket)
    if source and bucket then
        local plicense <const> = Cobalt.Functions.GetIdentifier(source, 'license')
        Player(source).state:set('instance', bucket, true)
        SetPlayerRoutingBucket(source, bucket)
        Cobalt.Player_Buckets[plicense] = { id = source, bucket = bucket }
        return true
    else
        return false
    end
end

---Will set any entity into the provided bucket, for example peds / vehicles / props / etc.
---@param entity number
---@param bucket number
---@return boolean
function Cobalt.Functions.SetEntityBucket(entity, bucket)
    if entity and bucket then
        SetEntityRoutingBucket(entity, bucket)
        Cobalt.Entity_Buckets[entity] = { id = entity, bucket = bucket }
        return true
    else
        return false
    end
end

---Will return an array of all the player ids inside the current bucket
---@param bucket number
---@return table|boolean
function Cobalt.Functions.GetPlayersInBucket(bucket)
    local curr_bucket_pool <const> = {}
    if Cobalt.Player_Buckets and next(Cobalt.Player_Buckets) then
        for _, v in pairs(Cobalt.Player_Buckets) do
            if v.bucket == bucket then
                curr_bucket_pool[#curr_bucket_pool + 1] = v.id
            end
        end
        return curr_bucket_pool
    else
        return false
    end
end

---Will return an array of all the entities inside the current bucket
---(not for player entities, use GetPlayersInBucket for that)
---@param bucket number
---@return table|boolean
function Cobalt.Functions.GetEntitiesInBucket(bucket)
    local curr_bucket_pool <const> = {}
    if Cobalt.Entity_Buckets and next(Cobalt.Entity_Buckets) then
        for _, v in pairs(Cobalt.Entity_Buckets) do
            if v.bucket == bucket then
                curr_bucket_pool[#curr_bucket_pool + 1] = v.id
            end
        end
        return curr_bucket_pool
    else
        return false
    end
end

local PLATE_CHARS <const> = 'ABCDEFGHJKLMNPRSTUVWXYZ0123456789'
local PLATE_LENGTH <const> = 8

---@return string
local function randomPlate()
    local chars <const> = {}

    for i = 1, PLATE_LENGTH do
        local index <const> = math.random(#PLATE_CHARS)
        chars[i] = PLATE_CHARS:sub(index, index)
    end

    return table.concat(chars)
end

local PLATE_ATTEMPTS <const> = 10

---@return string plate eight characters that no `player_vehicles` row uses
function Cobalt.Functions.GeneratePlate()
    for _ = 1, PLATE_ATTEMPTS do
        local plate <const> = randomPlate()

        if not MySQL.scalar.await('SELECT 1 FROM player_vehicles WHERE plate = ? LIMIT 1', { plate }) then
            return plate
        end
    end

    error(('no free plate after %d attempts'):format(PLATE_ATTEMPTS))
end

---@param source integer
---@param model string|integer
---@param coords? vector3|vector4 defaults to the player's position
---@param warp? boolean seat the player as the driver
---@param vehicleType? string `CreateVehicleServerSetter` type; looked up with `GetVehicleType` when left out
---@return integer? vehicle
---@return string? plate
function Cobalt.Functions.SpawnVehicle(source, model, coords, warp, vehicleType)
    local ped <const> = GetPlayerPed(source)
    local hash <const> = type(model) == 'string' and joaat(model) or model
    local setterType <const> = vehicleType
        or type(model) == 'string' and Cobalt.Functions.GetVehicleType(source, model)
        or 'automobile'
    local at <const> = coords or GetEntityCoords(ped)
    local plate <const> = Cobalt.Functions.GeneratePlate()
    local vehicle <const> = CreateVehicleServerSetter(hash, setterType, at.x, at.y, at.z, at.w or 0.0)
    local deadline <const> = GetGameTimer() + 5000

    while not DoesEntityExist(vehicle) do
        if GetGameTimer() > deadline then return end

        Wait(0)
    end

    SetVehicleNumberPlateText(vehicle, plate)
    Entity(vehicle).state:set('fuel', 100.0, true)

    if not warp then return vehicle, plate end

    while GetVehiclePedIsIn(ped, false) ~= vehicle do
        if GetGameTimer() > deadline or not DoesEntityExist(ped) then
            DeleteEntity(vehicle)
            return
        end

        TaskWarpPedIntoVehicle(ped, vehicle, -1)
        Wait(0)
    end

    return vehicle, plate
end

---Kick Player
---@param source? integer
---@param reason string
---@param setKickReason? fun(reason: string)
---@param deferrals? table
function Cobalt.Functions.Kick(source, reason, setKickReason, deferrals)
    reason = Lang:t('kick.message', { reason = reason, discord = config.discord })
    if setKickReason then
        setKickReason(reason)
    end
    CreateThread(function()
        if deferrals then
            deferrals.update(reason)
            Wait(2500)
        end
        if source then
            DropPlayer(source, reason)
        end
    end)
end

---Check if player is whitelisted
---@param source any
---@return boolean
function Cobalt.Functions.IsWhitelisted(source)
    if not config.whitelist then return true end
    if Cobalt.Functions.HasPermission(source, config.whitelistPermission) then return true end
    return false
end

---@param permission string
---@return boolean
local function isGrantableRank(permission)
    return lib.table.contains(config.permissions, permission)
end

---Add permission for player
---@param source integer
---@param permission string one of config.permissions
function Cobalt.Functions.AddPermission(source, permission)
    if not isGrantableRank(permission) then return end
    if not IsPlayerAceAllowed(source, permission) then
        ExecuteCommand(('add_principal player.%s group.%s'):format(source, permission))
        Cobalt.Commands.Refresh(source)
    end
end

---Remove permission from player
---@param source any
---@param permission string
function Cobalt.Functions.RemovePermission(source, permission)
    if permission then
        if isGrantableRank(permission) and IsPlayerAceAllowed(source, permission) then
            ExecuteCommand(('remove_principal player.%s group.%s'):format(source, permission))
            Cobalt.Commands.Refresh(source)
        end
    else
        for _, v in pairs(config.permissions) do
            if IsPlayerAceAllowed(source, v) then
                ExecuteCommand(('remove_principal player.%s group.%s'):format(source, v))
                Cobalt.Commands.Refresh(source)
            end
        end
    end
end

---Check if player has permission
---@param source any
---@param permission string
---@return boolean
function Cobalt.Functions.HasPermission(source, permission)
    if type(permission) == 'string' then
        if IsPlayerAceAllowed(source, permission) then return true end
    elseif type(permission) == 'table' then
        for _, permLevel in pairs(permission) do
            if IsPlayerAceAllowed(source, permLevel) then return true end
        end
    end

    return false
end

---Get the players permissions
---@param source any
---@return table
function Cobalt.Functions.GetPermission(source)
    local src <const> = source
    local perms <const> = {}
    for _, v in pairs(config.permissions) do
        if IsPlayerAceAllowed(src, v) then
            perms[v] = true
        end
    end
    return perms
end

---Get admin messages opt-in state for player
---@param source any
---@return boolean
function Cobalt.Functions.IsOptin(source)
    local license <const> = Cobalt.Functions.GetIdentifier(source, 'license')
    if not license or not Cobalt.Functions.HasPermission(source, 'admin') then return false end
    local Player <const> = Cobalt.Functions.GetPlayer(source)
    return Player.PlayerData.metadata.optin
end

---Toggle opt-in to admin messages
---@param source any
function Cobalt.Functions.ToggleOptin(source)
    local license <const> = Cobalt.Functions.GetIdentifier(source, 'license')
    if not license or not Cobalt.Functions.HasPermission(source, 'admin') then return end
    local Player <const> = Cobalt.Functions.GetPlayer(source)
    Player.Functions.SetMetaData('optin', not Player.PlayerData.metadata.optin)
end

---Check if player is banned
---@param source any
---@return boolean, string?
function Cobalt.Functions.IsPlayerBanned(source)
    local license <const> = Cobalt.Functions.GetIdentifier(source, 'license')
    local discord <const> = Cobalt.Functions.GetIdentifier(source, 'discord')
    local steam <const> = Cobalt.Functions.GetIdentifier(source, 'steam')
    MySQL.update.await('DELETE FROM bans WHERE expire <= ? AND (license = ? OR discord = ? OR steam = ?)', { os.time(), license, discord, steam })
    local result <const> = MySQL.single.await('SELECT reason, expire FROM bans WHERE license = ? OR discord = ? OR steam = ? ORDER BY expire DESC LIMIT 1', { license, discord, steam })
    if not result then return false end
    return true, Lang:t('kick.banned', { reason = result.reason, expires = os.date('%d/%m/%Y %H:%M', tonumber(result.expire)) })
end

---Check for duplicate license
---@param license any
---@return boolean
function Cobalt.Functions.IsLicenseInUse(license)
    local players <const> = GetPlayers()
    for _, player in pairs(players) do
        local playerLicense <const> = Cobalt.Functions.GetIdentifier(player, 'license')
        if playerLicense == license then return true end
    end
    return false
end

---Notifies a player, or everyone with -1, through cobalt_interfaces
---`data` is a notify table, or the text of QBCore's (source, text, type, length).
---@param source number
---@param data string | table
---@param notifyType? string
---@param length? number
---@diagnostic disable-next-line: duplicate-set-field
function Cobalt.Functions.Notify(source, data, notifyType, length)
    if type(data) ~= 'table' then
        data = { description = data, type = notifyType, duration = length or 5000 }
    end

    if data.type == 'primary' then data.type = 'inform' end
    if data.type == 'warn' then data.type = 'warning' end

    if GetResourceState('cobalt_interfaces') ~= 'started' then return end

    return exports.cobalt_interfaces:notify(source, data)
end

---@alias Need 'hunger' | 'thirst'

---@type table<Need, true>
local NEEDS <const> = { hunger = true, thirst = true }

---@param player table
---@param need Need
---@param value number
local function writeNeed(player, need, value)
    player.Functions.SetMetaData(need, math.max(0, math.min(100, value)))

    local metadata <const> = player.PlayerData.metadata

    TriggerClientEvent('hud:client:UpdateNeeds', player.PlayerData.source, metadata.hunger, metadata.thirst)
end

---@param source integer
---@param need Need
---@param value number
---@return boolean set false when the need is unknown, the value isn't a number or the player isn't loaded
function Cobalt.Functions.SetNeed(source, need, value)
    if not NEEDS[need] or type(value) ~= 'number' then return false end

    local player <const> = Cobalt.Functions.GetPlayer(source)

    if not player then return false end

    writeNeed(player, need, value)

    return true
end

---@param source integer
---@param need Need
---@param amount number negative to lower
---@return boolean added false when the need is unknown, the amount isn't a number or the player isn't loaded
function Cobalt.Functions.AddNeed(source, need, amount)
    if not NEEDS[need] or type(amount) ~= 'number' then return false end

    local player <const> = Cobalt.Functions.GetPlayer(source)

    if not player then return false end

    writeNeed(player, need, (player.PlayerData.metadata[need] or 100) + amount)

    return true
end
