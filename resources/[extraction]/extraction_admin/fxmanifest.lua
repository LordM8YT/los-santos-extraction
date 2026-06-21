fx_version "cerulean"
game "gta5"
lua54 "yes"

name "extraction_admin"
description "Project-specific admin helpers for Los Santos Extraction."
author "Los Santos Extraction"
version "0.1.0"

ui_page "web/index.html"

client_scripts {
    "client.lua"
}

server_scripts {
    "server.lua"
}

files {
    "web/index.html",
    "web/app.js"
}
