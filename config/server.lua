---@type ServerConfig
return {
    -- Joining
    closed = false, -- block joins for everyone below admin
    closedReason = 'Server Closed', -- message shown while the server is closed
    whitelist = false, -- only players with whitelistPermission can join
    whitelistPermission = 'admin', -- ACE permission that passes the whitelist
    checkDuplicateLicense = true, -- block a second connection from the same Rockstar license

    -- New characters
    spawn = vector4(-1035.71, -2731.87, 12.86, 0.0), -- where a new character appears the first time they load in

    -- Anti-spam (how often players save is the player_save_interval convar in server.cfg)
    callbackLimit = { perSecond = 10, floodSeconds = 3 }, -- callback calls per player per second; over it for floodSeconds in a row drops the player

    -- Staff and kick messages
    discord = '', -- Discord invite shown in kick and ban messages
    permissions = { 'owner', 'admin', 'staff' }, -- ranks cobalt_core can grant and remove

    -- Logging to FiveMesh (the API key is the fivemesh_api_key convar in secrets.cfg)
    logging = {
        enabled = true, -- send logs to FiveMesh; false turns logging off even with an API key set
        minLevel = 'info', -- lowest level sent: 'debug', 'info', 'warn', 'error' or 'fatal'; security logs are always sent
        environment = 'production', -- label on every log, e.g. 'production' or 'development'
        playerIdentifiers = true, -- attach the player's license, Discord, Steam and citizen ids to logs about them
        console = false, -- also print every log to the server console
        disabled = {}, -- categories not to send; a name turns off that category and everything under it, e.g. { 'chat', 'dealership.sync' }
    },

    -- Database
    migrations = { -- SQL files to create, in order, for resources whose file is not just sql/<resource>.sql
        ['illenium-appearance'] = {
            'sql/playerskins.sql',
            'sql/player_outfits.sql',
            'sql/player_outfit_codes.sql',
            'sql/management_outfits.sql',
        },
    },
}
