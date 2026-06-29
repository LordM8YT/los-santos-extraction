local characters = {}
local SAVE_FILE = 'data/characters.json'

local function getStorageKey(identifier)
    return ('character:%s'):format(identifier:gsub('[^%w_:.-]', '_'))
end

local function getIdentifier(source)
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if identifier:find('license:', 1, true) then
            return identifier
        end
    end

    return ('source:%s'):format(source)
end

local function getAllowedModel(model)
    local models = ExtractionCharacterConfig.models or {}

    for _, allowedModel in pairs(models) do
        if model == allowedModel then
            return allowedModel
        end
    end

    return ExtractionCharacterConfig.defaultModel or 'mp_m_freemode_01'
end

local function loadCharacters()
    local encoded = LoadResourceFile(GetCurrentResourceName(), SAVE_FILE)
    if not encoded or encoded == '' then
        return
    end

    local ok, decoded = pcall(json.decode, encoded)
    if ok and type(decoded) == 'table' then
        characters = decoded
    end
end

local function saveCharacters()
    SaveResourceFile(GetCurrentResourceName(), SAVE_FILE, json.encode(characters), -1)
end

local function buildDefaultCharacter()
    local defaults = ExtractionCharacterConfig.defaults or {}

    return {
        callsign = defaults.callsign or 'Contractor',
        affiliation = defaults.affiliation or 'Unaffiliated',
        archetype = defaults.archetype or 'Recon',
        model = ExtractionCharacterConfig.defaultModel or 'mp_m_freemode_01',
        components = {},
        props = {},
    }
end

local function loadCharacter(identifier)
    local decoded = characters[getStorageKey(identifier)]
    if type(decoded) ~= 'table' then return nil end

    decoded.model = getAllowedModel(decoded.model)
    decoded.components = type(decoded.components) == 'table' and decoded.components or {}
    decoded.props = type(decoded.props) == 'table' and decoded.props or {}
    return decoded
end

local function saveCharacter(identifier, character)
    characters[getStorageKey(identifier)] = character
    saveCharacters()
end

local function getCharacter(source)
    local identifier = getIdentifier(source)
    local storageKey = getStorageKey(identifier)

    if not characters[storageKey] then
        characters[storageKey] = loadCharacter(identifier) or buildDefaultCharacter()
    end

    return characters[storageKey]
end

local function syncCharacterToLsx(source, character)
    if GetResourceState('lsx_core') ~= 'started' then
        return
    end

    local player = exports.lsx_core:GetPlayer(source)
    if not player then
        return
    end

    player.set('operatorName', character.callsign, false)
    player.set('callSign', character.callsign, false)
    player.set('archetype', character.archetype, false)
    player.set('affiliation', character.affiliation, false)
    player.set('model', character.model, true)
end

local function createOrUpdateCharacter(source, data)
    local identifier = getIdentifier(source)
    local current = getCharacter(source)
    local defaults = ExtractionCharacterConfig.defaults or {}

    current.callsign = tostring(data and data.callsign or current.callsign or defaults.callsign or 'Contractor'):sub(1, 24)
    current.affiliation = tostring(data and data.affiliation or current.affiliation or defaults.affiliation or 'Unaffiliated'):sub(1, 32)
    current.archetype = tostring(data and data.archetype or current.archetype or defaults.archetype or 'Recon'):sub(1, 24)
    current.model = getAllowedModel(data and data.model or current.model)
    current.components = type(current.components) == 'table' and current.components or {}
    current.props = type(current.props) == 'table' and current.props or {}

    saveCharacter(identifier, current)
    syncCharacterToLsx(source, current)

    TriggerClientEvent('extraction_character:client:apply', source, current)

    return current
end

RegisterNetEvent('extraction_character:server:requestCurrent', function()
    local character = getCharacter(source)
    syncCharacterToLsx(source, character)
    TriggerClientEvent('extraction_character:client:apply', source, character)
end)

RegisterNetEvent('extraction_character:server:createOrUpdate', function(data)
    createOrUpdateCharacter(source, type(data) == 'table' and data or {})
end)

exports('GetCharacter', function(source)
    return getCharacter(source)
end)

exports('CreateOrUpdateCharacter', function(source, data)
    return createOrUpdateCharacter(source, type(data) == 'table' and data or {})
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    loadCharacters()
end)
