local limit <const> = require 'config.server'.callbackLimit

---@class CallbackWindow
---@field second integer
---@field calls integer
---@field floodedSeconds integer

---@type table<integer, CallbackWindow>
local windows <const> = {}

---@param source integer
---@param message string
---@param reasonKey string
---@param data table
local function drop(source, message, reasonKey, data)
    windows[source] = nil
    exports.cobalt_core:LogPlayer(source, 'core.callback_abuse', message, data, 'security')
    DropPlayer(source, Lang:t(reasonKey))
end

---@param source integer
---@return CallbackWindow
local function windowOf(source)
    local second <const> = GetGameTimer() // 1000
    local window = windows[source]

    if not window then
        window = { second = second, calls = 0, floodedSeconds = 0 }
        windows[source] = window
    elseif window.second ~= second then
        local flooded <const> = window.calls > limit.perSecond and window.second == second - 1

        window.floodedSeconds = flooded and window.floodedSeconds + 1 or 0
        window.second = second
        window.calls = 0
    end

    return window
end

---Counts one server callback call and says whether it may run. Drops the player for an unknown name or a sustained flood.
---@param source integer
---@param name string
---@param known boolean whether a callback with this name is registered
---@return boolean allowed
local function allow(source, name, known)
    if not known then
        drop(source, 'Kicked: called a server callback that does not exist', 'kick.unknown_callback', { callback = name })
        return false
    end

    local window <const> = windowOf(source)

    window.calls += 1

    if window.calls <= limit.perSecond then return true end

    if window.floodedSeconds + 1 >= limit.floodSeconds then
        drop(source, 'Kicked: too many server callback calls', 'kick.callback_flood', {
            callback = name,
            perSecond = window.calls,
            seconds = limit.floodSeconds,
        })
    end

    return false
end

AddEventHandler('playerDropped', function()
    windows[source] = nil
end)

return allow
