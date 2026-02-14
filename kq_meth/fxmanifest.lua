shared_script '@WaveShield/resource/include.lua'

fx_version 'cerulean'
games { 'gta5' }
lua54 'yes'

author 'KuzQuality | Kuzkay'
description 'Meth cooking script by KuzQuality'
version '1.7.0'

data_file 'DLC_ITYP_REQUEST' 'stream/kq_meth.ytyp'

dependencies {
    '/onesync',
}

files {
    'stream/*.*'
}

server_scripts {
    -- dependencies
    'locale.lua',
    'config.lua',
    
    -- resource
    'server/editable/editable.lua',
    'server/utils.lua',
    
    'server/guards.lua',
    'server/server.lua',
    'server/editable/debug.lua',
}

shared_scripts {
    'link_check.lua'
}

client_scripts {
    -- dependencies
    'locale.lua',
    'config.lua',
    
    -- resource
    
    'client/utils.lua',
    'client/settings.lua',
    'client/resources/reactions.lua',
    'client/resources/types.lua',
    'client/resources/resource.lua',
    'client/devices/devices.lua',
    'client/cache.lua',
    'client/functions.lua',
    'client/enterexit.lua',
    'client/cooking/smoke.lua',
    'client/cooking/interactions.lua',
    'client/cooking/dragging.lua',
    'client/cooking/finish.lua',
    'client/cooking/main.lua',
    'client/main.lua',
    'client/editable/editable.lua',

    'client/collections/ammonia.lua',
    'client/collections/simple.lua',
    'client/guards.lua',
    
    'client/editable/debug.lua',
}

escrow_ignore {
    'config.lua',
    'locale.lua',
    'link_check.lua',
    '_INSTALLATION/*.lua',
    'client/editable/*.lua',
    'server/editable/*.lua',
    'stream/*.ytd',
}

dependency '/assetpacks'