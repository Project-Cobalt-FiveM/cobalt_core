local defaults <const> = require 'server.defaults'
local sharedConfig <const> = require 'config.shared'
local stateIds <const> = require 'server.stateid'

Cobalt.Players = {}
Cobalt.PlayersByCid = {}
Cobalt.PlayersByLicense = {}
Cobalt.PlayersByPhone = {}
Cobalt.Player = {}

local OFFLINE_TTL <const> = 60

---@class OfflineEntry
---@field player CorePlayer
---@field expires integer `os.time()` it goes stale at, 0 once evicted

---@type table<string, OfflineEntry>
local offlineByCid <const> = {}
---@type table<string, OfflineEntry> the license's most recently updated character
local offlineByLicense <const> = {}
---@type table<string, OfflineEntry>
local offlineByPhone <const> = {}

---@param index table<string, OfflineEntry>
---@param key string
---@return CorePlayer?
local function cachedOffline(index, key)
    local entry <const> = index[key]

    if entry and os.time() < entry.expires then return entry.player end
end

---@param player CorePlayer
---@return OfflineEntry
local function cacheOffline(player)
    local data <const> = player.PlayerData
    local entry <const> = { player = player, expires = os.time() + OFFLINE_TTL }

    offlineByCid[data.citizenid] = entry

    if data.phone_number then offlineByPhone[data.phone_number] = entry end

    return entry
end

---@param index table<string, OfflineEntry>
---@param now integer
local function sweep(index, now)
    for key, entry in pairs(index) do
        if now >= entry.expires then index[key] = nil end
    end
end

SetInterval(function()
    local now <const> = os.time()

    sweep(offlineByCid, now)
    sweep(offlineByLicense, now)
    sweep(offlineByPhone, now)
end, OFFLINE_TTL * 1000)

---Expires a character's cached copy under all its keys and forgets the license's most recent character.
---@param citizenid? string
---@param license? string
local function evictOfflineCache(citizenid, license)
    local entry <const> = offlineByCid[citizenid]

    if entry then entry.expires = 0 end
    if license then offlineByLicense[license] = nil end
end

---@param index table<string, CorePlayer>
---@param key? string
---@param Player CorePlayer
local function unindexKey(index, key, Player)
    if index[key] == Player then index[key] = nil end
end

---Takes a character out of the citizenid, license and phone indexes and expires its cached offline copy.
---@param Player CorePlayer
function Cobalt.Player.Unindex(Player)
    local data <const> = Player.PlayerData

    unindexKey(Cobalt.PlayersByCid, data.citizenid, Player)
    unindexKey(Cobalt.PlayersByLicense, data.license, Player)
    unindexKey(Cobalt.PlayersByPhone, data.phone_number, Player)
    evictOfflineCache(data.citizenid, data.license)
end

---Records the number npwd stored in `players.phone_number` for a loaded character, in memory and on its client.
---@param citizenid string
---@param number string
function Cobalt.Player.SetPhoneNumber(citizenid, number)
    local Player <const> = Cobalt.PlayersByCid[citizenid]

    if not Player or Player.PlayerData.phone_number == number then return end

    unindexKey(Cobalt.PlayersByPhone, Player.PlayerData.phone_number, Player)
    Cobalt.PlayersByPhone[number] = Player
    Player.Functions.SetPlayerData('phone_number', number)
end

local function SyncIdentityStateBags(source, playerData)
    local state <const> = Player(source).state
    state:set('cobalt:citizenid', playerData.citizenid, true)
    local charinfo <const> = playerData.charinfo
    if charinfo then
        state:set('cobalt:name', charinfo.firstname .. ' ' .. charinfo.lastname, true)
    end
    state:set('LoggedIn', true, true)
end

local function ClearPlayerStateBags(source)
    local state <const> = Player(source).state
    state:set('cobalt:citizenid', nil, true)
    state:set('cobalt:name', nil, true)
    state:set('LoggedIn', false, true)
end

---@param source integer
---@return string?
local function SessionCitizenId(source)
    return Player(source).state['cobalt:citizenid']
end

local jsonColumns <const> = { 'money', 'charinfo', 'position', 'metadata' }

local SELECT_PLAYER <const> = [[
    SELECT p.citizenid, p.cid, p.license, p.name, p.phone_number, p.money, p.charinfo, p.position, p.metadata,
        s.state_id
    FROM players p LEFT JOIN state_ids s ON s.license = p.license
]]

---@alias PlayerKey 'citizenid' | 'license' | 'phone' | 'charinfo'

---@type table<PlayerKey, string>
local PLAYER_BY <const> = {
    citizenid = SELECT_PLAYER .. 'WHERE p.citizenid = ? LIMIT 1',
    license = SELECT_PLAYER .. 'WHERE p.license = ? ORDER BY p.last_updated DESC LIMIT 1',
    phone = SELECT_PLAYER .. 'WHERE p.phone_number = ? LIMIT 1',
    charinfo = SELECT_PLAYER .. 'WHERE JSON_UNQUOTE(JSON_EXTRACT(p.charinfo, ?)) = ? LIMIT 1',
}

---@param row table?
---@return table?
local function decodePlayerRow(row)
    if not row then return nil end

    local playerData <const> = {
        citizenid = row.citizenid,
        cid = row.cid,
        license = row.license,
        name = row.name,
        phone_number = row.phone_number,
        stateid = row.state_id,
    }

    for i = 1, #jsonColumns do
        local column <const> = jsonColumns[i]
        playerData[column] = row[column] and json.decode(row[column]) or nil
    end

    return playerData
end

---@param citizenid string
---@return table?
local function fetchPlayer(citizenid)
    return decodePlayerRow(MySQL.single.await(PLAYER_BY.citizenid, { citizenid }))
end

local SAVE_PLAYERS <const> = [[
    INSERT INTO players (citizenid, cid, license, name, money, charinfo, position, metadata)
    VALUES %s
    ON DUPLICATE KEY UPDATE cid = VALUES(cid), license = VALUES(license), name = VALUES(name),
        money = VALUES(money), charinfo = VALUES(charinfo), position = VALUES(position),
        metadata = VALUES(metadata)
]]
local PLAYER_ROW <const> = '(?, ?, ?, ?, ?, ?, ?, ?)'
local PLAYER_ROW_FIELDS <const> = 8
local ROWS_PER_STATEMENT <const> = 250
local ROWS_PER_FRAME <const> = 50
local ROW_SEPARATOR <const> = string.char(31)

---@param PlayerData table
---@param position table
---@return string[] row
local function playerRow(PlayerData, position)
    return {
        PlayerData.citizenid,
        tonumber(PlayerData.cid) or 0,
        PlayerData.license,
        PlayerData.name,
        json.encode(PlayerData.money),
        json.encode(PlayerData.charinfo),
        json.encode(position),
        json.encode(PlayerData.metadata),
    }
end

---@param rows string[][]
---@param dispatchOnly? boolean send the query without waiting for it, for when cobalt_core is stopping
local function writePlayers(rows, dispatchOnly)
    local params <const> = table.create(#rows * PLAYER_ROW_FIELDS, 0)

    for _, row in ipairs(rows) do
        table.move(row, 1, PLAYER_ROW_FIELDS, #params + 1, params)
    end

    local query <const> = SAVE_PLAYERS:format(PLAYER_ROW:rep(#rows, ', '))

    if dispatchOnly then return MySQL.update(query, params) end

    MySQL.update.await(query, params)
end

---@param PlayerData table
---@param position table
local function savePlayer(PlayerData, position)
    writePlayers({ playerRow(PlayerData, position) })
end

---@type table<integer, true>
local loggingIn <const> = {}

---@param source integer
---@param citizenid string|false
---@param newData? table
---@return boolean
local function loadCharacter(source, citizenid, newData)
    if not citizenid then
        Cobalt.Player.CheckPlayerData(source, newData)

        return true
    end

    local license <const> = Cobalt.Functions.GetIdentifier(source, 'license')
    local PlayerData <const> = fetchPlayer(citizenid)

    if not PlayerData or license ~= PlayerData.license then
        DropPlayer(source, Lang:t('info.exploit_dropped'))

        return false
    end

    Cobalt.Player.CheckPlayerData(source, PlayerData)

    return true
end

---@param source integer
---@param citizenid string|false
---@param newData? table
---@return boolean
function Cobalt.Player.Login(source, citizenid, newData)
    if not source or source == '' then
        lib.print.error('login called without a source')

        return false
    end

    if loggingIn[source] or Cobalt.Players[source] then return false end

    loggingIn[source] = true

    local ok <const>, loaded <const> = pcall(loadCharacter, source, citizenid, newData)

    loggingIn[source] = nil

    if not ok then error(loaded, 0) end

    return loaded
end

---@param key string
---@return string path
local function jsonPath(key)
    if type(key) ~= 'string' or not key:match('^[%a_][%w_]*$') then
        error(('%s is not a valid key'):format(key), 3)
    end

    return '$.' .. key
end

---Runs one keyed query. If the character logged in while the query ran, it returns the online player. If another
---lookup cached the character meanwhile, it returns that copy, so each character has one offline player at a time.
---@param key PlayerKey
---@param ... string|number
---@return CorePlayer?
local function loadPlayer(key, ...)
    local row <const> = MySQL.single.await(PLAYER_BY[key], { ... })

    if not row then return nil end

    local online <const> = Cobalt.PlayersByCid[row.citizenid]

    if online then return online end

    local entry = offlineByCid[row.citizenid]

    if not entry or os.time() >= entry.expires then
        entry = cacheOffline(Cobalt.Player.CheckPlayerData(nil, decodePlayerRow(row)) --[[@as CorePlayer]])
    end

    if key == 'license' then offlineByLicense[row.license] = entry end

    return entry.player
end

---@param online table<string, CorePlayer>
---@param offline table<string, OfflineEntry>
---@param key PlayerKey
---@param value string
---@param onlineOnly? boolean
---@return CorePlayer?
local function findPlayer(online, offline, key, value, onlineOnly)
    local player <const> = online[value]

    if player or onlineOnly then return player end
    if type(value) ~= 'string' or value == '' then return nil end

    return cachedOffline(offline, value) or loadPlayer(key, value)
end

---Returns the character with this citizenid, online from memory or else loaded from `players` and cached for a
---minute. A player loaded from the database has `Offline = true` and no `PlayerData.source`.
---@param citizenid string
---@param onlineOnly? boolean look at online players only, never the database
---@return CorePlayer?
function Cobalt.Functions.GetPlayerByCitizenId(citizenid, onlineOnly)
    return findPlayer(Cobalt.PlayersByCid, offlineByCid, 'citizenid', citizenid, onlineOnly)
end

---Returns the character on this Rockstar license, online from memory or else the license's character whose row
---changed last (`players.last_updated`, normally the last one played), loaded and cached for a minute. A player
---loaded from the database has `Offline = true` and no `PlayerData.source`.
---@param license string
---@param onlineOnly? boolean look at online players only, never the database
---@return CorePlayer?
function Cobalt.Functions.GetPlayerByLicense(license, onlineOnly)
    return findPlayer(Cobalt.PlayersByLicense, offlineByLicense, 'license', license, onlineOnly)
end

---Returns the character whose npwd number in `players.phone_number` is `number`, online from memory or else loaded
---and cached for a minute. A player loaded from the database has `Offline = true` and no `PlayerData.source`.
---@param number string
---@param onlineOnly? boolean look at online players only, never the database
---@return CorePlayer?
function Cobalt.Functions.GetPlayerByPhone(number, onlineOnly)
    return findPlayer(Cobalt.PlayersByPhone, offlineByPhone, 'phone', number, onlineOnly)
end

---Returns the first online character whose `charinfo[property]` equals `value`, or else the first matching row,
---cached for a minute. Charinfo values such as names repeat, so the database match is whichever row MariaDB reads
---first. A player loaded from the database has `Offline = true` and no `PlayerData.source`. Errors when the lookup
---reaches the database and `property` isn't an identifier.
---@param property string charinfo key: letters, digits and underscores, not starting with a digit
---@param value string|number
---@param onlineOnly? boolean look at online players only, never the database
---@return CorePlayer?
function Cobalt.Functions.GetPlayerByCharInfo(property, value, onlineOnly)
    if value == nil then return nil end

    for _, Player in pairs(Cobalt.Players) do
        if Player.PlayerData.charinfo[property] == value then return Player end
    end

    if onlineOnly then return nil end

    return loadPlayer('charinfo', jsonPath(property), value)
end

---@type table<string, true>
local MEMBERSHIP_KEYS <const> = { job = true, gang = true }

---@param playerData table
---@param template table
local function applyDefaults(playerData, template)
    for key, value in pairs(template) do
        if type(value) == 'table' then
            playerData[key] = playerData[key] or {}
            applyDefaults(playerData[key], value)
        elseif playerData[key] == nil then
            playerData[key] = type(value) == 'function' and value() or value
        end
    end
end

function Cobalt.Player.CheckPlayerData(source, PlayerData)
    PlayerData = PlayerData or {}
    local Offline <const> = not source

    if source then
        PlayerData.source = source
        PlayerData.license = PlayerData.license or Cobalt.Functions.GetIdentifier(source, 'license')
        PlayerData.name = GetPlayerName(source)
        PlayerData.stateid = stateIds.claim(PlayerData.license)
    end

    applyDefaults(PlayerData, defaults)

    for moneytype, amount in pairs(sharedConfig.money.starting) do
        if moneytype ~= 'bank' and PlayerData.money[moneytype] == nil then
            PlayerData.money[moneytype] = amount
        end
    end

    PlayerData.metadata.cash = PlayerData.metadata.cash or PlayerData.money.cash or 0
    PlayerData.money.cash = PlayerData.metadata.cash

    if sharedConfig.status.hungerRate == 0 then PlayerData.metadata.hunger = 100 end
    if sharedConfig.status.thirstRate == 0 then PlayerData.metadata.thirst = 100 end

    PlayerData.job = PlayerData.metadata.job
    PlayerData.gang = PlayerData.metadata.gang

    return Cobalt.Player.CreatePlayer(PlayerData, Offline)
end

function Cobalt.Player.Logout(source)
    ClearPlayerStateBags(source)
    TriggerClientEvent('cobalt_core:Client:OnPlayerUnload', source)
    TriggerEvent('cobalt_core:Server:OnPlayerUnload', source)

    local Player <const> = Cobalt.Players[source]
    if Player?.PlayerData then
        pcall(function() Player.Functions.Save() end)
        Cobalt.Player.Unindex(Player)
    end
    Cobalt.Players[source] = nil
end

Cobalt.PlayerClass = {}
local Player <const> = Cobalt.PlayerClass
Player.__index = Player

---Sends the whole PlayerData to the player's client, or only the listed top-level fields.
---@param fields? string[]
function Player:UpdatePlayerData(fields)
    if self.Offline then return end

    TriggerEvent('cobalt_core:Player:SetPlayerData', self.PlayerData)

    if not fields then
        return TriggerClientEvent('cobalt_core:Player:SetPlayerData', self.PlayerData.source, self.PlayerData)
    end

    local changes <const>, cleared <const> = {}, {}

    for i = 1, #fields do
        local field <const> = fields[i]
        local value <const> = self.PlayerData[field]

        if value == nil then
            cleared[#cleared + 1] = field
        else
            changes[field] = value
        end
    end

    TriggerClientEvent('cobalt_core:Player:UpdatePlayerData', self.PlayerData.source, changes, cleared)
end

function Player:Notify(text, type, length)
    Cobalt.Functions.Notify(self.PlayerData.source, text, type, length)
end

---@param charinfo? { firstname?: string, lastname?: string }
---@return string?
local function formatName(charinfo)
    if not charinfo then return nil end

    local name <const> = ('%s %s'):format(charinfo.firstname or '', charinfo.lastname or ''):match('^%s*(.-)%s*$')

    return name ~= '' and name or nil
end

---@return string?
function Player:GetName()
    return formatName(self.PlayerData.charinfo)
end

---@param target integer | string server id or citizenid
---@return string?
function Cobalt.Functions.GetName(target)
    local online <const> = type(target) == 'number'
        and Cobalt.Players[math.tointeger(target)]
        or Cobalt.PlayersByCid[target]

    if online then return formatName(online.PlayerData.charinfo) end

    if type(target) ~= 'string' then return nil end

    local name <const> = MySQL.scalar.await('SELECT fullname FROM players WHERE citizenid = ? LIMIT 1', { target })

    return name ~= '' and name or nil
end

local READ_METADATA <const> = 'SELECT citizenid, JSON_EXTRACT(metadata, ?) AS value FROM players WHERE citizenid IN (?)'
local WRITE_METADATA <const> = "UPDATE players SET metadata = JSON_SET(metadata, ?, JSON_EXTRACT(?, '$')) WHERE citizenid = ?"

---@param citizenids string[]
---@param key string
---@return table<string, any> values
function Cobalt.Functions.GetMetaData(citizenids, key)
    local path <const> = jsonPath(key)
    local values <const>, offline <const> = {}, {}

    for _, citizenid in ipairs(citizenids) do
        local online <const> = Cobalt.PlayersByCid[citizenid]

        if online then
            values[citizenid] = online.PlayerData.metadata[key]
        elseif type(citizenid) == 'string' then
            offline[#offline + 1] = citizenid
        end
    end

    if #offline == 0 then return values end

    for _, row in ipairs(MySQL.query.await(READ_METADATA, { path, offline }) or {}) do
        if row.value then values[row.citizenid] = json.decode(row.value) end
    end

    return values
end

---@param citizenid string
---@param key string
---@param value any
---@return boolean written
function Cobalt.Functions.SetMetaData(citizenid, key, value)
    local path <const> = jsonPath(key)

    if type(citizenid) ~= 'string' then return false end

    local online <const> = Cobalt.PlayersByCid[citizenid]

    if online then
        online.Functions.SetMetaData(key, value)
        value = online.PlayerData.metadata[key]
    end

    local written <const> = MySQL.update.await(WRITE_METADATA, { path, json.encode(value), citizenid }) == 1

    if written then evictOfflineCache(citizenid) end

    return written
end

---Sets one PlayerData field, or several at once from a `{ [field] = value }` table, and sends only those.
---@param key string | table<string, any>
---@param val? any
function Player:SetPlayerData(key, val)
    if type(key) == 'string' then
        self.PlayerData[key] = val

        return self:UpdatePlayerData({ key })
    end

    if type(key) ~= 'table' then return end

    local fields <const> = {}

    for field, value in pairs(key) do
        self.PlayerData[field] = value
        fields[#fields + 1] = field
    end

    self:UpdatePlayerData(fields)
end

function Player:SetMetaData(meta, val)
    if not meta or type(meta) ~= 'string' then return end
    if meta == 'hunger' or meta == 'thirst' then
        val = val > 100 and 100 or val
    end
    self.PlayerData.metadata[meta] = val

    if MEMBERSHIP_KEYS[meta] then
        self.PlayerData[meta] = val

        return self:UpdatePlayerData({ 'metadata', meta })
    end

    self:UpdatePlayerData({ 'metadata' })
end

function Player:GetMetaData(meta)
    if not meta or type(meta) ~= 'string' then return end
    return self.PlayerData.metadata[meta]
end

function Player:AddRep(rep, amount)
    if not rep or not amount then return end
    local addAmount <const> = tonumber(amount)
    local currentRep <const> = self.PlayerData.metadata.rep[rep] or 0
    self.PlayerData.metadata.rep[rep] = currentRep + addAmount
    self:UpdatePlayerData({ 'metadata' })
end

function Player:RemoveRep(rep, amount)
    if not rep or not amount then return end
    local removeAmount <const> = tonumber(amount)
    local currentRep <const> = self.PlayerData.metadata.rep[rep] or 0
    if currentRep - removeAmount < 0 then
        self.PlayerData.metadata.rep[rep] = 0
    else
        self.PlayerData.metadata.rep[rep] = currentRep - removeAmount
    end
    self:UpdatePlayerData({ 'metadata' })
end

function Player:GetRep(rep)
    if not rep then return end
    return self.PlayerData.metadata.rep[rep] or 0
end

---@param self table
---@return integer
local function bankBalance(self)
    return exports.cobalt_banking:GetBalance(self.PlayerData.citizenid)
end

---@param self table
---@param op 'add' | 'remove' | 'set'
---@param amount integer
---@param reason string
---@return boolean ok
---@return integer|string balanceOrError
local function writeBank(self, op, amount, reason)
    local banking <const> = exports.cobalt_banking
    local citizenid <const> = self.PlayerData.citizenid
    local details <const> = { note = reason, initiator = citizenid }

    if op == 'add' then return banking:Deposit(citizenid, amount, details) end
    if op == 'remove' then return banking:Withdraw(citizenid, amount, details) end

    return banking:AdjustBalance(citizenid, amount - bankBalance(self), details)
end

---@param self table
---@param moneytype string
---@return integer
local function walletBalance(self, moneytype)
    if moneytype == 'cash' then return self.PlayerData.metadata.cash or 0 end
    return self.PlayerData.money[moneytype] or 0
end

---@param self table
---@param moneytype string
---@param amount integer
local function setWallet(self, moneytype, amount)
    if moneytype == 'cash' then self.PlayerData.metadata.cash = amount end
    self.PlayerData.money[moneytype] = amount
end

local WRITE_CASH <const> = [[
    UPDATE players SET money = JSON_SET(money, '$.cash', ?), metadata = JSON_SET(metadata, '$.cash', ?)
    WHERE citizenid = ?
]]
local STORED_CASH <const> = "COALESCE(CAST(JSON_VALUE(metadata, '$.cash') AS SIGNED), CAST(JSON_VALUE(money, '$.cash') AS SIGNED), 0)"
local SHIFT_CASH <const> = ([[
    UPDATE players
    SET metadata = JSON_SET(metadata, '$.cash', %s + ?),
        money = JSON_SET(money, '$.cash', CAST(JSON_VALUE(metadata, '$.cash') AS SIGNED))
    WHERE citizenid = ?
]]):format(STORED_CASH)
local DEBIT_CASH <const> = ('%s    AND %s >= ?'):format(SHIFT_CASH, STORED_CASH)
local WRITE_WALLET <const> = 'UPDATE players SET money = JSON_SET(money, ?, ?) WHERE citizenid = ?'

---Writes one wallet balance to its row, in the same places the full save writes it.
---@param citizenid string
---@param moneytype string
---@param amount number
---@return boolean written
local function persistWallet(citizenid, moneytype, amount)
    if moneytype == 'cash' then
        return MySQL.update.await(WRITE_CASH, { amount, amount, citizenid }) == 1
    end

    return MySQL.update.await(WRITE_WALLET, { ('$."%s"'):format(moneytype), amount, citizenid }) == 1
end

---Moves `amount` cash between two rows in one transaction, which rolls back when the giver's row holds less.
---@param fromCid string
---@param toCid string
---@param amount integer
---@return boolean written
local function persistCashTransfer(fromCid, toCid, amount)
    return MySQL.startTransaction(function(query)
        if query(DEBIT_CASH, { -amount, fromCid, amount }).affectedRows ~= 1 then return false end

        return query(SHIFT_CASH, { amount, toCid }).affectedRows == 1
    end) == true
end

---@param self table
---@param op 'add' | 'remove' | 'set'
---@param moneytype string
---@param amount integer
---@param reason string
---@return boolean
local function writeMoney(self, op, moneytype, amount, reason)
    if moneytype == 'bank' then
        local ok <const>, balance <const> = writeBank(self, op, amount, reason)

        if not ok then return false end

        self.PlayerData.money.bank = balance
        return true
    end

    local before <const> = walletBalance(self, moneytype)
    local after = amount

    if op == 'add' then
        after = before + amount
    elseif op == 'remove' then
        after = before - amount
    end

    if after < 0 then return false end

    setWallet(self, moneytype, after)

    if after == before then return true end

    local saved <const>, written <const> = pcall(persistWallet, self.PlayerData.citizenid, moneytype, after)

    if saved and written then return true end

    setWallet(self, moneytype, walletBalance(self, moneytype) - (after - before))
    return false
end

---@param self table
---@param op 'add' | 'remove' | 'set'
---@param moneytype string
---@param amount number
---@param reason string
local function announceMoneyChange(self, op, moneytype, amount, reason)
    if self.Offline then return end

    local source <const> = self.PlayerData.source

    self:UpdatePlayerData(moneytype == 'cash' and { 'money', 'metadata' } or { 'money' })

    TriggerClientEvent('cobalt_core:Client:OnMoneyChange', source, moneytype, amount, op, reason)
    TriggerEvent('cobalt_core:Server:OnMoneyChange', source, moneytype, amount, op, reason)
end

---@param self table
---@param op 'add' | 'remove' | 'set'
---@param moneytype string
---@param amount number?
---@param reason string?
---@return boolean
local function changeMoney(self, op, moneytype, amount, reason)
    moneytype = moneytype:lower()
    amount = tonumber(amount)
    if not amount or amount ~= amount or amount < 0 or amount == math.huge then return false end

    reason = reason or 'unknown'

    if not writeMoney(self, op, moneytype, amount, reason) then return false end

    announceMoneyChange(self, op, moneytype, amount, reason)

    return true
end

---Moves cash from one loaded character to another, writing both rows in one transaction.
---@param from CorePlayer
---@param to CorePlayer
---@param amount integer
---@param reason string
---@return boolean moved
function Cobalt.Player.TransferCash(from, to, amount, reason)
    local fromBefore <const> = walletBalance(from, 'cash')
    local toBefore <const> = walletBalance(to, 'cash')

    if amount < 1 or fromBefore < amount then return false end

    setWallet(from, 'cash', fromBefore - amount)
    setWallet(to, 'cash', toBefore + amount)

    if not persistCashTransfer(from.PlayerData.citizenid, to.PlayerData.citizenid, amount) then
        setWallet(from, 'cash', walletBalance(from, 'cash') + amount)
        setWallet(to, 'cash', walletBalance(to, 'cash') - amount)

        return false
    end

    announceMoneyChange(from, 'remove', 'cash', amount, reason)
    announceMoneyChange(to, 'add', 'cash', amount, reason)

    return true
end

function Player:AddMoney(moneytype, amount, reason)
    return changeMoney(self, 'add', moneytype, amount, reason)
end

function Player:RemoveMoney(moneytype, amount, reason)
    return changeMoney(self, 'remove', moneytype, amount, reason)
end

function Player:SetMoney(moneytype, amount, reason)
    return changeMoney(self, 'set', moneytype, amount, reason)
end

function Player:GetMoney(moneytype)
    if not moneytype then return false end

    moneytype = moneytype:lower()
    if moneytype == 'bank' then return bankBalance(self) end

    return walletBalance(self, moneytype)
end

---@param balance integer
function Player:SyncBank(balance)
    self.PlayerData.money.bank = balance
    if self.Offline then return end

    self:UpdatePlayerData({ 'money' })
    TriggerClientEvent('cobalt_core:Client:OnMoneyChange', self.PlayerData.source, 'bank', balance, 'set', 'sync')
end

function Player:Save()
    if self.Offline then
        Cobalt.Player.SaveOffline(self.PlayerData)
    else
        Cobalt.Player.Save(self.PlayerData.source)
    end
end

function Player:Logout()
    if self.Offline then return end
    Cobalt.Player.Logout(self.PlayerData.source)
end

function Player:AddMethod(methodName, handler)
    if type(methodName) ~= 'string' or methodName == '' then
        return false, 'methodName must be a non-empty string'
    end
    if type(handler) ~= 'function' then
        return false, 'handler must be a function'
    end
    if Player[methodName] then
        return false, ('method %q already exists on Player class'):format(methodName)
    end
    Player[methodName] = handler
    return true
end

function Player:AddField(fieldName, value)
    if type(fieldName) ~= 'string' or fieldName == '' then
        return false, 'fieldName must be a non-empty string'
    end
    if type(value) == 'function' then
        return false, 'value must not be a function (use AddMethod)'
    end
    if Player[fieldName] then
        return false, ('field %q already exists on Player class'):format(fieldName)
    end
    Player[fieldName] = value
    return true
end

function Cobalt.Player.CreatePlayer(PlayerData, Offline)
    local self <const> = setmetatable({
        PlayerData = PlayerData,
        Offline    = Offline,
    }, Player)

    self.Functions = {}
    for methodName, fn in pairs(Player) do
        if type(fn) == 'function' then
            self.Functions[methodName] = function(...) return fn(self, ...) end
        end
    end

    self.Functions.AddMethod = function(methodName, handler)
        if type(methodName) == 'string' and type(handler) == 'function' then
            self.Functions[methodName] = function(...) return handler(self, ...) end
        end
    end

    self.Functions.AddField = function(fieldName, data)
        if type(fieldName) == 'string' then
            rawset(self, fieldName, data)
        end
    end

    if self.Offline then
        return self
    else
        Cobalt.Players[self.PlayerData.source] = self
        Cobalt.PlayersByCid[self.PlayerData.citizenid] = self
        Cobalt.PlayersByLicense[self.PlayerData.license] = self
        if self.PlayerData.phone_number then
            Cobalt.PlayersByPhone[self.PlayerData.phone_number] = self
        end
        evictOfflineCache(self.PlayerData.citizenid, self.PlayerData.license)

        Cobalt.Player.Save(self.PlayerData.source)

        SyncIdentityStateBags(self.PlayerData.source, self.PlayerData)

        TriggerEvent('cobalt_core:Server:PlayerLoaded', self)
        self.Functions.UpdatePlayerData()
        TriggerClientEvent('cobalt_core:Client:OnPlayerLoaded', self.PlayerData.source)
    end
end

function Cobalt.Functions.AddPlayerMethod(ids, methodName, handler)
    local idType <const> = type(ids)
    if idType == 'number' then
        if ids == -1 then
            return Cobalt.PlayerClass:AddMethod(methodName, handler)
        else
            if not Cobalt.Players[ids] then return end

            Cobalt.Players[ids].Functions.AddMethod(methodName, handler)
        end
    elseif idType == 'table' and table.type(ids) == 'array' then
        for i = 1, #ids do
            Cobalt.Functions.AddPlayerMethod(ids[i], methodName, handler)
        end
    end
end

function Cobalt.Functions.AddPlayerField(ids, fieldName, data)
    local idType <const> = type(ids)
    if idType == 'number' then
        if ids == -1 then
            return Cobalt.PlayerClass:AddField(fieldName, data)
        else
            if not Cobalt.Players[ids] then return end

            Cobalt.Players[ids].Functions.AddField(fieldName, data)
        end
    elseif idType == 'table' and table.type(ids) == 'array' then
        for i = 1, #ids do
            Cobalt.Functions.AddPlayerField(ids[i], fieldName, data)
        end
    end
end


---@param Player table
---@return string[] row
local function onlineRow(Player)
    local PlayerData <const> = Player.PlayerData
    local ped <const> = GetPlayerPed(PlayerData.source)

    if ped ~= 0 and DoesEntityExist(ped) then
        PlayerData.metadata.armor = GetPedArmour(ped)

        local hp <const> = GetEntityHealth(ped)

        if hp and hp > 0 then PlayerData.metadata.health = math.min(hp, GetEntityMaxHealth(ped)) end

        local coords <const> = GetEntityCoords(ped)

        if #coords > 1.0 then Player.lastPosition = { x = coords.x, y = coords.y, z = coords.z } end
    end

    return playerRow(PlayerData, Player.lastPosition or PlayerData.position)
end

---@param row string[]
---@return string
local function rowKey(row)
    return table.concat(row, ROW_SEPARATOR)
end

---@param source integer
function Cobalt.Player.Save(source)
    local Player <const> = Cobalt.Players[source]

    if not Player?.PlayerData then
        return lib.print.error('save called without player data')
    end

    if Player.deleted then return end

    local row <const> = onlineRow(Player)

    writePlayers({ row })
    Player.savedRow = rowKey(row)
end

---@param batch { Player: table, row: string[] }[]
---@param dispatchOnly? boolean
local function writeBatch(batch, dispatchOnly)
    local live <const> = table.create(#batch, 0)

    for _, entry in ipairs(batch) do
        local Player <const> = entry.Player

        if not Player.deleted and Cobalt.PlayersByCid[Player.PlayerData.citizenid] == Player then
            live[#live + 1] = entry
        end
    end

    if #live == 0 then return end

    local rows <const> = table.create(#live, 0)

    for i, entry in ipairs(live) do rows[i] = entry.row end

    local ok <const>, err <const> = pcall(writePlayers, rows, dispatchOnly)

    if not ok then
        return lib.print.error(('saving %d players failed: %s'):format(#live, err))
    end

    for _, entry in ipairs(live) do entry.Player.savedRow = rowKey(entry.row) end
end

local isSavingAll = false

---Saves every online player whose saved row changed since their last save, a few hundred rows per statement.
---@param dispatchOnly? boolean send without waiting or yielding, for when cobalt_core is stopping
function Cobalt.Player.SaveAll(dispatchOnly)
    if isSavingAll and not dispatchOnly then return end

    isSavingAll = true

    local online <const> = {}

    for _, Player in pairs(Cobalt.Players) do online[#online + 1] = Player end

    local batch = {}

    for i, Player in ipairs(online) do
        if Cobalt.Players[Player.PlayerData.source] == Player and not Player.deleted then
            local ok <const>, row <const> = pcall(onlineRow, Player)

            if not ok then
                lib.print.error(('save failed for %s: %s'):format(Player.PlayerData.source, row))
            elseif rowKey(row) ~= Player.savedRow then
                batch[#batch + 1] = { Player = Player, row = row }
            end
        end

        if #batch == ROWS_PER_STATEMENT then
            writeBatch(batch, dispatchOnly)
            batch = {}
        end

        if not dispatchOnly and i % ROWS_PER_FRAME == 0 then Wait(0) end
    end

    if #batch > 0 then writeBatch(batch, dispatchOnly) end

    isSavingAll = false
end

function Cobalt.Player.SaveOffline(PlayerData)
    if not PlayerData then
        return lib.print.error('offline save called without player data')
    end

    savePlayer(PlayerData, PlayerData.position)
    evictOfflineCache(PlayerData.citizenid, PlayerData.license)
end

local DELETE_CHARACTER <const> = {
    'DELETE c FROM player_outfit_codes c JOIN player_outfits o ON o.id = c.outfitid WHERE o.citizenid = ?',
    'DELETE FROM player_outfits WHERE citizenid = ?',
    'DELETE FROM playerskins WHERE citizenid = ?',
    'DELETE FROM players WHERE citizenid = ?',
}

---@param citizenid string
---@return CorePlayer?
local function detachCharacter(citizenid)
    local Player <const> = Cobalt.PlayersByCid[citizenid]

    if not Player then return end

    Player.deleted = true
    Cobalt.Player.Unindex(Player)

    return Player
end

---@param citizenid string
---@param license string
---@param reason 'voluntary' | 'admin'
---@return boolean deleted
local function cascadeDelete(citizenid, license, reason)
    evictOfflineCache(citizenid, license)
    TriggerEvent('cobalt_core:characterDeleting', citizenid, reason)

    local queries <const> = {}
    for i = 1, #DELETE_CHARACTER do
        queries[i] = { query = DELETE_CHARACTER[i], values = { citizenid } }
    end

    if not MySQL.transaction.await(queries) then
        exports.cobalt_core:Log(
            'core.character_delete_failed',
            ('Deleting character %s rolled back'):format(citizenid),
            { citizenid = citizenid, reason = reason },
            'error'
        )

        return false
    end

    TriggerEvent('cobalt_core:characterDeleted', citizenid, reason)

    return true
end

---@param source integer
---@param citizenid string
---@return boolean deleted
function Cobalt.Player.DeleteCharacter(source, citizenid)
    local license <const> = Cobalt.Functions.GetIdentifier(source, 'license')
    local charLicense <const> = MySQL.scalar.await('SELECT license FROM players WHERE citizenid = ?', { citizenid })

    if not charLicense or license ~= charLicense then
        DropPlayer(source, Lang:t('info.exploit_dropped'))

        return false
    end

    if Cobalt.PlayersByCid[citizenid] then return false end

    return cascadeDelete(citizenid, charLicense, 'voluntary')
end

---@param citizenid string
---@return boolean deleted
function Cobalt.Player.ForceDeleteCharacter(citizenid)
    local license <const> = MySQL.scalar.await('SELECT license FROM players WHERE citizenid = ?', { citizenid })

    if not license then return false end

    local target <const> = detachCharacter(citizenid)

    if target then
        DropPlayer(target.PlayerData.source, Lang:t('kick.character_deleted'))
    end

    return cascadeDelete(citizenid, license, 'admin')
end


function Cobalt.Player.CreateCitizenId()
    local CitizenId <const> = tostring(Cobalt.Shared.RandomStr(3) .. Cobalt.Shared.RandomInt(5)):upper()
    local exists <const> = MySQL.scalar.await('SELECT 1 FROM players WHERE citizenid = ?', { CitizenId })
    if not exists then return CitizenId end
    return Cobalt.Player.CreateCitizenId()
end


function Cobalt.Player.CreateFingerId()
    local FingerId <const> = tostring(Cobalt.Shared.RandomStr(2) .. Cobalt.Shared.RandomInt(3) .. Cobalt.Shared.RandomStr(1) .. Cobalt.Shared.RandomInt(2) .. Cobalt.Shared.RandomStr(3) .. Cobalt.Shared.RandomInt(4))
    local query <const> = "SELECT 1 FROM players WHERE JSON_VALUE(metadata, '$.fingerprint') = ? LIMIT 1"
    local exists <const> = MySQL.scalar.await(query, { FingerId })
    if not exists then return FingerId end
    return Cobalt.Player.CreateFingerId()
end

function Cobalt.Player.CreateWalletId()
    local WalletId <const> = 'Cobalt-' .. math.random(11111111, 99999999)
    local query <const> = "SELECT 1 FROM players WHERE JSON_VALUE(metadata, '$.walletid') = ? LIMIT 1"
    local exists <const> = MySQL.scalar.await(query, { WalletId })
    if not exists then return WalletId end
    return Cobalt.Player.CreateWalletId()
end

---@param source integer
local function restoreSession(source)
    local citizenid <const> = SessionCitizenId(source)

    if not citizenid or Cobalt.Players[source] then return end

    local PlayerData <const> = fetchPlayer(citizenid)

    if PlayerData and PlayerData.license == Cobalt.Functions.GetIdentifier(source, 'license') then
        local ok <const>, loaded <const> = pcall(Cobalt.Player.Login, source, citizenid)

        if ok and loaded then return end
    end

    ClearPlayerStateBags(source)
    lib.print.error(('could not restore %s for player %d after a restart'):format(citizenid, source))
end

MySQL.ready(function()
    while GlobalState['cobalt:migrated:cobalt_core'] ~= true do Wait(50) end

    stateIds.publishOnline()

    for _, playerId in ipairs(GetPlayers()) do
        restoreSession(tonumber(playerId) --[[@as integer]])
    end
end)
