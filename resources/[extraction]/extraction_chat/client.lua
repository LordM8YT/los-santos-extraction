local CHAT_SUGGESTIONS = {
    {
        name = '/raidbag',
        help = 'Show your raid bag, stash and extraction profile.',
    },
    {
        name = '/raidleave',
        help = 'Leave the active raid and lose unsecured carried loot.',
    },
    {
        name = '/extractstats',
        help = 'Show extraction stats, stash value and progression.',
    },
    {
        name = '/coords',
        help = 'Copy your current coordinates for content placement.',
        params = {
            { name = 'format', help = 'Optional: vec3, vec4 or table.' },
        },
    },
    {
        name = '/copycoords',
        help = 'Copy your current coordinates as a vec4.',
    },
}

local isChatOpen = false
local suggestions = {}

local function cloneSuggestion(suggestion)
    return {
        name = suggestion.name,
        help = suggestion.help or '',
        params = suggestion.params or {},
    }
end

local function sendSuggestions()
    SendNUIMessage({
        action = 'setSuggestions',
        suggestions = suggestions,
    })
end

local function addSuggestion(suggestion)
    if not suggestion or not suggestion.name then
        return
    end

    for index, existing in ipairs(suggestions) do
        if existing.name == suggestion.name then
            suggestions[index] = cloneSuggestion(suggestion)
            sendSuggestions()
            return
        end
    end

    suggestions[#suggestions + 1] = cloneSuggestion(suggestion)
    sendSuggestions()
end

local function removeSuggestion(commandName)
    if not commandName then
        return
    end

    for index, suggestion in ipairs(suggestions) do
        if suggestion.name == commandName then
            table.remove(suggestions, index)
            sendSuggestions()
            return
        end
    end
end

local function closeChat()
    if not isChatOpen then
        return
    end

    isChatOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({ action = 'setVisible', visible = false })
end

local function openChat(prefill)
    if isChatOpen then
        return
    end

    isChatOpen = true
    SetTextChatEnabled(false)
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    sendSuggestions()
    SendNUIMessage({
        action = 'setVisible',
        visible = true,
        prefill = prefill or '',
    })
end

local function sanitizeText(value)
    if type(value) ~= 'string' then
        return ''
    end

    value = value:gsub('[\r\n]', ' ')
    value = value:gsub('^%s+', ''):gsub('%s+$', '')
    return value:sub(1, 180)
end

local function formatChatPayload(payload)
    if type(payload) == 'string' then
        return {
            author = 'SYSTEM',
            text = sanitizeText(payload),
            variant = 'system',
        }
    end

    if type(payload) ~= 'table' then
        return nil
    end

    if payload.text then
        return {
            author = sanitizeText(payload.author or 'SYSTEM'),
            text = sanitizeText(payload.text),
            variant = payload.variant or 'system',
        }
    end

    local args = payload.args
    if type(args) ~= 'table' or #args == 0 then
        return nil
    end

    if #args == 1 then
        return {
            author = 'SYSTEM',
            text = sanitizeText(tostring(args[1])),
            variant = 'system',
        }
    end

    return {
        author = sanitizeText(tostring(args[1])),
        text = sanitizeText(table.concat(args, ' ', 2)),
        variant = 'player',
    }
end

local function addMessage(message)
    if not message or message.text == '' then
        return
    end

    SendNUIMessage({
        action = 'addMessage',
        message = message,
    })
end

RegisterCommand('+lsx_chat', function()
    openChat('')
end, false)

RegisterCommand('-lsx_chat', function() end, false)
RegisterKeyMapping('+lsx_chat', 'Open Los Santos Extraction chat', 'keyboard', 'T')

RegisterCommand('+lsx_command_chat', function()
    openChat('/')
end, false)

RegisterCommand('-lsx_command_chat', function() end, false)
RegisterKeyMapping('+lsx_command_chat', 'Open Los Santos Extraction command chat', 'keyboard', 'SLASH')

RegisterNUICallback('submit', function(data, cb)
    local message = sanitizeText(data and data.message)
    closeChat()

    if message ~= '' then
        if message:sub(1, 1) == '/' then
            ExecuteCommand(message:sub(2))
        else
            TriggerServerEvent('extraction_chat:server:message', message)
        end
    end

    cb({ ok = true })
end)

RegisterNUICallback('close', function(_, cb)
    closeChat()
    cb({ ok = true })
end)

RegisterNetEvent('extraction_chat:client:addMessage', function(message)
    addMessage(formatChatPayload(message))
end)

RegisterNetEvent('chat:addMessage', function(message)
    addMessage(formatChatPayload(message))
end)

RegisterNetEvent('chat:addSuggestion', function(name, help, params)
    addSuggestion({
        name = name,
        help = help,
        params = params or {},
    })
end)

RegisterNetEvent('chat:removeSuggestion', function(name)
    removeSuggestion(name)
end)

RegisterNetEvent('chat:clear', function()
    SendNUIMessage({ action = 'clearMessages' })
end)

CreateThread(function()
    SetTextChatEnabled(false)

    for _, suggestion in ipairs(CHAT_SUGGESTIONS) do
        addSuggestion(suggestion)
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        SetTextChatEnabled(false)
    end
end)

CreateThread(function()
    while true do
        if isChatOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 257, true)
            Wait(0)
        else
            Wait(500)
        end
    end
end)
