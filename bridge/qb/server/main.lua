require 'bridge.qb.server.events'
require 'bridge.qb.server.log'

local qbShared <const> = require 'bridge.qb.shared.main'
local serverConfig <const> = require 'config.server'
local qbPlayer <const> = require 'bridge.qb.server.player'
local buildFunctions <const> = require 'bridge.qb.server.functions'
local buildCommands <const> = require 'bridge.qb.server.commands'
local useable <const> = require 'bridge.qb.server.useable'

---@return table QBCore
local function buildCore()
    local core <const> = {}

    for key, value in pairs(Cobalt) do
        core[key] = value
    end

    core.Shared = qbShared.shared()
    core.Config = qbShared.config({
        DefaultSpawn = serverConfig.spawn,
        UpdateInterval = GetConvarInt('player_save_interval', 60) / 60,
        Server = {
            Closed = serverConfig.closed,
            ClosedReason = serverConfig.closedReason,
            Whitelist = serverConfig.whitelist,
            WhitelistPermission = serverConfig.whitelistPermission,
            CheckDuplicateLicense = serverConfig.checkDuplicateLicense,
            Discord = serverConfig.discord,
            Permissions = serverConfig.permissions,
        },
    })
    core.Players = qbPlayer.all()
    core.Player = qbPlayer.api()
    core.Functions = buildFunctions()
    core.Commands = buildCommands()
    core.UsableItems = useable.items

    return core
end

qbShared.export('GetCoreObject', qbShared.coreObjectExport(buildCore))
qbShared.exportShared()
qbShared.export('ExploitBan', function(playerId, origin)
    exports.cobalt_core:ExploitBan(playerId, origin)
end)

for name, fn in pairs(buildFunctions()) do
    qbShared.export(name, fn)
end
