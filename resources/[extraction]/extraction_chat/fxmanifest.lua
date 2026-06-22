fx_version 'cerulean'
game 'gta5'

name 'extraction_chat'
author 'OpenAI Codex'
description 'Standalone Los Santos Extraction chat UI with command autocomplete.'
version '2.0.0'

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/styles.css',
    'web/app.js',
    'web/vendor/react.production.min.js',
    'web/vendor/react-dom.production.min.js'
}

client_script 'client.lua'
server_script 'server.lua'
