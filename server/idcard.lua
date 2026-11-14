local sharedConfig <const> = require 'config.shared'
local settings <const> = sharedConfig.idCard

---@type table<string, true>
local CARD_ITEMS <const> = { id_card = true, driver_license = true, weapon_license = true }

---@param source integer
---@return vector3?
---@return number?
local function placeOf(source)
    local ped <const> = GetPlayerPed(source)

    if ped == 0 then return end

    return GetEntityCoords(ped), GetEntityHeading(ped)
end

---@param heading number
---@param from vector3
---@param to vector3
---@return boolean
local function faces(heading, from, to)
    local rad <const> = math.rad(heading)
    local dx <const>, dy <const> = to.x - from.x, to.y - from.y
    local length <const> = math.sqrt(dx * dx + dy * dy)

    if length == 0 then return true end

    return (-math.sin(rad) * dx + math.cos(rad) * dy) / length >= 0.5
end

---@param target integer
---@param origin vector3
---@param bucket integer
---@return boolean
local function canView(target, origin, bucket)
    if GetPlayerRoutingBucket(target) ~= bucket then return false end

    local coords <const>, heading <const> = placeOf(target)

    if not coords then return false end
    if #(coords - origin) > settings.nearbyDistance then return false end
    if settings.requireFacing and not faces(heading --[[@as number]], coords, origin) then return false end

    return true
end

---@param source integer
---@return integer[]
local function nearbyViewers(source)
    local origin <const> = placeOf(source)
    local viewers <const> = {}

    if not origin then return viewers end

    local bucket <const> = GetPlayerRoutingBucket(source)

    for _, id in ipairs(GetPlayers()) do
        local target <const> = tonumber(id) --[[@as integer]]

        if target ~= source and canView(target, origin, bucket) then
            viewers[#viewers + 1] = target
        end
    end

    return viewers
end

---@param metadata table?
---@return 'id' | string?
local function cardKind(metadata)
    if type(metadata) ~= 'table' then return end
    if type(metadata.citizenid) ~= 'string' or type(metadata.firstname) ~= 'string' or type(metadata.lastname) ~= 'string' then return end

    local licence <const> = metadata.licence

    if licence == nil then return 'id' end
    if sharedConfig.licenses[licence] then return licence end
end

---@param metadata table
---@param kind string
---@param holder integer
---@return CardData
local function cardData(metadata, kind, holder)
    local record <const> = kind ~= 'id' and exports.cobalt_core:GetLicenseRecords(metadata.citizenid)?[kind] or nil

    return {
        style = settings.style,
        kind = kind,
        holder = holder,
        citizenid = metadata.citizenid,
        firstname = metadata.firstname,
        lastname = metadata.lastname,
        birthdate = type(metadata.birthdate) == 'string' and metadata.birthdate or nil,
        gender = tonumber(metadata.gender),
        nationality = type(metadata.nationality) == 'string' and metadata.nationality or nil,
        issued = type(metadata.issued) == 'string' and metadata.issued or nil,
        grantedBy = record?.grantedBy,
        grantedAt = record?.grantedAt,
    }
end

---@param source integer
---@param targets integer[]
---@param metadata table?
---@return boolean shown
local function showCard(source, targets, metadata)
    local kind <const> = cardKind(metadata)

    if not kind then return false end

    local data <const> = cardData(metadata --[[@as table]], kind, source)

    TriggerClientEvent('cobalt_core:client:showCard', source, data)

    for _, target in ipairs(targets) do
        if target ~= source and GetPlayerPed(target) ~= 0 then TriggerClientEvent('cobalt_core:client:showCard', target, data) end
    end

    return true
end

---@param source integer
---@param key? string
---@return CardItemMetadata?
local function cardMetadata(source, key)
    local player <const> = Cobalt.Players[source]

    if not player then return end

    local charinfo <const> = player.PlayerData.charinfo

    return {
        citizenid = player.PlayerData.citizenid,
        firstname = charinfo.firstname,
        lastname = charinfo.lastname,
        birthdate = charinfo.birthdate,
        gender = charinfo.gender,
        nationality = charinfo.nationality,
        licence = key,
        issued = os.date('%Y-%m-%d') --[[@as string]],
    }
end

exports('CardMetadata', cardMetadata)

exports('UseCard', function(event, item, inventory, slot)
    if event ~= 'usedItem' or not CARD_ITEMS[item.name] then return end

    local source <const> = inventory.source

    showCard(source, settings.showNearby and nearbyViewers(source) or {}, slot.metadata)
end)
