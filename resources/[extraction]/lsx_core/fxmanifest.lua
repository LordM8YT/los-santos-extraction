fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'lsx_core'
author 'OpenAI Codex'
description 'Standalone Los Santos Extraction framework core with ox-style integration surfaces.'
version '0.1.0'

dependencies {
    'ox_lib'
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/events.lua',
    'shared/utils.lua'
}

server_scripts {
    'server/identifiers.lua',
    'server/player.lua',
    'server/groups.lua',
    'server/main.lua'
}

client_scripts {
    'client/player.lua',
    'client/main.lua'
}

files {
    'lib/init.lua',
    'lib/server/init.lua',
    'lib/client/init.lua'
}
