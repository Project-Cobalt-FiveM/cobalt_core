local config <const> = require 'server.fivemesh.config'
local http <const> = require 'server.fivemesh.http'

local storage <const> = {}

---@param path string
---@return string? folder
---@return string? filename
local function splitPath(path)
    path = path:gsub('\\', '/'):gsub('^/+', '')

    if path == '' or path:find('%.%.') or path:find('/%.') or path:find('^%.') then return end

    local folder, filename = path:match('^(.*)/([^/]+)$')

    if filename then
        return folder, filename
    end

    return nil, path
end

---Uploads a Base64 file to the FiveMesh CDN. Yields, so call it from a thread.
---@param path string folder and file name, such as `uploads/phone/123.webp`
---@param data string standard Base64 or a `data:<type>;base64,` URL
---@param contentType? string MIME type, such as `image/webp`
---@return string? url public CDN URL
---@return string? error
function storage.upload(path, data, contentType)
    if config.apiKey == '' then
        return nil, 'FiveMesh is disabled'
    end

    if type(path) ~= 'string' or type(data) ~= 'string' or data == '' then
        return nil, 'path and data must be strings'
    end

    local folder, filename = splitPath(path)

    if not filename then
        return nil, ('invalid path %s'):format(path)
    end

    local idempotencyKey <const> = ('%s-%x-%08x'):format(cache.resource, os.time(), math.random(0, 0x7fffffff))
    local response <const> = http.request('POST', config.apiUrl .. '/objects/base64', {
        data = data,
        filename = filename,
        path = folder,
        contentType = contentType,
    }, { ['Idempotency-Key'] = idempotencyKey })

    local url <const> = response.data?.object?.publicUrl

    if http.ok(response) and url then
        return url
    end

    return nil, http.errorOf(response)
end

return storage
