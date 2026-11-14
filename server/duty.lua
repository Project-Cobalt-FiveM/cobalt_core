local TOGGLE_COOLDOWN_MS <const> = 2500

---@type table<integer, integer>
local lastToggle <const> = {}

---Flips a loaded character's duty through cobalt_management, at most once per cooldown. Ignores characters with no job.
---@param source integer
---@return boolean? onDuty nil when the toggle was ignored
local function toggle(source)
    local job <const> = Cobalt.Functions.GetPlayer(source)?.PlayerData.job

    if not job or job.name == 'unemployed' then return end
    if GetResourceState('cobalt_management') ~= 'started' then return end

    local now <const> = GetGameTimer()
    local last <const> = lastToggle[source]

    if last and now - last < TOGGLE_COOLDOWN_MS then return end

    lastToggle[source] = now

    local onDuty <const> = not exports.cobalt_management:GetDuty(source)

    if not exports.cobalt_management:SetDuty(source, onDuty) then return end

    Cobalt.Functions.Notify(source, { description = Lang:t(onDuty and 'info.on_duty' or 'info.off_duty') })

    return onDuty
end

AddEventHandler('playerDropped', function()
    lastToggle[source] = nil
end)

return toggle
