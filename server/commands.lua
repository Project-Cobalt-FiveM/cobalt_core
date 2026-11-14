local config <const> = require 'config.server'

Cobalt.Commands = {}
Cobalt.Commands.List = {}
Cobalt.Commands.IgnoreList = {
    owner = true,
    user = true,
}

function Cobalt.Commands.Add(name, help, arguments, argsrequired, callback, permission, ...)
    if not permission then permission = 'user' end

    local restricted
    local extraPerms <const> = ... and { ... } or nil
    if extraPerms then
        restricted = { ('group.' .. permission):lower() }
        for _, p in ipairs(extraPerms) do
            restricted[#restricted + 1] = ('group.' .. tostring(p)):lower()
        end
    elseif permission == 'user' then
        restricted = false
    else
        restricted = ('group.' .. permission):lower()
    end

    local params
    if arguments and #arguments > 0 then
        params = {}
        for i = 1, #arguments do
            local a <const> = arguments[i]
            params[i] = {
                name     = a.name,
                help     = a.help,
                type     = a.type,
                optional = not argsrequired,
            }
        end
    end

    local wrappedCallback = callback
    if params and callback then
        wrappedCallback = function(source, args, raw)
            for i = 1, #params do
                local pname <const> = params[i].name
                if args[i] == nil and pname and args[pname] ~= nil then
                    args[i] = args[pname]
                end
            end
            return callback(source, args, raw)
        end
    end

    lib.addCommand(name, {
        help       = help,
        params     = params,
        restricted = restricted,
    }, wrappedCallback)

    Cobalt.Commands.List[name:lower()] = {
        name         = name:lower(),
        permission   = permission,
        help         = help,
        arguments    = arguments,
        argsrequired = argsrequired,
        callback     = callback,
    }
end

function Cobalt.Commands.Refresh(source)
    local src <const> = source
    local Player <const> = Cobalt.Functions.GetPlayer(src)
    if not Player then return end
    local suggestions <const> = {}
    for command, info in pairs(Cobalt.Commands.List) do
        if IsPlayerAceAllowed(tostring(src), 'command.' .. command) then
            suggestions[#suggestions + 1] = {
                name   = '/' .. command,
                help   = info.help,
                params = info.arguments,
            }
        else
            TriggerClientEvent('chat:removeSuggestion', src, '/' .. command)
        end
    end
    TriggerClientEvent('chat:addSuggestions', src, suggestions)
end

---@param value? string
---@return number?
local function coordinate(value)
    local number <const> = value and tonumber((value:gsub(',', '')))

    return number and number + 0.0
end

Cobalt.Commands.Add('tp', Lang:t('command.tp.help'), { { name = Lang:t('command.tp.params.x.name'), help = Lang:t('command.tp.params.x.help') }, { name = Lang:t('command.tp.params.y.name'), help = Lang:t('command.tp.params.y.help') }, { name = Lang:t('command.tp.params.z.name'), help = Lang:t('command.tp.params.z.help') } }, false, function(source, args)
    if args[1] and not args[2] and not args[3] then
        if tonumber(args[1]) then
            local target <const> = GetPlayerPed(tonumber(args[1]))
            if target ~= 0 then
                local coords <const> = GetEntityCoords(target)
                TriggerClientEvent('cobalt_core:Command:TeleportToPlayer', source, coords)
            else
                Cobalt.Functions.Notify(source, { description = Lang:t('error.not_online'), type = 'error' })
            end
        else
            local location <const> = CobaltShared.Locations[args[1]]
            if location then
                TriggerClientEvent('cobalt_core:Command:TeleportToCoords', source, location.x, location.y, location.z, location.w)
            else
                Cobalt.Functions.Notify(source, { description = Lang:t('error.location_not_exist'), type = 'error' })
            end
        end
    else
        if not args[1] or not args[2] then
            Cobalt.Functions.Notify(source, { description = Lang:t('error.missing_args'), type = 'error' })
            return
        end

        local x <const>, y <const> = coordinate(args[1]), coordinate(args[2])
        local z <const>, heading <const> = coordinate(args[3]), coordinate(args[4])

        if not x or not y or (args[3] and not z) or (args[4] and not heading) then
            Cobalt.Functions.Notify(source, { description = Lang:t('error.wrong_format'), type = 'error' })
            return
        end

        TriggerClientEvent('cobalt_core:Command:TeleportToCoords', source, x, y, z, heading)
    end
end, 'admin')

Cobalt.Commands.Add('tpm', Lang:t('command.tpm.help'), {}, false, function(source)
    TriggerClientEvent('cobalt_core:Command:GoToMarker', source)
end, 'admin')

Cobalt.Commands.Add('togglepvp', Lang:t('command.togglepvp.help'), {}, false, function()
    GlobalState:set('pvp', not GlobalState.pvp, true)
    TriggerClientEvent('cobalt_core:Client:PvpHasToggled', -1, GlobalState.pvp)
end, 'admin')

Cobalt.Commands.Add('addpermission', Lang:t('command.addpermission.help'), { { name = Lang:t('command.addpermission.params.id.name'), help = Lang:t('command.addpermission.params.id.help') }, { name = Lang:t('command.addpermission.params.permission.name'), help = Lang:t('command.addpermission.params.permission.help') } }, true, function(source, args)
    local Player <const> = Cobalt.Functions.GetPlayer(tonumber(args[1]))
    local permission <const> = tostring(args[2]):lower()
    if Player then
        Cobalt.Functions.AddPermission(Player.PlayerData.source, permission)
    else
        Cobalt.Functions.Notify(source, { description = Lang:t('error.not_online'), type = 'error' })
    end
end, 'owner')

Cobalt.Commands.Add('removepermission', Lang:t('command.removepermission.help'), { { name = Lang:t('command.removepermission.params.id.name'), help = Lang:t('command.removepermission.params.id.help') }, { name = Lang:t('command.removepermission.params.permission.name'), help = Lang:t('command.removepermission.params.permission.help') } }, true, function(source, args)
    local Player <const> = Cobalt.Functions.GetPlayer(tonumber(args[1]))
    local permission <const> = tostring(args[2]):lower()
    if Player then
        Cobalt.Functions.RemovePermission(Player.PlayerData.source, permission)
    else
        Cobalt.Functions.Notify(source, { description = Lang:t('error.not_online'), type = 'error' })
    end
end, 'owner')

Cobalt.Commands.Add('openserver', Lang:t('command.openserver.help'), {}, false, function(source)
    if not config.closed then
        Cobalt.Functions.Notify(source, { description = Lang:t('error.server_already_open'), type = 'error' })
        return
    end
    if Cobalt.Functions.HasPermission(source, 'admin') then
        config.closed = false
        Cobalt.Functions.Notify(source, { description = Lang:t('success.server_opened'), type = 'success' })
    else
        Cobalt.Functions.Kick(source, Lang:t('error.no_permission'), nil, nil)
    end
end, 'admin')

Cobalt.Commands.Add('closeserver', Lang:t('command.closeserver.help'), { { name = Lang:t('command.closeserver.params.reason.name'), help = Lang:t('command.closeserver.params.reason.help') } }, false, function(source, args)
    if config.closed then
        Cobalt.Functions.Notify(source, { description = Lang:t('error.server_already_closed'), type = 'error' })
        return
    end
    if Cobalt.Functions.HasPermission(source, 'admin') then
        local reason <const> = args[1] or Lang:t('info.no_reason')
        config.closed = true
        config.closedReason = reason
        for k in pairs(Cobalt.Players) do
            if not Cobalt.Functions.HasPermission(k, config.whitelistPermission) then
                Cobalt.Functions.Kick(k, reason, nil, nil)
            end
        end
        Cobalt.Functions.Notify(source, { description = Lang:t('success.server_closed'), type = 'success' })
    else
        Cobalt.Functions.Kick(source, Lang:t('error.no_permission'), nil, nil)
    end
end, 'admin')

Cobalt.Commands.Add('dv', Lang:t('command.dv.help'), {}, false, function(source)
    TriggerClientEvent('cobalt_core:Command:DeleteVehicle', source)
end, 'admin')

Cobalt.Commands.Add('dvall', Lang:t('command.dvall.help'), {}, false, function()
    local vehicles <const> = GetAllVehicles()
    for _, vehicle in ipairs(vehicles) do
        DeleteEntity(vehicle)
    end
end, 'admin')

Cobalt.Commands.Add('dvp', Lang:t('command.dvp.help'), {}, false, function()
    local peds <const> = GetAllPeds()
    for _, ped in ipairs(peds) do
        DeleteEntity(ped)
    end
end, 'admin')

Cobalt.Commands.Add('dvo', Lang:t('command.dvo.help'), {}, false, function()
    local objects <const> = GetAllObjects()
    for _, object in ipairs(objects) do
        DeleteEntity(object)
    end
end, 'admin')

Cobalt.Commands.Add('givemoney', Lang:t('command.givemoney.help'), { { name = Lang:t('command.givemoney.params.id.name'), help = Lang:t('command.givemoney.params.id.help') }, { name = Lang:t('command.givemoney.params.moneytype.name'), help = Lang:t('command.givemoney.params.moneytype.help') }, { name = Lang:t('command.givemoney.params.amount.name'), help = Lang:t('command.givemoney.params.amount.help') } }, true, function(source, args)
    local Player <const> = Cobalt.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        Player.Functions.AddMoney(tostring(args[2]), tonumber(args[3]), 'Admin give money')
    else
        Cobalt.Functions.Notify(source, { description = Lang:t('error.not_online'), type = 'error' })
    end
end, 'admin')

Cobalt.Commands.Add('setmoney', Lang:t('command.setmoney.help'), { { name = Lang:t('command.setmoney.params.id.name'), help = Lang:t('command.setmoney.params.id.help') }, { name = Lang:t('command.setmoney.params.moneytype.name'), help = Lang:t('command.setmoney.params.moneytype.help') }, { name = Lang:t('command.setmoney.params.amount.name'), help = Lang:t('command.setmoney.params.amount.help') } }, true, function(source, args)
    local Player <const> = Cobalt.Functions.GetPlayer(tonumber(args[1]))
    if Player then
        Player.Functions.SetMoney(tostring(args[2]), tonumber(args[3]))
    else
        Cobalt.Functions.Notify(source, { description = Lang:t('error.not_online'), type = 'error' })
    end
end, 'admin')

---@param source integer
local function showJob(source)
    local PlayerJob <const> = exports.cobalt_management:GetJob(source)
    if not PlayerJob then return end

    Cobalt.Functions.Notify(source, { description = Lang:t('info.job_info', { value = PlayerJob.label or PlayerJob.name, value2 = PlayerJob.grade?.name or '—', value3 = PlayerJob.onduty == true }) })
end

Cobalt.Commands.Add('job', Lang:t('command.job.help'), {}, false, showJob, 'user')

Cobalt.Commands.Add('gang', Lang:t('command.gang.help'), {}, false, function(source)
    local PlayerGang <const> = exports.cobalt_management:GetGang(source)
    if not PlayerGang then return end
    Cobalt.Functions.Notify(source, { description = Lang:t('info.gang_info', { value = PlayerGang.label, value2 = PlayerGang.grade?.name or '—' }) })
end, 'user')
