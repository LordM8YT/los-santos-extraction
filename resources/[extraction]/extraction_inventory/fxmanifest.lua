fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'extraction_inventory'
author 'OpenAI Codex'
description 'Standalone inventory UI for the extraction prototype.'
version '1.0.1'

dependency 'extraction_items'

ui_page 'web/inventory.html'

files {
    'web/inventory.html',
    'web/inventory.css',
    'web/inventory.js'
}

client_script 'client/main.lua'
