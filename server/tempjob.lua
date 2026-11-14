local NAME_KEY <const> = 'cobalt:tempjob'
local LABEL_KEY <const> = 'cobalt:tempjob:label'

---@type table<integer, TempJob>
local tempJobs <const> = {}

---@param src integer
---@param job TempJob?
local function apply(src, job)
    local previous <const> = tempJobs[src]

    tempJobs[src] = job

    local state <const> = Player(src).state

    state:set(NAME_KEY, job?.name, true)
    state:set(LABEL_KEY, job?.label, true)

    TriggerEvent('cobalt_core:server:tempJobChanged', src, job, previous)
end

---@param src integer
---@param name string
---@param data? { label?: string } | table
---@return boolean
local function SetTempJob(src, name, data)
    src = tonumber(src) --[[@as integer]]

    if not src or not Cobalt.Players[src] then return false end
    if type(name) ~= 'string' or name == '' then return false end

    apply(src, {
        name = name,
        label = type(data?.label) == 'string' and data.label or name,
        data = data,
        resource = GetInvokingResource() or cache.resource,
    })

    return true
end

---@param src integer
---@return boolean
local function ClearTempJob(src)
    src = tonumber(src) --[[@as integer]]

    if not src or not tempJobs[src] then return false end

    apply(src, nil)

    return true
end

---@param src integer
---@return TempJob?
local function GetTempJob(src)
    return tempJobs[tonumber(src)]
end

---@param src integer
local function forget(src)
    if tempJobs[src] then apply(src, nil) end
end

AddEventHandler('cobalt_core:Server:OnPlayerUnload', forget)

AddEventHandler('playerDropped', function()
    local src <const> = source
    local previous <const> = tempJobs[src]

    if not previous then return end

    tempJobs[src] = nil

    TriggerEvent('cobalt_core:server:tempJobChanged', src, nil, previous)
end)

AddEventHandler('onResourceStop', function(resource)
    for src, job in pairs(tempJobs) do
        if job.resource == resource then apply(src, nil) end
    end
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= cache.resource then return end

    for _, id in ipairs(GetPlayers()) do
        local state <const> = Player(id).state

        state:set(NAME_KEY, nil, true)
        state:set(LABEL_KEY, nil, true)
    end
end)

Cobalt.Functions.SetTempJob = SetTempJob
Cobalt.Functions.ClearTempJob = ClearTempJob
Cobalt.Functions.GetTempJob = GetTempJob
