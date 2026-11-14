local qbShared <const> = require 'bridge.qb.shared.main'
local qbPlayer <const> = require 'bridge.qb.server.player'
local useable <const> = require 'bridge.qb.server.useable'
local callbacks <const> = require 'bridge.qb.server.callbacks'

local playerGetters <const> = {
    'GetPlayer',
    'GetPlayerByCitizenId',
    'GetPlayerByLicense',
    'GetPlayerByPhone',
    'GetPlayerByCharInfo',
    'GetOfflinePlayerByCitizenId',
}

---@param account string
---@return table?
local function playerByAccount(account)
    for _, player in pairs(Cobalt.Players) do
        if player.PlayerData.charinfo.account == account then
            return qbPlayer.from(player)
        end
    end
end

---@return string
local function createAccountNumber()
    return qbPlayer.uniqueId(function()
        return ('US0%dQBCore%d%d%d'):format(
            math.random(1, 9),
            math.random(1111, 9999),
            math.random(1111, 9999),
            math.random(11, 99)
        )
    end, 'charinfo.account')
end

---@return string
local function createPhoneNumber()
    return qbPlayer.uniqueId(function()
        return ('%d%d'):format(math.random(100, 999), math.random(1000000, 9999999))
    end, 'charinfo.phone')
end

local overrides <const> = {
    GetQBPlayers = qbPlayer.all,
    GetPlayerByAccount = playerByAccount,
    CreateAccountNumber = createAccountNumber,
    CreatePhoneNumber = createPhoneNumber,
    HasItem = function(source, items, amount)
        return qbShared.hasItems(function(name, count)
            return exports.cobalt_inventory:HasItem(source, name, count)
        end, items, amount)
    end,
    CreateUseableItem = useable.create,
    CanUseItem = useable.find,
    UseItem = useable.use,
    CreateCallback = callbacks.create,
    TriggerClientCallback = callbacks.trigger,
    GetDutyCount = function(job)
        local players <const>, count <const> = Cobalt.Functions.GetPlayersByJob(job, true)

        return count, players
    end,
}

---@return table<string, function> functions qb-core's QBCore.Functions, built from the current Cobalt.Functions
return function()
    local functions <const> = {}

    for name, fn in pairs(Cobalt.Functions) do
        functions[name] = fn
    end

    for _, name in ipairs(playerGetters) do
        functions[name] = qbPlayer.wrap(Cobalt.Functions[name])
    end

    for name, fn in pairs(overrides) do
        functions[name] = fn
    end

    return functions
end
