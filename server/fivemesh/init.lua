local config <const> = require 'server.fivemesh.config'
local logs <const> = require 'server.fivemesh.logs'
local storage <const> = require 'server.fivemesh.storage'

if config.apiKey == '' then
    lib.print.warn('FiveMesh disabled: fivemesh_api_key is not set, so logs and uploads are off')
end

---@param category string
---@param message string
---@param data? any
---@param level? LogLevel
---@return boolean queued
local function log(category, message, data, level)
    return logs.push({
        category = category,
        message = message,
        data = data,
        level = level,
        resource = GetInvokingResource() or cache.resource,
    })
end

---@param source integer
---@param category string
---@param message string
---@param data? any
---@param level? LogLevel
---@param target? integer
---@return boolean queued
local function logPlayer(source, category, message, data, level, target)
    return logs.push({
        category = category,
        message = message,
        data = data,
        level = level,
        source = source and tonumber(source),
        target = target and tonumber(target),
        resource = GetInvokingResource() or cache.resource,
    })
end

Cobalt.Functions.Log = log
Cobalt.Functions.LogPlayer = logPlayer
Cobalt.Functions.UploadFile = storage.upload
