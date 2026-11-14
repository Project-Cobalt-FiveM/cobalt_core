local config <const> = require 'server.fivemesh.config'
local storage <const> = require 'server.fivemesh.storage'

local NPWD <const> = 'npwd'
local UPLOAD_PATH <const> = '/npwd/upload'
local BASE64 <const> = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

---@return string
local function uploadToken()
    local token = GetConvar('SCREENSHOT_BASIC_TOKEN', '')

    if token == '' then
        token = ('%08x%08x%08x%08x'):format(
            math.random(0, 0x7fffffff),
            math.random(0, 0x7fffffff),
            math.random(0, 0x7fffffff),
            math.random(0, 0x7fffffff)
        )
        SetConvar('SCREENSHOT_BASIC_TOKEN', token)
    end

    return token
end

local token <const> = uploadToken()

---@return boolean
local function npwdStarted()
    return GetResourceState(NPWD) == 'started'
end

---@param Player table
local function registerWithNpwd(Player)
    local data <const> = Player.PlayerData
    local charinfo <const> = data.charinfo or {}

    exports.npwd:newPlayer({
        source = data.source,
        identifier = data.citizenid,
        firstname = charinfo.firstname or '',
        lastname = charinfo.lastname or '',
    })
end

AddEventHandler('cobalt_core:Server:PlayerLoaded', function(Player)
    if not npwdStarted() then return end

    registerWithNpwd(Player)
end)

AddEventHandler('cobalt_core:Server:OnPlayerUnload', function(source)
    if not npwdStarted() then return end

    exports.npwd:unloadPlayer(source)
end)

AddEventHandler('onServerResourceStart', function(resource)
    if resource ~= NPWD then return end

    for _, Player in pairs(Cobalt.Players) do
        registerWithNpwd(Player)
    end
end)

---@param text string Base64 whose length is a multiple of 4
---@return string
local function decodeBase64(text)
    local bytes <const> = {}

    for i = 1, #text, 4 do
        local value = 0

        for j = i, i + 3 do
            value = value * 64 + BASE64:find(text:sub(j, j), 1, true) - 1
        end

        bytes[#bytes + 1] = string.char(value >> 16 & 0xff, value >> 8 & 0xff, value & 0xff)
    end

    return table.concat(bytes)
end

---@param image string Base64 image
---@return string? contentType
---@return string? extension
local function sniffImage(image)
    local head <const> = decodeBase64(image:sub(1, 16))

    if head:sub(1, 3) == '\xFF\xD8\xFF' then return 'image/jpeg', 'jpg' end
    if head:sub(1, 8) == '\x89PNG\r\n\x1A\n' then return 'image/png', 'png' end
    if head:sub(1, 4) == 'RIFF' and head:sub(9, 12) == 'WEBP' then return 'image/webp', 'webp' end
end

---@param address string
---@return boolean
local function isLoopback(address)
    local host <const> = address:match('^%[(.-)%]') or address:match('^([%d%.]+):%d+$') or address

    return host:find('^127%.') ~= nil or host:find('^::ffff:127%.') ~= nil or host == '::1'
end

---@param request table
---@return boolean
local function isNpwd(request)
    local authorization <const> = request.headers.Authorization or request.headers.authorization or ''

    return isLoopback(request.address or '') and authorization:match('^%s*Bearer%s+(%S+)%s*$') == token
end

---@param request table
---@return boolean
local function carriesPhone(request)
    local source <const> = tonumber(request.headers['X-Npwd-Source'] or request.headers['x-npwd-source'])

    if not source or not GetPlayerName(source) then return false end
    if GetResourceState('cobalt_inventory') ~= 'started' then return false end

    local ok <const>, held <const> = pcall(exports.cobalt_inventory.HasItem, exports.cobalt_inventory, source, 'phone')

    return ok and held == true
end

---@param response table
---@param status integer
---@param body table
local function reply(response, status, body)
    response.writeHead(status, { ['Content-Type'] = 'application/json' })
    response.send(json.encode(body))
end

---@param image string
---@param response table
local function uploadPhoto(image, response)
    if #image > config.phone.maxBytes * 4 // 3 + 4 then
        return reply(response, 413, { error = 'image is over the size limit' })
    end

    if #image < 16 or #image % 4 ~= 0 or image:find('[^%w%+/=]') then
        return reply(response, 400, { error = 'body must be a Base64 image' })
    end

    local contentType, extension = sniffImage(image)

    if not contentType then
        return reply(response, 415, { error = 'body must be a JPEG, PNG or WebP image' })
    end

    local path <const> = ('%s/%x%08x.%s'):format(config.phone.folder, os.time(), math.random(0, 0x7fffffff), extension)
    local url, err = storage.upload(path, image, contentType)

    if not url then
        lib.print.warn(('npwd photo upload failed: %s'):format(err))
        return reply(response, 502, { error = err })
    end

    reply(response, 200, { url = url })
end

SetHttpHandler(function(request, response)
    if request.method ~= 'POST' or request.path ~= UPLOAD_PATH then
        return reply(response, 404, { error = 'not found' })
    end

    if not isNpwd(request) then
        return reply(response, 403, { error = 'forbidden' })
    end

    if not carriesPhone(request) then
        return reply(response, 403, { error = 'the player carries no phone' })
    end

    request.setDataHandler(function(body)
        CreateThread(function()
            uploadPhoto(body or '', response)
        end)
    end)
end)
