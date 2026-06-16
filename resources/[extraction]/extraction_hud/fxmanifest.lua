fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'extraction_hud'
author 'OpenAI Codex'
description 'Standalone extraction HUD and vanilla HUD suppressor.'
version '1.0.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/styles.css',
    'web/app.js'
}

shared_script 'shared/config.lua'

client_script 'client/main.lua'
