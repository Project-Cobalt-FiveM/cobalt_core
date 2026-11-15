local STATE_KEY <const> = 'cobalt:stateid'

---@type table<string, integer>
local known <const> = {}

---@param license string
---@return integer?
local function find(license)
    local stateId = known[license]

    if stateId then return stateId end

    stateId = MySQL.scalar.await('SELECT state_id FROM state_ids WHERE license = ?', { license })
    known[license] = stateId

    return stateId
end

---@param license string
---@return integer stateId the player's permanent number, issued in join order the first time they connect
local function claim(license)
    local existing <const> = find(license)

    if existing then return existing end

    local ok <const>, inserted <const> = pcall(MySQL.insert.await, 'INSERT INTO state_ids (license) VALUES (?)', { license })

    if ok and inserted then
        known[license] = inserted

        return inserted
    end

    return find(license) --[[@as integer]]
end

---@param playerId integer
---@param stateId integer
local function publish(playerId, stateId)
    if not DoesPlayerExist(tostring(playerId)) then return end

    local state <const> = Player(playerId).state

    if state[STATE_KEY] ~= stateId then state:set(STATE_KEY, stateId, true) end
end

local function publishOnline()
    local online <const>, licenses <const> = {}, {}

    for _, id in ipairs(GetPlayers()) do
        local playerId <const> = tonumber(id) --[[@as integer]]
        local license <const> = Cobalt.Functions.GetIdentifier(playerId, 'license')

        if license then
            online[#online + 1] = { id = playerId, license = license }
            licenses[#licenses + 1] = license
        end
    end

    if #licenses == 0 then return end

    local rows <const> = MySQL.query.await('SELECT license, state_id FROM state_ids WHERE license IN (?)', { licenses })

    for _, row in ipairs(rows or {}) do known[row.license] = row.state_id end

    for _, player in ipairs(online) do publish(player.id, claim(player.license)) end
end

AddEventHandler('playerJoining', function()
    local playerId <const> = source
    local license <const> = Cobalt.Functions.GetIdentifier(playerId, 'license')

    if license then publish(playerId, claim(license)) end
end)

return {
    claim = claim,
    publishOnline = publishOnline,
}
