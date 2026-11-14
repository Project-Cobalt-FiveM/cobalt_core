local sharedConfig <const> = require 'config.shared'

local qb <const> = {}

---@type table<string, any>
local metadataDefaults <const> = {
    injail = 0,
    jailitems = {},
    tracker = false,
    inside = { apartment = {} },
    phone = {},
    phonedata = { SerialNumber = '', InstalledApps = {} },
    commandbinds = {},
    dealerrep = 0,
    craftingrep = 0,
    attachmentcraftingrep = 0,
}

---@param source table
---@return table
local function shallowCopy(source)
    local copy <const> = {}

    for key, value in pairs(source) do
        copy[key] = value
    end

    return copy
end

---@param playerData table cobalt_core PlayerData
---@return table? job qb-core's job: the cobalt_management job, with QBCore's `payment` field
function qb.job(playerData)
    local job = playerData.job
    if not job or job.payment or not job.grade then return job end

    job = shallowCopy(job)
    job.payment = job.grade.payment

    return job
end

---@param playerData table cobalt_core PlayerData
---@return table playerData a copy in qb-core's shape
function qb.playerData(playerData)
    local view <const> = shallowCopy(playerData)
    view.job = qb.job(playerData)

    local metadata <const> = shallowCopy(playerData.metadata or {})

    for key, value in pairs(metadataDefaults) do
        if metadata[key] == nil then
            metadata[key] = value
        end
    end

    view.metadata = metadata

    return view
end

---@param has fun(name: string, amount: integer): boolean
---@param items string | string[] | table<string, integer>
---@param amount? integer
---@return boolean
function qb.hasItems(has, items, amount)
    if type(items) ~= 'table' then return has(items, amount or 1) end

    for key, value in pairs(items) do
        local name, count = key, value

        if type(key) == 'number' then
            name, count = value, amount or 1
        end

        if not has(name, count) then return false end
    end

    return true
end

---@return table banking cobalt_banking's config table, or an empty table when it is absent
local function loadBankingConfig()
    local ok, banking = pcall(lib.load, '@cobalt_banking.config')

    return ok and type(banking) == 'table' and banking or {}
end

---@return string[] names every money type, since none can go below zero
local function moneyTypes()
    local names <const> = {}

    for name in pairs(sharedConfig.money.starting) do names[#names + 1] = name end

    return names
end

---@type table?
local money

---@return table money qb-core's Config.Money
local function moneyConfig()
    if money then return money end

    local banking <const> = loadBankingConfig()

    money = {
        MoneyTypes = sharedConfig.money.starting,
        DontAllowMinus = moneyTypes(),
        MinusLimit = 0,
        PayCheckTimeOut = banking.PaycheckInterval or 15,
        PayCheckSociety = false,
    }

    return money
end

---@param config table the side-specific fields of qb-core's Config, with its Server table
---@return table config qb-core's Config
function qb.config(config)
    config.MaxPlayers = GetConvarInt('sv_maxclients', 48)
    config.Money = moneyConfig()
    config.Player = { HungerRate = sharedConfig.status.hungerRate, ThirstRate = sharedConfig.status.thirstRate }
    config.Server.PVP = sharedConfig.pvp

    return config
end

---@param build fun(): table
---@return fun(filters?: string[]): table
function qb.coreObjectExport(build)
    return function(filters)
        local core <const> = build()
        if type(filters) ~= 'table' then return core end

        local results <const> = {}

        for i = 1, #filters do
            local key <const> = filters[i]
            results[key] = core[key]
        end

        return results
    end
end

---@param name string export name under `exports['qb-core']`
---@param fn function
function qb.export(name, fn)
    AddEventHandler(('__cfx_export_qb-core_%s'):format(name), function(setCb)
        setCb(fn)
    end)
end

---@return boolean
local function inventoryStarted()
    return GetResourceState('cobalt_inventory') == 'started'
end

---@return table<string, InventoryItemDef> items cobalt_inventory's item definitions, empty until it starts
local function sharedItems()
    if not inventoryStarted() then return {} end

    return exports.cobalt_inventory:GetSharedItems()
end

---@return table<integer, { name: string, label: string }> weapons cobalt_inventory's weapon items keyed by hash, in QBCore's Shared.Weapons shape
local function sharedWeapons()
    local weapons <const> = {}

    for name, def in pairs(sharedItems()) do
        if def.category == 'weapons' then weapons[joaat(name)] = { name = name, label = def.label } end
    end

    return weapons
end

---@return table shared qb-core's QBCore.Shared: Cobalt.Shared with cobalt_inventory's items and weapons
function qb.shared()
    local shared <const> = shallowCopy(Cobalt.Shared)
    shared.Items = sharedItems()
    shared.Weapons = sharedWeapons()

    return shared
end

function qb.exportShared()
    qb.export('GetSharedItems', sharedItems)
    qb.export('GetSharedVehicles', function() return Cobalt.Shared.Vehicles end)
    qb.export('GetSharedWeapons', sharedWeapons)
    qb.export('GetSharedJobs', function() return Cobalt.Shared.Jobs end)
    qb.export('GetSharedGangs', function() return Cobalt.Shared.Gangs end)
    qb.export('GetShared', function(namespace, item)
        if namespace == 'Items' then
            return inventoryStarted() and exports.cobalt_inventory:GetItemDef(item) or nil
        end

        if namespace == 'Weapons' then return sharedWeapons()[item] end

        local tbl <const> = Cobalt.Shared[namespace]
        if type(tbl) == 'table' then return tbl[item] end
    end)
end

---@param cobaltToQb table<string, string> cobalt event name to qb-core event name
---@param register fun(name: string, handler: function)
function qb.reemit(cobaltToQb, register)
    for cobaltEvent, qbEvent in pairs(cobaltToQb) do
        register(cobaltEvent, function(...)
            TriggerEvent(qbEvent, ...)
        end)
    end
end

return qb
