local lang <const> = GetConvar('qb_locale', 'en')
if lib?.locale then
    pcall(lib.locale, lang)
end

Lang = {}

---@param key string
---@param subs table<string, any>?
---@return string
function Lang:t(key, subs)
    local dict <const> = lib.getLocales and lib.getLocales() or nil
    local s = (dict and dict[key]) or key
    if subs then
        for k, v in pairs(subs) do
            s = (s:gsub('%%{' .. k .. '}', (tostring(v):gsub('%%', '%%%%'))))
        end
    end
    return s
end

Locale = {}
Locale.__index = Locale

---@diagnostic disable-next-line: unused-local
function Locale.new(_, _opts)
    return Lang
end

function Locale:t(key, subs)
    return Lang:t(key, subs)
end
