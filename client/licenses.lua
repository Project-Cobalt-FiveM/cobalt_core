local TYPES <const> = require 'config.shared'.licenses

exports('GetLicenseTypes', function()
    return TYPES
end)
