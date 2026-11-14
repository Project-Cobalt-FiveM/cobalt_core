local INTERFACES <const> = 'cobalt_interfaces'
local settings <const> = require 'config.shared'.idCard
local HOLDER_CLOSE_MS <const> = settings.autoCloseSeconds * 1000
local VIEWER_CLOSE_MS <const> = settings.viewerCloseSeconds * 1000
local HEADSHOT_TIMEOUT_MS <const> = 1500
local CLOSE_CONTROLS <const> = { 194, 322 }
local PAUSE_CONTROL <const> = 200

---@type integer?
local headshot
local lastTicket = 0
---@type integer?
local activeTicket

local function releaseHeadshot()
    if not headshot then return end

    UnregisterPedheadshot(headshot)
    headshot = nil
end

---@param holder integer
---@return integer?
local function holderPed(holder)
    if holder == cache.serverId then return cache.ped end

    local player <const> = GetPlayerFromServerId(holder)

    if player == -1 then return end

    return GetPlayerPed(player)
end

---@param holder integer
---@return string?
local function headshotUrl(holder)
    local ped <const> = holderPed(holder)

    if not ped or ped == 0 then return end

    releaseHeadshot()
    headshot = RegisterPedheadshotTransparent(ped)

    local deadline <const> = GetGameTimer() + HEADSHOT_TIMEOUT_MS

    while not IsPedheadshotReady(headshot) or not IsPedheadshotValid(headshot) do
        if GetGameTimer() > deadline then
            releaseHeadshot()
            return
        end

        Wait(0)
    end

    local txd <const> = GetPedheadshotTxdString(headshot)

    return ('https://nui-img/%s/%s'):format(txd, txd)
end

local function HideCard()
    if not activeTicket then return end

    activeTicket = nil
    releaseHeadshot()

    TriggerEvent('cobalt_interfaces:client:hideCard')
end

---@param ticket integer
---@param openMs integer
local function watchClose(ticket, openMs)
    local closesAt <const> = GetGameTimer() + openMs

    while activeTicket == ticket do
        DisableControlAction(0, PAUSE_CONTROL, true)

        if GetGameTimer() >= closesAt then return HideCard() end

        for i = 1, #CLOSE_CONTROLS do
            local control <const> = CLOSE_CONTROLS[i]

            if IsDisabledControlJustPressed(0, control) or IsControlJustPressed(0, control) then return HideCard() end
        end

        Wait(0)
    end
end

---@param card CardData
local function ShowCard(card)
    if GetResourceState(INTERFACES) ~= 'started' then return end

    lastTicket += 1

    local ticket <const> = lastTicket

    activeTicket = ticket

    local photo <const> = headshotUrl(card.holder)

    if activeTicket ~= ticket then return end

    TriggerEvent('cobalt_interfaces:client:showCard', card, photo)

    local openMs <const> = card.holder == cache.serverId and HOLDER_CLOSE_MS or VIEWER_CLOSE_MS

    CreateThread(function() watchClose(ticket, openMs) end)
end

RegisterNetEvent('cobalt_core:client:showCard', ShowCard)

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource then releaseHeadshot() end
end)

