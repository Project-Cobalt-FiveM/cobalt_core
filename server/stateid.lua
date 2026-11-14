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

return {
    find = find,
    claim = claim,
}
