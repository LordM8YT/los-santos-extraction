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

local registeredSuggestions = {}

local function addChatSuggestion(suggestion)
    TriggerEvent('chat:addSuggestion', suggestion.name, suggestion.help, suggestion.params or {})
    registeredSuggestions[#registeredSuggestions + 1] = suggestion.name
end

local function registerChatSuggestions()
    for _, suggestion in ipairs(CHAT_SUGGESTIONS) do
        addChatSuggestion(suggestion)
    end
end

CreateThread(function()
    while GetResourceState('chat') ~= 'started' do
        Wait(500)
    end

    registerChatSuggestions()
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    for _, commandName in ipairs(registeredSuggestions) do
        TriggerEvent('chat:removeSuggestion', commandName)
    end
end)
