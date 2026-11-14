---@param name string
---@param title string
---@param color? string
---@param message? string
---@param tagEveryone? boolean
---@param imageUrl? string
local function createLog(name, title, color, message, tagEveryone, imageUrl)
    exports.cobalt_core:Log(name, title, {
        description = message,
        image = imageUrl,
        from = GetInvokingResource(),
    }, tagEveryone and 'warn' or 'info')
end

AddEventHandler('qb-log:server:CreateLog', createLog)

AddEventHandler('__cfx_export_qb-log_CreateLog', function(setCb)
    setCb(createLog)
end)
