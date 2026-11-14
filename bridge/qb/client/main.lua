require 'bridge.qb.client.events'
require 'bridge.qb.client.drawtext'

local qbShared <const> = require 'bridge.qb.shared.main'
local qbFunctions <const> = require 'bridge.qb.client.functions'
local sharedConfig <const> = require 'config.shared'

local overrides <const> = {
    GetPlayerData = function(cb)
        local playerData <const> = qbShared.playerData(Cobalt.PlayerData)
        if not cb then return playerData end

        cb(playerData)
    end,
    HasItem = function(items, amount)
        return qbShared.hasItems(function(name, count)
            return exports.cobalt_inventory:HasItem(name, count)
        end, items, amount)
    end,
}

---@return table<string, function> functions qb-core's client QBCore.Functions
local function buildFunctions()
    local functions <const> = {}

    for name, fn in pairs(Cobalt.Functions) do
        functions[name] = fn
    end

    for name, fn in pairs(qbFunctions) do
        functions[name] = fn
    end

    for name, fn in pairs(overrides) do
        functions[name] = fn
    end

    return functions
end

---@return table QBCore
local function buildCore()
    local core <const> = {}

    for key, value in pairs(Cobalt) do
        core[key] = value
    end

    core.Shared = qbShared.shared()
    core.Config = qbShared.config({
        StatusInterval = sharedConfig.status.starvingDamageSeconds * 1000,
        Server = {},
    })
    core.PlayerData = qbShared.playerData(Cobalt.PlayerData)
    core.Functions = buildFunctions()

    return core
end

qbShared.export('GetCoreObject', qbShared.coreObjectExport(buildCore))
qbShared.exportShared()

---@type table<string, true>
local exportedByDrawText <const> = { DrawText = true }

for name, fn in pairs(buildFunctions()) do
    if not exportedByDrawText[name] then
        qbShared.export(name, fn)
    end
end
