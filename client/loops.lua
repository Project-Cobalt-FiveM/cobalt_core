local sharedConfig <const> = require 'config.shared'

CreateThread(function()
    while true do
        local metadata <const> = Cobalt.PlayerData.metadata

        if LocalPlayer.state.LoggedIn and metadata then
            local ped <const> = cache.ped
            if sharedConfig.status.hungerRate == 0 and sharedConfig.status.thirstRate == 0 then
                local maxHp <const> = GetEntityMaxHealth(ped)
                if GetEntityHealth(ped) < maxHp and not (metadata.isdead or metadata.inlaststand) then
                    SetEntityHealth(ped, maxHp)
                end
            elseif ((metadata.hunger or 100) <= 0 or (metadata.thirst or 100) <= 0) and not (metadata.isdead or metadata.inlaststand) then
                local currentHealth <const> = GetEntityHealth(ped)
                local decreaseThreshold <const> = math.random(5, 10)
                SetEntityHealth(ped, currentHealth - decreaseThreshold)
            end
        end
        Wait(sharedConfig.status.starvingDamageSeconds * 1000)
    end
end)
