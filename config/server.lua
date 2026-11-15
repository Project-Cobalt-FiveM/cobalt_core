---@type ServerConfig
return {
    -- Joining
    closed = false, -- maintenance mode: only admins and owners can join, and /closeserver kicks everyone else; /openserver ends it
    closedReason = 'Server Closed', -- message shown to players turned away during maintenance
    whitelist = false, -- whitelist mode: only players holding whitelistPermission can join; /whitelist toggles it until restart
    whitelistPermission = 'whitelisted', -- ACE that passes the whitelist; staff ranks hold it in server.cfg, give it to a player with add_ace identifier.<type>:<id> whitelisted allow
    checkDuplicateLicense = true, -- block a second connection from the same Rockstar license

    -- New characters
    spawn = vector4(-1035.71, -2731.87, 12.86, 0.0), -- where a new character appears the first time they load in

    -- Anti-spam (how often players save is the player_save_interval convar in server.cfg)
    callbackLimit = { perSecond = 10, floodSeconds = 3 }, -- callback calls per player per second; over it for floodSeconds in a row drops the player

    -- Staff and kick messages
    discord = 'discord.gg/projectcobalt', -- Discord invite shown in kick and ban messages
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
