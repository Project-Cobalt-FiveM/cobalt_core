local migratedKey <const> = ('cobalt:migrated:%s'):format(GetCurrentResourceName())
local migrated <const> = promise.new()
local tablesReady = false

CreateThread(function()
    while GlobalState[migratedKey] == false do Wait(50) end

    tablesReady = true
    migrated:resolve()
end)

local function waitForTables()
    if not tablesReady then Citizen.Await(migrated) end
end

---@param method string
local function gate(method)
    local original <const> = MySQL[method]

    MySQL[method] = setmetatable({
        method = method,
        await = function(...)
            waitForTables()
            return original.await(...)
        end,
    }, {
        __call = function(_, ...)
            if tablesReady then return original(...) end

            local args <const> = table.pack(...)

            migrated:next(function() original(table.unpack(args, 1, args.n)) end)
        end,
    })
end

for _, method in ipairs({ 'scalar', 'single', 'query', 'insert', 'update', 'prepare', 'transaction', 'rawExecute' }) do
    gate(method)
end

local onDatabaseReady <const> = MySQL.ready
local startTransaction <const> = MySQL.startTransaction

MySQL.ready = setmetatable({
    await = function(cb)
        onDatabaseReady.await()
        waitForTables()
        return cb and cb() or true
    end,
}, {
    __call = function(_, cb)
        onDatabaseReady(function()
            waitForTables()
            cb()
        end)
    end,
})

---@param cb function
function MySQL.startTransaction(cb)
    waitForTables()
    return startTransaction(cb)
end
