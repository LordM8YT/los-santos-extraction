local MAX_MESSAGE_LENGTH = 180

local function sanitizeText(value)
    if type(value) ~= 'string' then
        return ''
    end

    value = value:gsub('[\r\n]', ' ')
    value = value:gsub('^%s+', ''):gsub('%s+$', '')
    return value:sub(1, MAX_MESSAGE_LENGTH)
end

RegisterNetEvent('extraction_chat:server:message', function(rawMessage)
    local source = source
    local message = sanitizeText(rawMessage)

    if message == '' then
        return
    end

    TriggerClientEvent('extraction_chat:client:addMessage', -1, {
        author = sanitizeText(GetPlayerName(source) or ('Player ' .. source)),
        text = message,
        variant = 'player',
    })
end)
