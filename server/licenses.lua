local TYPES <const> = require 'config.shared'.licenses

---@param target integer|string server id or citizenid
---@return table?
local function playerOf(target)
    if type(target) == 'number' then return Cobalt.Players[math.tointeger(target)] end
    if type(target) ~= 'string' or target == '' then return end

    return Cobalt.Functions.GetPlayerByCitizenId(target) or Cobalt.Functions.GetOfflinePlayerByCitizenId(target)
end

---@param player table
---@param field 'licences'|'licenceGrants'|'licencePoints'|'licenceRevoked'
---@return table
local function storeOf(player, field)
    return player.PlayerData.metadata[field] or {}
end

---@return table<string, LicenseType>
local function GetLicenseTypes()
    return TYPES
end

---@param target integer|string
---@param key string
---@return boolean
local function HasLicense(target, key)
    local player <const> = TYPES[key] and playerOf(target)

    return player and player.PlayerData.metadata.licences?[key] == true or false
end

---@param target integer|string
---@return table<string, LicenseRecord>?
local function GetLicenseRecords(target)
    local player <const> = playerOf(target)

    if not player then return end

    local held <const> = storeOf(player, 'licences')
    local grants <const> = storeOf(player, 'licenceGrants')
    local points <const> = storeOf(player, 'licencePoints')
    local revoked <const> = storeOf(player, 'licenceRevoked')
    local records <const> = {}

    for key, info in pairs(TYPES) do
        local holds <const> = held[key] == true
        local grant <const> = holds and grants[key] or nil

        records[key] = {
            held = holds,
            grantedAt = grant?.at,
            grantedBy = grant?.by,
            revokedAt = not holds and revoked[key] or nil,
            points = points[key] or 0,
            pointsLimit = info.pointsLimit,
        }
    end

    return records
end

---@param player table
---@param key string
---@param granted boolean
---@param issuer? string
---@return boolean changed
local function setLicense(player, key, granted, issuer)
    local licences <const> = storeOf(player, 'licences')

    if (licences[key] == true) == granted then return false end

    local grants <const> = storeOf(player, 'licenceGrants')
    local revoked <const> = storeOf(player, 'licenceRevoked')
    local points <const> = storeOf(player, 'licencePoints')

    licences[key] = granted
    grants[key] = granted and { at = os.time(), by = issuer } or nil
    revoked[key] = not granted and os.time() or nil

    if granted then points[key] = nil end

    player.Functions.SetMetaData('licences', licences)
    player.Functions.SetMetaData('licenceGrants', grants)
    player.Functions.SetMetaData('licenceRevoked', revoked)
    player.Functions.SetMetaData('licencePoints', points)

    if player.Offline then player.Functions.Save() end

    local source <const> = not player.Offline and player.PlayerData.source or nil

    TriggerEvent('cobalt_core:server:licenseChanged', player.PlayerData.citizenid, key, granted, source)

    return true
end

---@param target integer|string
---@param key string
---@param granted boolean
---@param issuer? string
---@return boolean changed
local function changeLicense(target, key, granted, issuer)
    local player <const> = TYPES[key] and playerOf(target)

    return player and setLicense(player, key, granted, issuer) or false
end

---@param target integer|string
---@param key string
---@param amount integer
---@return integer? total
---@return boolean revoked
local function AddLicensePoints(target, key, amount)
    local limit <const> = TYPES[key]?.pointsLimit
    local player <const> = limit and amount > 0 and playerOf(target)

    if not player or player.PlayerData.metadata.licences?[key] ~= true then return nil, false end

    local points <const> = storeOf(player, 'licencePoints')
    local total <const> = (points[key] or 0) + amount

    points[key] = total
    player.Functions.SetMetaData('licencePoints', points)

    if total >= limit then return total, setLicense(player, key, false) end

    if player.Offline then player.Functions.Save() end

    return total, false
end

---@param target integer|string
---@param key string
---@param issuer? string
---@return boolean changed
local function GrantLicense(target, key, issuer)
    return changeLicense(target, key, true, issuer)
end

---@param target integer|string
---@param key string
---@return boolean changed
local function RevokeLicense(target, key)
    return changeLicense(target, key, false)
end

Cobalt.Functions.GetLicenseTypes = GetLicenseTypes
Cobalt.Functions.HasLicense = HasLicense
Cobalt.Functions.GetLicenseRecords = GetLicenseRecords
Cobalt.Functions.GrantLicense = GrantLicense
Cobalt.Functions.RevokeLicense = RevokeLicense
Cobalt.Functions.AddLicensePoints = AddLicensePoints
