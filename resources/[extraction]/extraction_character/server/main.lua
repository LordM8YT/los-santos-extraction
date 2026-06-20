local characters = {}

local function getIdentifier(source)
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if identifier:find('license:', 1, true) then
            return identifier
        end
    end

    return ('source:%s'):format(source)
end

local function buildDefaultCharacter()
    local defaults = ExtractionCharacterConfig.defaults or {}

    return {
        callsign = defaults.callsign or 'Contractor',
        faction = defaults.faction or 'Independent',
        archetype = defaults.archetype or 'Recon',
        model = ExtractionCharacterConfig.defaultModel or 'mp_m_freemode_01',
        components = {},
        props = {},
    }
end

local function getCharacter(source)
    local identifier = getIdentifier(source)

    if not characters[identifier] then
        characters[identifier] = buildDefaultCharacter()
    end

    return characters[identifier]
end

RegisterNetEvent('extraction_character:server:requestCurrent', function()
    TriggerClientEvent('extraction_character:client:apply', source, getCharacter(source))
end)

exports('GetCharacter', function(source)
    return getCharacter(source)
end)
