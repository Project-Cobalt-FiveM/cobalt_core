local config <const> = require 'server.fivemesh.config'
local settings <const> = require 'config.server'.logging
local http <const> = require 'server.fivemesh.http'

---@class FiveMeshEvent
---@field event_id string
---@field level 'debug'|'info'|'warn'|'error'|'fatal'
---@field event_type string
---@field message string
---@field occurred_at string
---@field resource? string
---@field environment string
---@field data? table
---@field player_id? string
---@field player_identifiers? table<string, string>
---@field target_player_id? string
---@field target_player_identifiers? table<string, string>

---@class QueuedEvent
---@field event FiveMeshEvent
---@field bytes integer

local LEVELS <const> = {
    debug = 'debug',
    info = 'info',
    warn = 'warn',
    error = 'error',
    fatal = 'fatal',
    security = 'warn',
}

local LEVEL_RANK <const> = { debug = 1, info = 2, warn = 3, error = 4, fatal = 5 }

local logs <const> = {}

---@type QueuedEvent[]
local queue <const> = {}
local sequence = 0
---@type string?
local endpoint
local lookupRetryAt = 0

local LOOKUP_RETRY_MS <const> = 60000

---@param prefix string
---@return string
local function nextId(prefix)
    sequence += 1

    return ('%s-%x-%x-%04x'):format(prefix, os.time(), sequence, math.random(0, 0xffff))
end

---@param category string
---@param level LogLevel
---@return string
local function eventType(category, level)
    local name = category:lower():gsub('[^%w%.:_%-]', '_')

    if name == '' then
        name = 'log'
    end

    if level == 'security' then
        name = 'security.' .. name
    end

    return name:sub(1, 96)
end

---@param data any
---@return table?
local function asObject(data)
    if data == nil then return end

    if type(data) ~= 'table' then
        return { value = data }
    end

    if next(data) == nil then return end

    return data[1] == nil and data or { items = data }
end

---@param source integer
---@return table<string, string>?
local function identifiersOf(source)
    local identifiers <const> = {}

    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        local kind, value = identifier:match('^(%w+):(.+)$')

        if kind and kind ~= 'ip' then
            identifiers[kind] = value
        end
    end

    identifiers.citizenid = Cobalt.Players[source]?.PlayerData.citizenid

    return next(identifiers) and identifiers or nil
end

---@param event FiveMeshEvent
---@return integer
local function encodedSize(event)
    local size <const> = #json.encode(event)

    if size <= config.logs.maxEventBytes then
        return size
    end

    event.data = { truncated = true }
    event.message = event.message:sub(1, 1024)

    return #json.encode(event)
end

---@return FiveMeshEvent[]
local function takeBatch()
    local events <const> = {}
    local bytes = 0

    while queue[1] and #events < config.logs.batchSize and bytes + queue[1].bytes <= config.logs.maxBatchBytes do
        local queued <const> = table.remove(queue, 1)
        events[#events + 1] = queued.event
        bytes += queued.bytes
    end

    return events
end

---@param events FiveMeshEvent[]
---@return table
local function batchOf(events)
    return { batch_id = nextId('batch'), events = events }
end

---@return string?
local function joinCode()
    return GetConvar('web_baseUrl', ''):match('%-(%w+)%.users%.cfx%.re$')
end

---@return string
local function resolveEndpoint()
    if endpoint then return endpoint end

    local boundUrl <const> = config.logsUrl .. '/logs'
    local now <const> = GetGameTimer()

    if now < lookupRetryAt then return boundUrl end

    lookupRetryAt = now + LOOKUP_RETRY_MS

    local response <const> = http.request('GET', config.apiUrl .. '/whoami')

    if not http.ok(response) then return boundUrl end

    local identity <const> = response.data?.data or response.data

    if identity?.server then
        endpoint = boundUrl

        return endpoint
    end

    local code <const> = joinCode()

    if not code then return boundUrl end

    endpoint = ('%s/servers/%s/logs'):format(config.logsUrl, code)

    return endpoint
end

---@param events FiveMeshEvent[]
local function send(events)
    local response <const> = http.request('POST', resolveEndpoint(), batchOf(events))

    if http.ok(response) then return end

    lib.print.warn(('FiveMesh dropped %d log events: %s'):format(#events, http.errorOf(response)))
end

---@param category string
---@return boolean off the category, or a category it sits under, is in logging.disabled
local function categoryDisabled(category)
    for _, name in ipairs(settings.disabled) do
        if category == name then return true end

        local boundary <const> = category:sub(#name + 1, #name + 1)

        if category:sub(1, #name) == name and (boundary == '.' or boundary == ':') then return true end
    end

    return false
end

---@param level LogLevel
---@return boolean sent the level meets logging.minLevel; security logs always do
local function levelSent(level)
    return level == 'security' or LEVEL_RANK[level] >= (LEVEL_RANK[settings.minLevel] or LEVEL_RANK.info)
end

---@class LogEntry
---@field level? LogLevel
---@field category string
---@field message string
---@field data? any
---@field resource? string
---@field source? integer
---@field target? integer

---@param entry LogEntry
---@return boolean queued
function logs.push(entry)
    if not settings.enabled then return false end

    if type(entry.category) ~= 'string' then return false end

    if type(entry.message) ~= 'string' or entry.message == '' then return false end

    local level <const> = LEVELS[entry.level] and entry.level or 'info'

    if not levelSent(level) or categoryDisabled(entry.category) then return false end

    if settings.console then lib.print.info(('%s: %s'):format(entry.category, entry.message)) end

    if config.apiKey == '' then return false end

    ---@type FiveMeshEvent
    local event <const> = {
        event_id = nextId('evt'),
        level = LEVELS[level],
        event_type = eventType(entry.category, level),
        message = entry.message:sub(1, 2048),
        occurred_at = os.date('!%Y-%m-%dT%H:%M:%SZ') --[[@as string]],
        resource = entry.resource,
        environment = settings.environment,
        data = asObject(entry.data),
    }

    if entry.source and DoesPlayerExist(entry.source) then
        event.player_id = tostring(entry.source)
        event.player_identifiers = settings.playerIdentifiers and identifiersOf(entry.source) or nil
    end

    if entry.target and DoesPlayerExist(entry.target) then
        event.target_player_id = tostring(entry.target)
        event.target_player_identifiers = settings.playerIdentifiers and identifiersOf(entry.target) or nil
    end

    if #queue >= config.logs.maxQueued then
        table.remove(queue, 1)
    end

    queue[#queue + 1] = { event = event, bytes = encodedSize(event) }

    if #queue >= config.logs.batchSize then
        logs.flush()
    end

    return true
end

function logs.flush()
    while queue[1] do
        local events <const> = takeBatch()

        CreateThread(function()
            send(events)
        end)
    end
end

function logs.flushNow()
    while queue[1] do
        http.fire('POST', endpoint or config.logsUrl .. '/logs', batchOf(takeBatch()))
    end
end

if config.apiKey ~= '' then
    SetInterval(logs.flush, config.logs.flushInterval)

    AddEventHandler('onResourceStop', function(resource)
        if resource == cache.resource then
            logs.flushNow()
        end
    end)
end

return logs
