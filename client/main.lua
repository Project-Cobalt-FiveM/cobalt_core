Cobalt = {}
Cobalt.PlayerData = {}
Cobalt.Shared = CobaltShared

local function GetCoreObject(filters)
    if not filters then return Cobalt end
    local results <const> = {}
    for i = 1, #filters do
        local key <const> = filters[i]
        if Cobalt[key] then
            results[key] = Cobalt[key]
        end
    end
    return results
end
exports('GetCoreObject', GetCoreObject)
