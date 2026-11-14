local REACH <const> = 3.0
local CARRY_PROMPT_MS <const> = 15000

---@type { other: integer, carrier: boolean }?
local carry

---@return integer?
local function nearestPlayer()
    local playerId <const> = lib.getClosestPlayer(GetEntityCoords(cache.ped), REACH, false)

    return playerId and GetPlayerServerId(playerId) or nil
end

---@return boolean
local function nobodyNear()
    return nearestPlayer() == nil
end

---@param description string
---@param notifyType? string
local function notify(description, notifyType)
    Cobalt.Functions.Notify({ description = description, type = notifyType or 'info' })
end

---@param serverEvent string
local function toNearest(serverEvent)
    local target <const> = nearestPlayer()
    if not target then return notify(Lang:t('interact.nobody_near'), 'error') end

    TriggerServerEvent(serverEvent, target)
end

local function copyCitizenId()
    local citizenid <const> = Cobalt.PlayerData.citizenid
    if not citizenid then return end

    lib.setClipboard(citizenid)
    notify(Lang:t('interact.id_copied', { citizenid = citizenid }), 'success')
end

local function giveCash()
    local target <const> = nearestPlayer()
    if not target then return notify(Lang:t('interact.nobody_near'), 'error') end

    local values <const> = Cobalt.Functions.InputDialog(Lang:t('radial.give_cash'), {
        { type = 'number', label = Lang:t('radial.amount'), prefix = '$', min = 1, required = true },
    }, { icon = 'money', submitText = Lang:t('radial.give_cash') })

    local amount <const> = values and math.tointeger(values[1])
    if not amount or amount < 1 then return end

    TriggerServerEvent('cobalt_core:server:giveCash', target, amount)
end

local function reloadSkin()
    TriggerEvent('illenium-appearance:client:reloadSkin')
end

Cobalt.Functions.RegisterRadial({
    id = 'cobalt:citizen',
    label = Lang:t('radial.citizen'),
    items = {
        { id = 'cobalt:copyid', label = Lang:t('radial.copy_id'), icon = 'copy', onSelect = copyCitizenId },
        {
            id = 'cobalt:showid',
            label = Lang:t('radial.show_id'),
            icon = 'identification-card',
            disabled = nobodyNear,
            onSelect = function() toNearest('cobalt_core:server:showId') end,
        },
        {
            id = 'cobalt:sharenumber',
            label = Lang:t('radial.share_number'),
            icon = 'device-mobile',
            disabled = nobodyNear,
            onSelect = function() toNearest('cobalt_core:server:shareNumber') end,
        },
        { id = 'cobalt:givecash', label = Lang:t('radial.give_cash'), icon = 'money', disabled = nobodyNear, onSelect = giveCash },
        {
            id = 'cobalt:carry',
            label = Lang:t('radial.carry'),
            icon = 'hand-grabbing',
            canInteract = function() return carry == nil end,
            disabled = nobodyNear,
            onSelect = function() toNearest('cobalt_core:server:carryRequest') end,
        },
        {
            id = 'cobalt:carrystop',
            label = Lang:t('radial.put_down'),
            icon = 'arrow-line-down',
            canInteract = function() return carry ~= nil end,
            onSelect = function() TriggerServerEvent('cobalt_core:server:carryStop') end,
        },
    },
})

Cobalt.Functions.AddRadialItem({
    { id = 'cobalt:citizen', label = Lang:t('radial.citizen'), icon = 'user', menu = 'cobalt:citizen' },
    { id = 'cobalt:reloadskin', label = Lang:t('radial.reload_skin'), icon = 't-shirt', onSelect = reloadSkin },
})

RegisterNetEvent('cobalt_core:client:carryPrompt', function(name)
    if type(name) ~= 'string' then return end

    local choice <const> = Cobalt.Functions.AlertDialog({
        header = Lang:t('interact.carry_header'),
        content = Lang:t('interact.carry_prompt', { name = name }),
        icon = 'hand-grabbing',
        labels = { confirm = Lang:t('interact.carry_accept'), cancel = Lang:t('interact.carry_decline') },
    }, CARRY_PROMPT_MS)

    TriggerServerEvent('cobalt_core:server:carryReply', choice == 'confirm')
end)

---@param other integer
---@param isCarrier boolean
local function playCarry(other, isCarrier)
    local dict <const> = isCarrier and 'missfinale_c2mcs_1' or 'nm'
    local clip <const> = isCarrier and 'fin_c2_mcs_1_camman' or 'firemans_carry'
    local flag <const> = isCarrier and 49 or 33

    lib.requestAnimDict(dict)

    if not isCarrier then
        local carrierPed <const> = GetPlayerPed(GetPlayerFromServerId(other))

        AttachEntityToEntity(cache.ped, carrierPed, 0, 0.27, 0.15, 0.63, 0.5, 0.5, 180.0, false, false, false, false, 2, false)
    end

    while carry and carry.other == other do
        if not IsEntityPlayingAnim(cache.ped, dict, clip, 3) then
            TaskPlayAnim(cache.ped, dict, clip, 8.0, -8.0, -1, flag, 0, false, false, false)
        end

        Wait(250)
    end

    RemoveAnimDict(dict)
end

RegisterNetEvent('cobalt_core:client:carryStart', function(other, isCarrier)
    other = math.tointeger(other)
    if not other or carry then return end

    carry = { other = other, carrier = isCarrier == true }
    CreateThread(function() playCarry(other, isCarrier == true) end)
end)

local function stopCarry()
    if not carry then return end

    local wasCarried <const> = not carry.carrier
    carry = nil

    if wasCarried then DetachEntity(cache.ped, true, false) end

    ClearPedTasks(cache.ped)
end

RegisterNetEvent('cobalt_core:client:carryStop', stopCarry)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then stopCarry() end
end)
