fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'standalone_extraction'
author 'OpenAI Codex'
description 'Standalone extraction gameplay loop for FiveM with no framework dependencies.'
version '1.0.0'

dependencies {
    'extraction_items',
    'extraction_world',
    'extraction_inventory',
    'extraction_hud'
}

shared_scripts {
    'config.lua',
    'shared/session_config.lua',
    'shared/quest_config.lua'
}

client_scripts {
    'client/population.lua',
    'client/main.lua'
}

server_script 'server/main.lua'
