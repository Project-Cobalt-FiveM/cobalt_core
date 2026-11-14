local function round2(n) return math.floor(n * 100 + 0.5) / 100 end
local function fmt2(c)    return ('vec2(%s, %s)'):format(round2(c.x), round2(c.y)) end
local function fmt3(c)    return ('vec3(%s, %s, %s)'):format(round2(c.x), round2(c.y), round2(c.z)) end
local function fmt4(c, h) return ('vec4(%s, %s, %s, %s)'):format(round2(c.x), round2(c.y), round2(c.z), round2(h)) end

local function emitVector(text)
    lib.print.info(text)
    lib.setClipboard(text)
    Cobalt.Functions.Notify({ description = Lang:t('success.copied', { text = text }), type = 'success' })
end

AddEventHandler('cobalt_core:Client:PrintVector', function(kind)
    local ped <const> = cache.ped
    local coords <const> = GetEntityCoords(ped)
    if kind == 2 then
        emitVector(fmt2(coords))
    elseif kind == 4 then
        emitVector(fmt4(coords, GetEntityHeading(ped)))
    else
        emitVector(fmt3(coords))
    end
end)
