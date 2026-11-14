local settings <const> = require 'config.shared'.stateIdPreview

local STATE_KEY <const> = 'cobalt:stateid'
local CLIPBOARD_MODEL <const> = `p_amb_clipboard_01`
local CLIPBOARD_BONE <const> = 36029
local CLIPBOARD_OFFSET <const> = vec3(0.16, 0.08, 0.1)
local CLIPBOARD_ROTATION <const> = vec3(-130.0, -50.0, 0.0)
local ANIM_DICT <const> = 'missfam4'
local ANIM_CLIP <const> = 'base'
local ANIM_FLAGS <const> = 49
local ANIM_BLEND <const> = 3.0
local ANIM_START_MS <const> = 1000
local HEAD_BONE <const> = 31086
local TAG_HEIGHT <const> = 0.4
local SIGHT_FLAGS <const> = 17
local REFRESH_MS <const> = 250

---@class StateIdTag
---@field ped integer
---@field label string

---@class Clipboard
---@field entity integer
---@field ped integer
---@field since integer game timer when it came out

---@type Clipboard?
local clipboard

---@type StateIdTag[]
local tags <const> = {}

local previewing = false

---@return boolean?
local function isDown()
    local metadata <const> = Cobalt.PlayerData.metadata

    return IsEntityDead(cache.ped) or metadata?.isdead or metadata?.inlaststand
end

---@param ped integer
---@return boolean
local function canHoldClipboard(ped)
    return not IsPedInAnyVehicle(ped, true) and not IsPedSwimming(ped) and not Cobalt.PlayerData.metadata?.ishandcuffed
end

local function takeOutClipboard()
    local ped <const> = cache.ped
    local coords <const> = GetEntityCoords(ped)
    local entity <const> = CreateObject(CLIPBOARD_MODEL, coords.x, coords.y, coords.z, false, false, false)

    AttachEntityToEntity(
        entity,
        ped,
        GetPedBoneIndex(ped, CLIPBOARD_BONE),
        CLIPBOARD_OFFSET.x,
        CLIPBOARD_OFFSET.y,
        CLIPBOARD_OFFSET.z,
        CLIPBOARD_ROTATION.x,
        CLIPBOARD_ROTATION.y,
        CLIPBOARD_ROTATION.z,
        true,
        true,
        false,
        true,
        1,
        true
    )
    TaskPlayAnim(ped, ANIM_DICT, ANIM_CLIP, ANIM_BLEND, ANIM_BLEND, -1, ANIM_FLAGS, 0.0, false, false, false)

    clipboard = { entity = entity, ped = ped, since = GetGameTimer() }
end

local function putAwayClipboard()
    if not clipboard then return end

    if DoesEntityExist(clipboard.entity) then DeleteEntity(clipboard.entity) end

    StopAnimTask(clipboard.ped, ANIM_DICT, ANIM_CLIP, ANIM_BLEND)
    clipboard = nil
end

---@param held Clipboard
---@return boolean
local function wasInterrupted(held)
    if GetGameTimer() - held.since < ANIM_START_MS then return false end

    return held.ped ~= cache.ped or not IsEntityPlayingAnim(held.ped, ANIM_DICT, ANIM_CLIP, 3)
end

---@param ped integer
---@param other integer
---@return boolean
local function canSee(ped, other)
    if other == ped then return true end

    return IsEntityVisible(other) and HasEntityClearLosToEntity(ped, other, SIGHT_FLAGS)
end

local function refreshTags()
    local ped <const> = cache.ped

    table.wipe(tags)

    for _, nearby in ipairs(lib.getNearbyPlayers(GetEntityCoords(ped), settings.radius, true)) do
        local stateId <const> = Player(GetPlayerServerId(nearby.id)).state[STATE_KEY]

        if stateId and canSee(ped, nearby.ped) then
            tags[#tags + 1] = { ped = nearby.ped, label = tostring(stateId) }
        end
    end
end

local function drawTags()
    for i = 1, #tags do
        local tag <const> = tags[i]

        if DoesEntityExist(tag.ped) then
            local head <const> = GetPedBoneCoords(tag.ped, HEAD_BONE, 0.0, 0.0, 0.0)

            Cobalt.Functions.DrawText3D(head.x, head.y, head.z + TAG_HEIGHT, tag.label)
        end
    end
end

local function endPreview()
    putAwayClipboard()
    table.wipe(tags)
    RemoveAnimDict(ANIM_DICT)
    SetModelAsNoLongerNeeded(CLIPBOARD_MODEL)

    previewing = false
end

---@param keybind CKeybind
local function preview(keybind)
    lib.requestAnimDict(ANIM_DICT)
    lib.requestModel(CLIPBOARD_MODEL)

    local holdable = false
    local refreshAt = 0

    while keybind.isPressed and not isDown() and not IsPauseMenuActive() do
        local now <const> = GetGameTimer()

        if now >= refreshAt then
            refreshTags()
            refreshAt = now + REFRESH_MS
        end

        local canHold <const> = canHoldClipboard(cache.ped)

        if canHold ~= holdable then
            holdable = canHold

            if holdable then
                takeOutClipboard()
            else
                putAwayClipboard()
            end
        elseif clipboard and wasInterrupted(clipboard) then
            putAwayClipboard()
        end

        drawTags()
        Wait(0)
    end

    endPreview()
end

lib.addKeybind({
    name = 'stateids',
    description = locale('stateid.keybind'),
    defaultKey = settings.key,
    onPressed = function(self)
        if previewing or not LocalPlayer.state.LoggedIn or isDown() then return end

        previewing = true

        CreateThread(function() preview(self) end)
    end,
})

AddEventHandler('onResourceStop', function(resource)
    if resource == cache.resource and previewing then endPreview() end
end)
