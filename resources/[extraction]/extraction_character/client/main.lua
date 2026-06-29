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
    local ped = PlayerPedId()

    if currentCharacter.appearance and GetResourceState('illenium-appearance') == 'started' then
        pcall(function()
            exports['illenium-appearance']:setPlayerAppearance(currentCharacter.appearance)
        end)
        ped = PlayerPedId()
    end

    if DoesEntityExist(ped) then
        SetEntityVisible(ped, true, false)
        ResetEntityAlpha(ped)
        SetEntityCollision(ped, true, true)
    end

    -- Component/prop customization will be applied here once the character creator UI exists.
    TriggerEvent('extraction_character:client:applied', currentCharacter)
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
