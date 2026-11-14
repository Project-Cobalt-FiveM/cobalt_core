local RESOURCE <const> = 'cobalt_interfaces'
local interfaces <const> = exports[RESOURCE]

---@return boolean
local function ready()
    return LocalPlayer.state.interfacesReady == true
end

---@return string
local function caller()
    return GetInvokingResource() or cache.resource
end

local notifyTypes <const> = { primary = 'inform', info = 'inform', warn = 'warning' }

local function nonEmpty(value)
    return value ~= '' and value or nil
end

---Builds notify data from a table, or from QBCore's (text, type, length, icon).
---@param text string | table
---@param notifyType? string
---@param length? number
---@param icon? string
---@return table
local function toNotifyData(text, notifyType, length, icon)
    if type(text) ~= 'table' then
        return {
            description = text ~= nil and tostring(text) or nil,
            type = notifyTypes[notifyType] or notifyType,
            duration = length or 5000,
            icon = icon,
        }
    end

    local title <const> = nonEmpty(text.title) or nonEmpty(text.caption)
    local description <const> = nonEmpty(text.description) or nonEmpty(text.message) or nonEmpty(text.text)
    local dataType <const> = text.type or notifyType

    return {
        id = text.id,
        title = title,
        description = description,
        type = notifyTypes[dataType] or dataType,
        duration = text.duration or length or 5000,
        icon = text.icon or icon,
        iconColor = text.iconColor,
        iconAnimation = text.iconAnimation,
        position = text.position,
        style = text.style,
        alignIcon = text.alignIcon,
        sound = text.sound,
    }
end

---@param text string | table
---@param notifyType? string
---@param length? number
---@param icon? string
function Cobalt.Functions.Notify(text, notifyType, length, icon)
    if not ready() then return end

    interfaces:notify(toNotifyData(text, notifyType, length, icon))
end

---@return boolean
local function progressActive()
    return ready() and interfaces:progressActive() == true
end

local function cancelProgress()
    if progressActive() then interfaces:cancelProgress() end
end

---Accepts ox_lib's disable keys and QBCore's disableControls keys.
local function toDisable(controls)
    if not controls then return nil end

    return {
        move = controls.move or controls.disableMovement,
        sprint = controls.sprint,
        car = controls.car or controls.disableCarMovement,
        mouse = controls.mouse or controls.disableMouse,
        combat = controls.combat or controls.disableCombat,
    }
end

---Accepts ox_lib's anim, QBCore's { animDict, anim, flags } and QBCore's { task = scenario }.
local function toAnim(anim)
    if not anim then return nil end

    local scenario <const> = anim.scenario or anim.task

    if scenario then return { scenario = scenario, playEnter = anim.playEnter } end

    local dict <const> = anim.dict or anim.animDict
    local clip <const> = anim.clip or anim.anim

    if not dict or not clip then return nil end

    return {
        dict = dict,
        clip = clip,
        flag = anim.flag or anim.flags or 49,
        blendIn = anim.blendIn,
        blendOut = anim.blendOut,
        duration = anim.duration,
        playbackRate = anim.playbackRate,
        lockX = anim.lockX,
        lockY = anim.lockY,
        lockZ = anim.lockZ,
    }
end

---QBCore's props are { model, bone, coords, rotation }.
---@return table[]?
local function fromQbProps(...)
    local props <const> = {}

    for i = 1, select('#', ...) do
        local prop <const> = select(i, ...)

        if prop?.model then
            props[#props + 1] = { model = prop.model, bone = prop.bone, pos = prop.coords, rot = prop.rotation }
        end
    end

    return props[1] and props or nil
end

---Shows a bar, then runs `onFinish` or `onCancel`. Returns true when the bar filled.
---@param data table
---@return boolean
local function runProgress(data)
    if type(data.duration) ~= 'number' or data.duration <= 0 then return false end
    if not ready() then return false end

    if progressActive() then
        Cobalt.Functions.Notify(Lang:t('error.busy'), 'error', 2500)

        if data.onCancel then data.onCancel() end
        return false
    end

    local props <const> = {
        label = data.label,
        duration = data.duration,
        icon = data.icon,
        canCancel = data.canCancel ~= false,
        useWhileDead = data.useWhileDead,
        allowRagdoll = data.allowRagdoll,
        allowCuffed = data.allowCuffed,
        allowFalling = data.allowFalling,
        allowSwimming = data.allowSwimming,
        anim = toAnim(data.anim),
        prop = data.prop,
        disable = toDisable(data.disable),
    }

    local finished <const> = interfaces:progressBar(props)

    if finished then
        if data.onFinish then data.onFinish() end
    elseif data.onCancel then
        data.onCancel()
    end

    return finished == true
end

---QBCore's positional progress bar, run in a thread so the caller does not yield.
local function runQbProgress(
    _, label, duration, useWhileDead, canCancel, disableControls, animation, prop, propTwo, onFinish, onCancel
)
    CreateThread(function()
        runProgress({
            label = label,
            duration = duration,
            useWhileDead = useWhileDead,
            canCancel = canCancel,
            disable = disableControls,
            anim = animation,
            prop = fromQbProps(prop, propTwo),
            onFinish = onFinish,
            onCancel = onCancel,
        })
    end)
end

---`Progressbar(data)` yields and returns true when the bar fills.
---QBCore's `Progressbar(name, label, duration, ...)` returns at once and calls onFinish or onCancel.
---@param data table | string
---@return boolean?
function Cobalt.Functions.Progressbar(data, ...)
    if type(data) == 'table' then return runProgress(data) end

    runQbProgress(data, ...)
end

---@param text string
---@param options? { key?: string, position?: string }
function Cobalt.Functions.ShowTextUI(text, options)
    if ready() then interfaces:showTextUI(text, options, caller()) end
end

function Cobalt.Functions.HideTextUI()
    if ready() then interfaces:hideTextUI(caller()) end
end

---@return boolean, string?
function Cobalt.Functions.IsTextUIOpen()
    if not ready() then return false end

    return interfaces:isTextUIOpen()
end

---@param difficulty string | table | (string | table)[]
---@param inputs? string[]
---@return boolean?
function Cobalt.Functions.SkillCheck(difficulty, inputs)
    if not ready() then return end

    return interfaces:skillCheck(difficulty, inputs, caller())
end

---@type table<string, { menu: table, resource: string }>
local contexts <const> = {}

---@param context table One menu, or a list of menus
function Cobalt.Functions.RegisterContext(context)
    local resource <const> = caller()

    for _, menu in ipairs(context.id and { context } or context) do
        contexts[menu.id] = { menu = menu, resource = resource }
    end

    if ready() then interfaces:registerContext(context, resource) end
end

---@param id string
function Cobalt.Functions.ShowContext(id)
    if ready() then interfaces:showContext(id) end
end

---@param onExit? boolean Runs the menu's onExit
function Cobalt.Functions.HideContext(onExit)
    if ready() then interfaces:hideContext(onExit) end
end

---@param heading string
---@param rows (string | table)[]
---@param options? table
---@return any[]?
function Cobalt.Functions.InputDialog(heading, rows, options)
    if not ready() then return end

    return interfaces:inputDialog(heading, rows, options, caller())
end

---@param data table
---@param timeout? number
---@return 'confirm' | 'cancel' | nil
function Cobalt.Functions.AlertDialog(data, timeout)
    if not ready() then return end

    return interfaces:alertDialog(data, timeout, caller())
end

---@type table<string, { item: table, resource: string, order: integer }>
local radialItems <const> = {}

local radialOrder = 0

---@type table<string, { menu: table, resource: string }>
local radialMenus <const> = {}

---@param items table One item, or a list of items
function Cobalt.Functions.AddRadialItem(items)
    local resource <const> = caller()

    for _, item in ipairs(items.id and { items } or items) do
        radialOrder += 1
        radialItems[item.id] = { item = item, resource = resource, order = radialOrder }
    end

    if ready() then interfaces:addRadialItem(items) end
end

---@param id string
function Cobalt.Functions.RemoveRadialItem(id)
    radialItems[id] = nil

    if ready() then interfaces:removeRadialItem(id) end
end

---@param menu table `{ id, label?, items }`
function Cobalt.Functions.RegisterRadial(menu)
    radialMenus[menu.id] = { menu = menu, resource = caller() }

    if ready() then interfaces:registerRadial(menu) end
end

function Cobalt.Functions.HideRadial()
    if ready() then interfaces:hideRadial() end
end

---@param state boolean
function Cobalt.Functions.DisableRadial(state)
    if ready() then interfaces:disableRadial(state) end
end

AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= RESOURCE then return end

    for _, entry in pairs(contexts) do
        interfaces:registerContext(entry.menu, entry.resource)
    end

    for _, entry in pairs(radialMenus) do
        interfaces:registerRadial(entry.menu)
    end

    local ordered <const> = {}

    for _, entry in pairs(radialItems) do
        ordered[#ordered + 1] = entry
    end

    table.sort(ordered, function(a, b) return a.order < b.order end)

    for _, entry in ipairs(ordered) do
        interfaces:addRadialItem(entry.item)
    end
end)

AddEventHandler('onClientResourceStop', function(resource)
    for id, entry in pairs(contexts) do
        if entry.resource == resource then contexts[id] = nil end
    end

    for id, entry in pairs(radialMenus) do
        if entry.resource == resource then radialMenus[id] = nil end
    end

    for id, entry in pairs(radialItems) do
        if entry.resource == resource then Cobalt.Functions.RemoveRadialItem(id) end
    end
end)

for _, name in ipairs({
    'Notify',
    'Progressbar',
    'ShowTextUI', 'HideTextUI', 'IsTextUIOpen',
    'SkillCheck',
    'RegisterContext', 'ShowContext', 'HideContext',
    'InputDialog', 'AlertDialog',
    'AddRadialItem', 'RemoveRadialItem', 'RegisterRadial', 'HideRadial', 'DisableRadial',
}) do
    exports(name, Cobalt.Functions[name])
end

exports('progressActive', progressActive)
exports('cancelProgress', cancelProgress)
