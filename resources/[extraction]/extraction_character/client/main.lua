local currentCharacter

local function requestModel(model)
    local hash = joaat(model)

    if not IsModelInCdimage(hash) or not IsModelValid(hash) then
        return false
    end

    RequestModel(hash)

    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(0)
    end

    if not HasModelLoaded(hash) then
        return false
    end

    SetPlayerModel(PlayerId(), hash)
    SetModelAsNoLongerNeeded(hash)
    return true
end

local function applyCharacter(character)
    currentCharacter = character or currentCharacter or {}

    local model = currentCharacter.model or ExtractionCharacterConfig.defaultModel
    requestModel(model)

    -- Component/prop customization will be applied here once the character creator UI exists.
end

RegisterNetEvent('extraction_character:client:apply', function(character)
    applyCharacter(character)
end)

RegisterNetEvent('extraction_character:client:requestCurrent', function()
    TriggerServerEvent('extraction_character:server:requestCurrent')
end)

exports('ApplyCharacter', applyCharacter)
exports('GetCurrentCharacter', function()
    return currentCharacter
end)
