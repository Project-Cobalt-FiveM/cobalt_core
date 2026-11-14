local config <const> = require 'config.server'

local BLOOD_TYPES <const> = { 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-' }

return {
    citizenid = function() return Cobalt.Player.CreateCitizenId() end,
    cid = 1,
    money = {},
    charinfo = {
        firstname = 'Firstname',
        lastname = 'Lastname',
        birthdate = '2000-01-01',
        gender = 0,
        nationality = 'USA',
    },
    metadata = {
        hunger = 100,
        thirst = 100,
        stress = 0,
        isdead = false,
        inlaststand = false,
        armor = 0,
        ishandcuffed = false,
        optin = true,
        status = {},
        rep = {},
        callsign = 'NO CALLSIGN',
        bloodtype = function() return BLOOD_TYPES[math.random(#BLOOD_TYPES)] end,
        fingerprint = function() return Cobalt.Player.CreateFingerId() end,
        walletid = function() return Cobalt.Player.CreateWalletId() end,
        criminalrecord = { hasRecord = false },
        licences = {},
    },
    position = config.spawn,
}
