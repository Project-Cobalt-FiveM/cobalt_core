local config <const> = require 'config.server'
local stateIds <const> = require 'server.stateid'

local function SetMethod(methodName, handler)
    if type(methodName) ~= 'string' then
        return false, 'invalid_method_name'
    end

    Cobalt.Functions[methodName] = handler

    TriggerEvent('cobalt_core:Server:UpdateObject')

    return true, 'success'
end

Cobalt.Functions.SetMethod = SetMethod

local function SetField(fieldName, data)
    if type(fieldName) ~= 'string' then
        return false, 'invalid_field_name'
    end

    Cobalt[fieldName] = data

    TriggerEvent('cobalt_core:Server:UpdateObject')

    return true, 'success'
end

Cobalt.Functions.SetField = SetField

local function AddJob(jobName, job)
    if type(jobName) ~= 'string' then
        return false, 'invalid_job_name'
    end

    if Cobalt.Shared.Jobs[jobName] then
        return false, 'job_exists'
    end

    Cobalt.Shared.Jobs[jobName] = job

    PublishJobs()
    TriggerClientEvent('cobalt_core:Client:OnSharedUpdate', -1, 'Jobs', jobName, job)
    TriggerEvent('cobalt_core:Server:UpdateObject')
    return true, 'success'
end

Cobalt.Functions.AddJob = AddJob

---@param store table
---@param entries table
---@param kind string
---@return string? message
---@return any errorItem
local function rejectEntries(store, entries, kind)
    for key, value in pairs(entries) do
        if type(key) ~= 'string' then return ('invalid_%s_name'):format(kind), value end
        if store[key] then return ('%s_exists'):format(kind), value end
    end
end

local function AddJobs(jobs)
    local message <const>, errorItem <const> = rejectEntries(Cobalt.Shared.Jobs, jobs, 'job')
    if message then return false, message, errorItem end

    for key, value in pairs(jobs) do Cobalt.Shared.Jobs[key] = value end

    PublishJobs()
    TriggerClientEvent('cobalt_core:Client:OnSharedUpdateMultiple', -1, 'Jobs', jobs)
    TriggerEvent('cobalt_core:Server:UpdateObject')
    return true, 'success', nil
end

Cobalt.Functions.AddJobs = AddJobs

local function RemoveJob(jobName)
    if type(jobName) ~= 'string' then
        return false, 'invalid_job_name'
    end

    if not Cobalt.Shared.Jobs[jobName] then
        return false, 'job_not_exists'
    end

    Cobalt.Shared.Jobs[jobName] = nil

    PublishJobs()
    TriggerClientEvent('cobalt_core:Client:OnSharedUpdate', -1, 'Jobs', jobName, nil)
    TriggerEvent('cobalt_core:Server:UpdateObject')
    return true, 'success'
end

Cobalt.Functions.RemoveJob = RemoveJob

local function UpdateJob(jobName, job)
    if type(jobName) ~= 'string' then
        return false, 'invalid_job_name'
    end

    if not Cobalt.Shared.Jobs[jobName] then
        return false, 'job_not_exists'
    end

    Cobalt.Shared.Jobs[jobName] = job

    PublishJobs()
    TriggerClientEvent('cobalt_core:Client:OnSharedUpdate', -1, 'Jobs', jobName, job)
    TriggerEvent('cobalt_core:Server:UpdateObject')
    return true, 'success'
end

Cobalt.Functions.UpdateJob = UpdateJob

local function AddGang(gangName, gang)
    if type(gangName) ~= 'string' then
        return false, 'invalid_gang_name'
    end

    if Cobalt.Shared.Gangs[gangName] then
        return false, 'gang_exists'
    end

    Cobalt.Shared.Gangs[gangName] = gang

    PublishGangs()
    TriggerClientEvent('cobalt_core:Client:OnSharedUpdate', -1, 'Gangs', gangName, gang)
    TriggerEvent('cobalt_core:Server:UpdateObject')
    return true, 'success'
end

Cobalt.Functions.AddGang = AddGang

local function AddGangs(gangs)
    local message <const>, errorItem <const> = rejectEntries(Cobalt.Shared.Gangs, gangs, 'gang')
    if message then return false, message, errorItem end

    for key, value in pairs(gangs) do Cobalt.Shared.Gangs[key] = value end

    PublishGangs()
    TriggerClientEvent('cobalt_core:Client:OnSharedUpdateMultiple', -1, 'Gangs', gangs)
    TriggerEvent('cobalt_core:Server:UpdateObject')
    return true, 'success', nil
end

Cobalt.Functions.AddGangs = AddGangs

local function RemoveGang(gangName)
    if type(gangName) ~= 'string' then
        return false, 'invalid_gang_name'
    end

    if not Cobalt.Shared.Gangs[gangName] then
        return false, 'gang_not_exists'
    end

    Cobalt.Shared.Gangs[gangName] = nil

    PublishGangs()
    TriggerClientEvent('cobalt_core:Client:OnSharedUpdate', -1, 'Gangs', gangName, nil)
    TriggerEvent('cobalt_core:Server:UpdateObject')
    return true, 'success'
end

Cobalt.Functions.RemoveGang = RemoveGang

local function UpdateGang(gangName, gang)
    if type(gangName) ~= 'string' then
        return false, 'invalid_gang_name'
    end

    if not Cobalt.Shared.Gangs[gangName] then
        return false, 'gang_not_exists'
    end

    Cobalt.Shared.Gangs[gangName] = gang

    PublishGangs()
    TriggerClientEvent('cobalt_core:Client:OnSharedUpdate', -1, 'Gangs', gangName, gang)
    TriggerEvent('cobalt_core:Server:UpdateObject')
    return true, 'success'
end

Cobalt.Functions.UpdateGang = UpdateGang

local resourceName <const> = GetCurrentResourceName()
---@return string
local function GetCoreVersion()
    return GetResourceMetadata(resourceName, 'version')
end

Cobalt.Functions.GetCoreVersion = GetCoreVersion

local PERMANENT_BAN <const> = 2147483647

---@alias BanIdentifier 'license' | 'discord' | 'steam'

---@class BanOptions
---@field reason string
---@field bannedBy string
---@field expire? integer unix time the ban ends, permanent when nil
---@field identifiers? BanIdentifier[] which of the player's identifiers to ban, all three when nil

---@param playerId integer
---@param options BanOptions
---@return integer? banId nil when the player has none of the chosen identifiers
local function Ban(playerId, options)
    local banned <const> = {}

    for _, idType in ipairs(options.identifiers or { 'license', 'discord', 'steam' }) do
        banned[idType] = Cobalt.Functions.GetIdentifier(playerId, idType)
    end

    if not banned.license and not banned.discord and not banned.steam then return nil end

    return MySQL.insert.await(
        'INSERT INTO bans (name, license, discord, steam, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        {
            GetPlayerName(playerId),
            banned.license,
            banned.discord,
            banned.steam,
            Cobalt.Functions.GetIdentifier(playerId, 'ip'),
            options.reason,
            math.min(options.expire or PERMANENT_BAN, PERMANENT_BAN),
            options.bannedBy,
        }
    )
end

Cobalt.Functions.Ban = Ban

---@param term string ban id, or a license, Discord or Steam identifier
---@param expiresBefore? integer lifts only bans ending before this unix time
---@return integer removed
local function Unban(term, expiresBefore)
    return MySQL.update.await(
        'DELETE FROM bans WHERE (id = ? OR license = ? OR discord = ? OR steam = ?) AND expire < ?',
        { tonumber(term) or 0, term, term, term, expiresBefore or math.maxinteger }
    )
end

Cobalt.Functions.Unban = Unban

local ACCOUNT_CHARACTERS <const> = [[
    SELECT citizenid, cid, name, fullname, phone_number, money, charinfo, position, metadata,
        UNIX_TIMESTAMP(last_updated) AS lastPlayed
    FROM players WHERE license = ? ORDER BY cid LIMIT 50
]]
local ACCOUNT_BANS <const> = [[
    SELECT id, reason, bannedby, expire, UNIX_TIMESTAMP(created_at) AS createdAt
    FROM bans WHERE license = ? ORDER BY id DESC LIMIT 100
]]

---@param license string
---@return integer?
local function connectedSource(license)
    for _, id in ipairs(GetPlayers()) do
        if Cobalt.Functions.GetIdentifier(id, 'license') == license then return tonumber(id) end
    end
end

---@param row table
---@return CoreAccountCharacter
local function storedCharacter(row)
    local metadata <const> = json.decode(row.metadata)

    return {
        citizenid = row.citizenid,
        cid = row.cid,
        name = row.fullname ~= '' and row.fullname or nil,
        charinfo = row.charinfo and json.decode(row.charinfo) or {},
        phone_number = row.phone_number,
        job = metadata.job,
        gang = metadata.gang,
        money = json.decode(row.money),
        metadata = metadata,
        position = row.position and json.decode(row.position),
        lastPlayed = row.lastPlayed,
        online = false,
    }
end

---@param player CorePlayer
---@param now integer
---@return CoreAccountCharacter
local function playingCharacter(player, now)
    local data <const> = player.PlayerData

    return {
        citizenid = data.citizenid,
        cid = data.cid,
        name = player.Functions.GetName(),
        charinfo = data.charinfo,
        phone_number = data.phone_number,
        job = data.job,
        gang = data.gang,
        money = data.money,
        metadata = data.metadata,
        position = player.lastPosition or data.position,
        lastPlayed = now,
        online = true,
    }
end

---@param row table
---@param now integer
---@return CoreAccountBan
local function accountBan(row, now)
    local expire <const> = row.expire or PERMANENT_BAN

    return {
        id = row.id,
        reason = row.reason,
        by = row.bannedby,
        expires = expire < PERMANENT_BAN and expire or nil,
        active = expire > now,
        createdAt = row.createdAt,
    }
end

---@param license string
---@return CoreAccount?
local function GetAccount(license)
    if type(license) ~= 'string' or license == '' then return nil end

    local playing <const> = Cobalt.PlayersByLicense[license]
    local source <const> = playing and playing.PlayerData.source or connectedSource(license)
    local rows <const> = MySQL.query.await(ACCOUNT_CHARACTERS, { license })
    local banRows <const> = MySQL.query.await(ACCOUNT_BANS, { license })
    local stateId <const> = stateIds.find(license)

    if not source and not stateId and #rows == 0 and #banRows == 0 then return nil end

    local now <const> = os.time()
    local playingCid <const> = playing?.PlayerData.citizenid
    local characters <const> = table.create(#rows + 1, 0)
    local name, newest = nil, -1
    local playingListed = false

    for i = 1, #rows do
        local row <const> = rows[i]

        if row.lastPlayed > newest then name, newest = row.name, row.lastPlayed end

        if row.citizenid == playingCid then
            characters[i] = playingCharacter(playing, now)
            playingListed = true
        else
            characters[i] = storedCharacter(row)
        end
    end

    if playing and not playingListed then characters[#characters + 1] = playingCharacter(playing, now) end

    local bans <const> = table.create(#banRows, 0)

    for i = 1, #banRows do bans[i] = accountBan(banRows[i], now) end

    return {
        license = license,
        name = source and GetPlayerName(source) or name,
        stateid = stateId,
        online = source and { source = source, citizenid = playingCid } or nil,
        characters = characters,
        bans = bans,
    }
end

Cobalt.Functions.GetAccount = GetAccount

local function ExploitBan(playerId, origin)
    Ban(playerId, { reason = origin, bannedBy = 'Anti Cheat' })
    DropPlayer(playerId, Lang:t('info.exploit_banned', { discord = config.discord }))
end

Cobalt.Functions.ExploitBan = ExploitBan

---@param plate string
---@return string? citizenid
---@return integer? vehicleId the `player_vehicles` id
local function GetVehicleOwnerByPlate(plate)
    if type(plate) ~= 'string' then return nil end

    local trimmed <const> = plate:gsub('%s+', '')

    if trimmed == '' then return nil end

    local query <const> = 'SELECT id, citizenid FROM player_vehicles WHERE plate IN (?, ?) LIMIT 1'
    local row <const> = MySQL.single.await(query, { trimmed, ('%-8s'):format(trimmed) })

    if not row then return nil end

    return row.citizenid, row.id
end

Cobalt.Functions.GetVehicleOwnerByPlate = GetVehicleOwnerByPlate

---@type string[]
local VEHICLE_COLUMNS <const> = {
    'id', 'license', 'citizenid', 'vehicle', 'hash', 'mods', 'plate', 'fakeplate', 'garage', 'fuel', 'engine', 'body',
    'state', 'depotprice', 'drivingdistance', 'status', 'vehicle_type', 'class', 'parked_at', 'impounded_at',
    'impound_reason', 'impounded_by', 'hold_until', 'created_at',
}

---@type table<string, true>
local SELECTABLE_VEHICLE_COLUMNS <const> = {}

for _, column in ipairs(VEHICLE_COLUMNS) do SELECTABLE_VEHICLE_COLUMNS[column] = true end

local VEHICLES_BY_CITIZEN_QUERY <const> = 'SELECT %s FROM player_vehicles WHERE citizenid = ? ORDER BY id LIMIT 100'

---@param citizenid string
---@param fields? string[]
---@return table[]
local function GetVehiclesByCitizenId(citizenid, fields)
    if type(citizenid) ~= 'string' or citizenid == '' then return {} end

    local columns <const> = type(fields) == 'table' and #fields > 0 and fields or VEHICLE_COLUMNS

    for _, column in ipairs(columns) do
        if not SELECTABLE_VEHICLE_COLUMNS[column] then
            error(('%s is not a selectable player_vehicles column'):format(column))
        end
    end

    local query <const> = VEHICLES_BY_CITIZEN_QUERY:format(table.concat(columns, ', '))

    return MySQL.query.await(query, { citizenid }) or {}
end

Cobalt.Functions.GetVehiclesByCitizenId = GetVehiclesByCitizenId

---@param source integer
---@param model string
---@return string?
local function GetVehicleType(source, model)
    local shared <const> = GetShared('Vehicles', model:lower())

    if shared?.type then return shared.type end

    local ok <const>, vehicleType <const> = pcall(lib.callback.await, 'cobalt_core:client:vehicleType', source, model)

    return ok and vehicleType or nil
end

Cobalt.Functions.GetVehicleType = GetVehicleType
