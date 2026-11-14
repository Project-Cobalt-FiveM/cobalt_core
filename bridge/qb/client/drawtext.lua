local qbShared <const> = require 'bridge.qb.shared.main'

---@type table<string, string>
local positions <const> = {
    left = 'left-center',
    right = 'right-center',
    top = 'top-center',
}

---@param text string
---@param position? 'left' | 'right' | 'top'
local function drawText(text, position)
    Cobalt.Functions.ShowTextUI(text, { position = positions[position] or 'left-center' })
end

qbShared.export('DrawText', drawText)
qbShared.export('ChangeText', drawText)
qbShared.export('HideText', Cobalt.Functions.HideTextUI)
qbShared.export('KeyPressed', Cobalt.Functions.HideTextUI)
