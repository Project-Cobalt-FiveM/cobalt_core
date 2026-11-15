local status <const> = require 'config.shared'.status

if status.hungerRate == 0 and status.thirstRate == 0 then return end

---@param metadata table
---@return boolean
local function isStarving(metadata)
    if metadata.isdead or metadata.inlaststand then return false end

    return (metadata.hunger or 100) <= 0 or (metadata.thirst or 100) <= 0
end

CreateThread(function()
    while true do
        local metadata <const> = Cobalt.PlayerData.metadata

        if LocalPlayer.state.LoggedIn and metadata and isStarving(metadata) then
            SetEntityHealth(cache.ped, GetEntityHealth(cache.ped) - math.random(5, 10))
        end

        Wait(status.starvingDamageSeconds * 1000)
    end
end)
