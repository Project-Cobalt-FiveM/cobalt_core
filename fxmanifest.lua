fx_version 'cerulean'
game 'gta5'
lua54 'yes'
use_experimental_fxv2_oal 'yes'
name 'cobalt_core'
author 'Project Cobalt'
description 'Core resource for the framework, contains all the core functionality and features'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/locale.lua',
    'shared/main.lua',
    'shared/vehicles.lua',
    'shared/locations.lua',
}

client_scripts {
    'client/main.lua',
    'client/functions.lua',
    'client/interface.lua',
    'client/radial.lua',
    'client/loops.lua',
    'client/events.lua',
    'client/tempjob.lua',
    'client/licenses.lua',
    'client/idcard.lua',
    'client/stateid.lua',
    'client/devcommands.lua',
    'client/vehiclenames.lua',
    'bridge/qb/client/main.lua',
}

server_scripts {
    '@cobalt_mysql/lib/MySQL.lua',
    'server/migrations.lua',
    'server/main.lua',
    'server/functions.lua',
    'server/player.lua',
    'server/events.lua',
    'server/commands.lua',
    'server/exports.lua',
    'server/vehicles.lua',
    'server/tempjob.lua',
    'server/licenses.lua',
    'server/idcard.lua',
    'server/fivemesh/init.lua',
    'server/npwd.lua',
    'server/radial.lua',
    'server/publish.lua',
    'bridge/qb/server/main.lua',
}

provide 'qb-core'

files {
    'config/shared.lua',
    'data/*.lua',
    'shared/vehicle.lua',
    'locales/*.json',
    'bridge/qb/shared/main.lua',
    'bridge/qb/client/events.lua',
    'bridge/qb/client/functions.lua',
    'bridge/qb/client/drawtext.lua',
}

dependencies {
    'ox_lib',
    'cobalt_mysql',
}
