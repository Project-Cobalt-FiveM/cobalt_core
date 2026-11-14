local extraFiles <const> = require 'config.server'.migrations

local COUNT_TABLES <const> = [[
    SELECT COUNT(*) FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN (?)
]]

local core <const> = promise.new()

---@param resource string
---@param done boolean
local function markMigrated(resource, done)
    GlobalState:set(('cobalt:migrated:%s'):format(resource), done, false)
end

markMigrated(cache.resource, false)

---@param sql string
---@return string[]
local function splitStatements(sql)
    local statements <const> = {}
    local current = {}
    local quote
    local i = 1
    local length <const> = #sql

    local function finish()
        local statement <const> = table.concat(current):match('^%s*(.-)%s*$')

        if statement ~= '' then statements[#statements + 1] = statement end

        current = {}
    end

    while i <= length do
        local char <const> = sql:sub(i, i)
        local pair <const> = sql:sub(i, i + 1)

        if quote then
            current[#current + 1] = char

            if char == '\\' and quote ~= '`' then
                current[#current + 1] = sql:sub(i + 1, i + 1)
                i += 1
            elseif char == quote then
                quote = nil
            end
        elseif pair == '/*' then
            local close <const> = sql:find('*/', i + 2, true)
            i = (close or length) + 1
        elseif char == '#' or sql:match('^%-%-%s', i) then
            local close <const> = sql:find('\n', i, true)
            i = (close or length) + 1
        elseif char == ';' then
            finish()
        else
            if char == "'" or char == '"' or char == '`' then quote = char end

            current[#current + 1] = char
        end

        i += 1
    end

    finish()

    return statements
end

---@param statement string
---@return string?
local function createdTable(statement)
    local _, last <const> = statement:upper():find('^CREATE%s+TABLE%s+IF%s+NOT%s+EXISTS%s+')

    return last and statement:match('^`?([%w_]+)', last + 1)
end

---@param resource string
---@return { file: string, statements: string[] }[] files
---@return string[] tables
local function readFiles(resource)
    local files <const> = {}
    local tables <const> = {}

    for _, file in ipairs(extraFiles[resource] or { ('sql/%s.sql'):format(resource) }) do
        local sql <const> = LoadResourceFile(resource, file)

        if sql then
            local statements <const> = splitStatements(sql)

            files[#files + 1] = { file = file, statements = statements }

            for i = 1, #statements do
                local name <const> = createdTable(statements[i])

                if name and not lib.table.contains(tables, name) then tables[#tables + 1] = name end
            end
        end
    end

    return files, tables
end

---@param resource string
---@param tables string[]
---@return boolean
local function tablesExist(resource, tables)
    local ok <const>, found <const> = pcall(MySQL.scalar.await, COUNT_TABLES, { tables })

    if ok then return found == #tables end

    lib.print.error(('could not check the tables of %s: %s'):format(resource, found))
    return false
end

---@param resource string
---@param files { file: string, statements: string[] }[]
---@return boolean
local function runFiles(resource, files)
    for _, entry in ipairs(files) do
        for i, statement in ipairs(entry.statements) do
            local ok <const>, err <const> = pcall(MySQL.query.await, statement)

            if not ok then
                local message <const> = ('%s: statement %d of %s failed'):format(resource, i, entry.file)

                lib.print.error(('%s: %s'):format(message, err))
                exports.cobalt_core:Log('core.migration', message, {
                    resource = resource,
                    file = entry.file,
                    statement = i,
                    error = tostring(err),
                }, 'error')

                return false
            end
        end
    end

    lib.print.info(('created the tables of %s'):format(resource))
    return true
end

---@param resource string
local function migrate(resource)
    local files <const>, tables <const> = readFiles(resource)

    if #files == 0 then return end
    if #tables > 0 and tablesExist(resource, tables) then return end

    runFiles(resource, files)
end

---@param resource string
local function start(resource)
    markMigrated(resource, false)
    Citizen.Await(core)
    migrate(resource)
    markMigrated(resource, true)
end

MySQL.ready(function()
    migrate(cache.resource)
    core:resolve()
    markMigrated(cache.resource, true)
end)

AddEventHandler('onResourceStarting', start)
