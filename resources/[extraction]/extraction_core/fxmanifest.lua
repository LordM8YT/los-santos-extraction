fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'extraction_core'
author 'OpenAI Codex'
description 'Foundation resource for the modular PvPvE extraction framework.'
version '0.1.0'

dependencies {
    'ox_lib'
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/constants.lua',
    'shared/utils.lua'
}

server_scripts {
    'server/logger.lua',
    'server/identifiers.lua',
    'server/buckets.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua'
}
