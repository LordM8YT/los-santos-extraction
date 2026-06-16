fx_version 'cerulean'
game 'common'

name 'extraction_chat'
author 'OpenAI Codex'
description 'Extraction-themed chat skin for the default FiveM chat resource.'
version '1.0.0'

file 'style.css'

chat_theme 'extraction' {
    styleSheet = 'style.css',
    msgTemplates = {
        default = '<div class="extract-chat-line"><span class="extract-chat-author">{0}</span><span class="extract-chat-text">{1}</span></div>',
        defaultAlt = '<div class="extract-chat-line system"><span class="extract-chat-text">{0}</span></div>',
        print = '<div class="extract-chat-line system"><span class="extract-chat-text">{0}</span></div>'
    }
}
