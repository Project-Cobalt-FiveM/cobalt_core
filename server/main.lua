Cobalt = {}
Cobalt.Shared = CobaltShared

SetConvarReplicated('sv_stateBagStrictMode', 'true')

---@type table<'Jobs' | 'Gangs', string>
local SHARED_STATE_KEYS <const> = { Jobs = 'cobalt:jobs', Gangs = 'cobalt:gangs' }

---@type table<'Jobs' | 'Gangs', true>
local replicating <const> = {}

---@param name 'Jobs' | 'Gangs'
local function replicateNextTick(name)
    if replicating[name] then return end

    replicating[name] = true

    SetTimeout(0, function()
        replicating[name] = nil
        GlobalState:set(SHARED_STATE_KEYS[name], Cobalt.Shared[name], true)
    end)
end

function PublishJobs()
    replicateNextTick('Jobs')
    TriggerEvent('cobalt_core:server:jobsChanged')
end

function PublishGangs()
    replicateNextTick('Gangs')
    TriggerEvent('cobalt_core:server:gangsChanged')
end

GlobalState:set('pvp', require('config.shared').pvp, true)

CreateThread(function()
    PublishJobs()
    PublishGangs()
end)

local function GetCoreObject(filters)
    if not filters then return Cobalt end
    local results <const> = {}
    for i = 1, #filters do
        local key <const> = filters[i]
        if Cobalt[key] then
            results[key] = Cobalt[key]
        end
    end
    return results
end
exports('GetCoreObject', GetCoreObject)
