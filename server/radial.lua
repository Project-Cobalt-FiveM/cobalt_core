local REACH <const> = 3.0
local CARRY_PROMPT_MS <const> = 30000
local COOLDOWN_MS <const> = 1000
local MAX_CASH_GIVE <const> = 1000000

---@type table<integer, integer>
local lastAction <const> = {}

---@type table<integer, { from: integer, expires: integer }>
local carryRequests <const> = {}

---@type table<integer, integer>
local carrying <const> = {}

---@type table<integer, integer>
local carriedBy <const> = {}

---@param source integer
---@return boolean
local function throttled(source)
    local now <const> = GetGameTimer()

    if lastAction[source] and now - lastAction[source] < COOLDOWN_MS then return true end

    lastAction[source] = now
    return false
end

---@param source integer
---@return boolean
local function inCarry(source)
    return carrying[source] ~= nil or carriedBy[source] ~= nil
end

---@param a integer
---@param b integer
---@return boolean
local function withinReach(a, b)
    local pedA <const> = GetPlayerPed(a)
    local pedB <const> = GetPlayerPed(b)

    if pedA == 0 or pedB == 0 then return false end
    if GetPlayerRoutingBucket(a) ~= GetPlayerRoutingBucket(b) then return false end

    return #(GetEntityCoords(pedA) - GetEntityCoords(pedB)) <= REACH
end

---@param source integer
---@param target unknown
---@return table?, table?
local function pair(source, target)
    target = math.tointeger(target)
    if not target or target == source then return end

    local player <const> = Cobalt.Functions.GetPlayer(source)
    local other <const> = Cobalt.Functions.GetPlayer(target)

    if not player or not other then return end
    if not withinReach(source, target) then return end

    return player, other
end

---@param source integer
---@param description string
---@param notifyType? string
local function notify(source, description, notifyType)
    Cobalt.Functions.Notify(source, { description = description, type = notifyType or 'info' })
end

RegisterNetEvent('cobalt_core:server:giveCash', function(target, amount)
    local source <const> = source --[[@as integer]]
    if throttled(source) then return end

    amount = math.tointeger(amount)
    if not amount or amount < 1 or amount > MAX_CASH_GIVE then return end

    local player, other = pair(source, target)
    if not player or not other then return notify(source, Lang:t('interact.nobody_near'), 'error') end

    if player:GetMoney('cash') < amount then
        return notify(source, Lang:t('interact.not_enough_cash'), 'error')
    end

    if not Cobalt.Player.TransferCash(player, other, amount, 'give cash') then
        return notify(source, Lang:t('interact.cash_failed'), 'error')
    end

    notify(source, Lang:t('interact.cash_given', { amount = amount, name = other:GetName() }), 'success')
    notify(other.PlayerData.source, Lang:t('interact.cash_received', { name = player:GetName(), amount = amount }), 'success')
end)

RegisterNetEvent('cobalt_core:server:shareNumber', function(target)
    local source <const> = source --[[@as integer]]
    if throttled(source) then return end

    local player, other = pair(source, target)
    if not player or not other then return notify(source, Lang:t('interact.nobody_near'), 'error') end
    if GetResourceState('npwd') ~= 'started' then return notify(source, Lang:t('interact.phones_offline'), 'error') end

    local number <const> = exports.npwd:getPhoneNumber(source)
    if not number then return notify(source, Lang:t('interact.no_number'), 'error') end

    TriggerClientEvent('npwd:contacts:receiveContact', other.PlayerData.source, { name = player:GetName(), number = number })
    notify(source, Lang:t('interact.number_shared', { name = other:GetName() }), 'success')
    notify(other.PlayerData.source, Lang:t('interact.number_received', { name = player:GetName() }))
end)

RegisterNetEvent('cobalt_core:server:showId', function(target)
    local source <const> = source --[[@as integer]]
    if throttled(source) then return end

    local player, other = pair(source, target)
    if not player or not other then return notify(source, Lang:t('interact.nobody_near'), 'error') end

    local charinfo <const> = player.PlayerData.charinfo or {}

    Cobalt.Functions.Notify(other.PlayerData.source, {
        title = player:GetName(),
        description = Lang:t('interact.id_details', {
            birthdate = charinfo.birthdate or Lang:t('interact.unknown'),
            nationality = charinfo.nationality or Lang:t('interact.unknown'),
            citizenid = player.PlayerData.citizenid,
        }),
        icon = 'identification-card',
        duration = 8000,
    })
    notify(source, Lang:t('interact.id_shown', { name = other:GetName() }), 'success')
end)

RegisterNetEvent('cobalt_core:server:carryRequest', function(target)
    local source <const> = source --[[@as integer]]
    if throttled(source) then return end
    if inCarry(source) then return end

    local player, other = pair(source, target)
    if not player or not other then return notify(source, Lang:t('interact.nobody_near'), 'error') end

    local targetSource <const> = other.PlayerData.source
    if inCarry(targetSource) then return end

    carryRequests[targetSource] = { from = source, expires = GetGameTimer() + CARRY_PROMPT_MS }
    TriggerClientEvent('cobalt_core:client:carryPrompt', targetSource, player:GetName())
    notify(source, Lang:t('interact.carry_asked', { name = other:GetName() }))
end)

RegisterNetEvent('cobalt_core:server:carryReply', function(accepted)
    local source <const> = source --[[@as integer]]
    local request <const> = carryRequests[source]
    carryRequests[source] = nil

    if not request or GetGameTimer() > request.expires then return end

    local carrier <const> = request.from

    if accepted ~= true then return notify(carrier, Lang:t('interact.carry_declined'), 'error') end
    if inCarry(carrier) or inCarry(source) then return notify(carrier, Lang:t('interact.carry_unavailable'), 'error') end
    if not pair(carrier, source) then return notify(carrier, Lang:t('interact.carry_too_far'), 'error') end

    carrying[carrier] = source
    carriedBy[source] = carrier
    TriggerClientEvent('cobalt_core:client:carryStart', carrier, source, true)
    TriggerClientEvent('cobalt_core:client:carryStart', source, carrier, false)
end)

---@param carrier integer
local function stopCarry(carrier)
    local carried <const> = carrying[carrier]
    if not carried then return end

    carrying[carrier] = nil
    carriedBy[carried] = nil
    TriggerClientEvent('cobalt_core:client:carryStop', carrier)
    TriggerClientEvent('cobalt_core:client:carryStop', carried)
end

---@param source integer
local function endCarryOf(source)
    local carrier <const> = carrying[source] and source or carriedBy[source]

    if carrier then stopCarry(carrier) end
end

RegisterNetEvent('cobalt_core:server:carryStop', function()
    endCarryOf(source --[[@as integer]])
end)

AddEventHandler('cobalt_core:Server:OnPlayerUnload', function(source)
    carryRequests[source] = nil
    endCarryOf(source)
end)

AddStateBagChangeHandler('isDead', nil, function(bagName, _, dead)
    if dead ~= true then return end

    local source <const> = GetPlayerFromStateBagName(bagName)

    if source ~= 0 then endCarryOf(source) end
end)

AddEventHandler('playerDropped', function()
    local source <const> = source --[[@as integer]]

    lastAction[source] = nil
    carryRequests[source] = nil
    endCarryOf(source)
end)
