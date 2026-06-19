fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'extraction_items'
author 'OpenAI Codex'
description 'Shared item registry for the standalone extraction project.'
version '1.0.0'

shared_scripts {
    'shared/items.lua'
}

server_script 'server/main.lua'
client_script 'client/main.lua'