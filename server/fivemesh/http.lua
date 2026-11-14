local config <const> = require 'server.fivemesh.config'

---@class FiveMeshResponse
---@field status integer 0 when the request failed or timed out
---@field body? string
---@field headers table<string, string>
---@field data? table

local http <const> = {}

---@param status integer
---@return boolean
local function isRetryable(status)
    return status == 0 or status == 408 or status == 429 or status >= 500
end

---@param headers table<string, string>
---@param attempt integer
---@return integer
local function backoff(headers, attempt)
    local retryAfter <const> = tonumber(headers['Retry-After'] or headers['retry-after'])

    if retryAfter then
        return math.min(math.floor(retryAfter * 1000), config.maxBackoff)
    end

    return math.floor(math.min(1000 * 2 ^ (attempt - 1), config.maxBackoff)) + math.random(0, 250)
end

---@param headers? table<string, string>
---@return table<string, string>
local function withAuth(headers)
    local merged <const> = {
        Authorization = 'Bearer ' .. config.apiKey,
        ['Content-Type'] = 'application/json',
    }

    for name, value in pairs(headers or {}) do
        merged[name] = value
    end

    return merged
end

---@param method string
---@param url string
---@param body string
---@param headers table<string, string>
---@return FiveMeshResponse
local function send(method, url, body, headers)
    local pending <const> = promise.new()
    local settled = false

    PerformHttpRequest(url, function(status, responseBody, responseHeaders, errorData)
        if settled then return end

        settled = true
        pending:resolve({ status = status or 0, body = responseBody or errorData, headers = responseHeaders or {} })
    end, method, body, headers)

    SetTimeout(config.timeout, function()
        if settled then return end

        settled = true
        pending:resolve({ status = 0, body = 'timed out', headers = {} })
    end)

    local response <const> = Citizen.Await(pending) --[[@as FiveMeshResponse]]
    local ok, data = pcall(json.decode, response.body or '')
    response.data = ok and type(data) == 'table' and data or nil

    return response
end

---@param response FiveMeshResponse
---@return boolean
function http.ok(response)
    return response.status >= 200 and response.status < 300
end

---@param response FiveMeshResponse
---@return string
function http.errorOf(response)
    local data <const> = response.data
    local code <const> = type(data?.error) == 'table' and data.error.code or data?.error
    local message <const> = type(data?.error) == 'table' and data.error.message or data?.message

    if code then
        return message and ('%s: %s'):format(code, message) or tostring(code)
    end

    return ('HTTP %d %s'):format(response.status, response.body or '')
end

---Sends a JSON request with the API key, retrying network failures, 408, 429 and 5xx with the same body.
---Yields, so call it from a thread.
---@param method string
---@param url string
---@param payload? table
---@param headers? table<string, string>
---@return FiveMeshResponse
function http.request(method, url, payload, headers)
    local body <const> = payload and json.encode(payload) or ''
    local requestHeaders <const> = withAuth(headers)
    local response

    for attempt = 1, config.maxAttempts do
        response = send(method, url, body, requestHeaders)

        if not isRetryable(response.status) or attempt == config.maxAttempts then break end

        Wait(backoff(response.headers, attempt))
    end

    return response
end

---Sends a JSON request once without waiting for the reply, for resource stop.
---@param method string
---@param url string
---@param payload table
function http.fire(method, url, payload)
    PerformHttpRequest(url, function() end, method, json.encode(payload), withAuth())
end

return http
