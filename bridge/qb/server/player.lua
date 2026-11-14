local qbShared <const> = require 'bridge.qb.shared.main'

local qbPlayer <const> = {}

---@param source integer
---@return table<string, function> methods qb-core Player methods that cobalt_core leaves to cobalt_management and cobalt_inventory
local function delegatedMethods(source)
    return {
        SetJob = function(job, grade)
            return exports.cobalt_management:SetJob(source, job, tonumber(grade) or 0)
        end,
        SetGang = function(gang, grade)
            return exports.cobalt_management:SetGang(source, gang, tonumber(grade) or 0)
        end,
        SetJobDuty = function(onDuty)
            return exports.cobalt_management:SetDuty(source, onDuty)
        end,
        HasItem = function(items, amount)
            return qbShared.hasItems(function(name, count)
                return exports.cobalt_inventory:HasItem(source, name, count)
            end, items, amount)
        end,
        AddItem = function(item, amount, _, info, reason)
            return exports.cobalt_inventory:AddItem(source, item, amount, info, nil, reason)
        end,
        RemoveItem = function(item, amount, _, reason)
            return exports.cobalt_inventory:RemoveItem(source, item, amount, nil, reason)
        end,
        GetItemByName = function(item)
            return exports.cobalt_inventory:GetItemByName(source, item)
        end,
    }
end

---@param player table? cobalt_core player
---@return table? player a qb-core shaped snapshot
function qbPlayer.from(player)
    if not player then return end

    local functions <const> = {}

    for name, fn in pairs(player.Functions) do
        functions[name] = fn
    end

    functions.GetPlayerData = function()
        return qbShared.playerData(player.PlayerData)
    end
    functions.UpdateClient = player.Functions.UpdatePlayerData

    if not player.Offline then
        for name, fn in pairs(delegatedMethods(player.PlayerData.source)) do
            functions[name] = fn
        end
    end

    return {
        PlayerData = qbShared.playerData(player.PlayerData),
        Functions = functions,
        Offline = player.Offline,
    }
end

---@param get fun(...): table?
---@return fun(...): table?
function qbPlayer.wrap(get)
    return function(...)
        return qbPlayer.from(get(...))
    end
end

---@return table<integer, table>
function qbPlayer.all()
    local players <const> = {}

    for source, player in pairs(Cobalt.Players) do
        players[source] = qbPlayer.from(player)
    end

    return players
end

---@param generate fun(): string
---@param field 'charinfo.account' | 'charinfo.phone' | 'metadata.phonedata.SerialNumber'
---@return string
function qbPlayer.uniqueId(generate, field)
    local column, path = field:match('^(%w+)%.(.+)$')
    local query <const> = ("SELECT 1 FROM players WHERE JSON_VALUE(%s, '$.%s') = ? LIMIT 1"):format(column, path)
    local id = generate()

    while MySQL.scalar.await(query, { id }) do
        id = generate()
    end

    return id
end

---@return string
local function createSerialNumber()
    return qbPlayer.uniqueId(function()
        return tostring(math.random(11111111, 99999999))
    end, 'metadata.phonedata.SerialNumber')
end

local playerGetters <const> = { 'GetOfflinePlayer', 'GetPlayerByLicense', 'GetOfflinePlayerByLicense' }

---@return table api qb-core's QBCore.Player
function qbPlayer.api()
    local api <const> = {}

    for name, fn in pairs(Cobalt.Player) do
        api[name] = fn
    end

    for _, name in ipairs(playerGetters) do
        api[name] = qbPlayer.wrap(Cobalt.Player[name])
    end

    api.CreateSerialNumber = createSerialNumber

    return api
end

return qbPlayer
