fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'extraction_pause'
author 'OpenAI Codex'
description 'Custom pause shell that suppresses the native GTA pause/map flow.'
version '1.0.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/styles.css',
    'web/app.js'
}

client_script 'client/main.lua'
