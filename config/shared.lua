---@type SharedConfig
return {
    -- Combat
    pvp = true, -- players can damage each other; /togglepvp changes it until restart

    -- Jobs
    forceDefaultDutyAtLogin = true, -- true: characters log in on their job's defaultDuty (data/jobs.lua); false: they keep the duty they logged out with

    -- Money (no balance can go below zero)
    money = {
        starting = { cash = 500, bank = 5000, crypto = 0 }, -- the money types a new character has, and what each starts with; bank opens their personal account
    },

    -- Hunger and thirst
    status = {
        hungerRate = 1, -- hunger lost each decayMinutes, out of 100; set both rates to 0 to turn hunger and thirst off
        thirstRate = 1, -- thirst lost each decayMinutes, out of 100
        decayMinutes = 5, -- minutes between drops in hunger and thirst
        starvingDamageSeconds = 5, -- seconds between health losses while hunger or thirst is at 0
    },

    -- Licences a character can hold, by key
    licenses = {
        driver = { label = 'Driver', pointsLimit = 12 }, -- pointsLimit: points that revoke it; leave out for a licence without points
        weapon = { label = 'Weapon' },
    },

    -- Cards shown when a player uses id_card, driver_license or gun_license
    idCard = {
        style = 'american', -- 'american' or 'lebanese'
        showNearby = true, -- also show the card to every player near the holder
        nearbyDistance = 10.0, -- how close a player must be to see the card, in meters
        requireFacing = false, -- only show it to nearby players who are facing the holder
        autoCloseSeconds = 8, -- seconds before the holder's card closes on its own
        viewerCloseSeconds = 5, -- seconds before a nearby player's card closes on its own
    },

    -- Holding the state ID key brings out a clipboard and shows the state ID over each nearby player's head
    stateIdPreview = {
        key = 'J', -- default keyboard key; players can rebind it under Settings > Key Bindings > FiveM
        radius = 8.0, -- how close a player must be for their state ID to show, in meters; the holder's own always shows
    },

    -- Starter motel room picked after character creation
    starterApartment = {
        enabled = true, -- new characters pick a motel room after creation; needs cobalt_housing
        shell = 'motel_room', -- interior shell every starter room uses
        locations = { -- each pick: id saved to metadata.starterApartment, label and description shown in the picker, door as vector4(x, y, z, heading)
            {
                id = 'pink_cage',
                label = 'Pink Cage Motel',
                description = 'Alta, a block from Vinewood Boulevard',
                door = vector4(313.32, -225.82, 54.22, 160.0),
            },
            {
                id = 'perrera_beach',
                label = 'Perrera Beach Motel',
                description = 'Del Perro, a short walk from the beach',
                door = vector4(-1477.42, -674.18, 29.04, 140.0),
            },
            {
                id = 'eastern_motel',
                label = 'Eastern Motel',
                description = 'Harmony, out on Route 68',
                door = vector4(317.03, 2623.02, 44.46, 300.0),
            },
            {
                id = 'bayview_lodge',
                label = 'Bayview Lodge',
                description = 'Paleto Forest, on the Great Ocean Highway',
                door = vector4(-696.52, 5802.48, 17.33, 64.0),
            },
        },
    },
}
