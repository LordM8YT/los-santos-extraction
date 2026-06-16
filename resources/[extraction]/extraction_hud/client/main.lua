local hudHiddenComponents = {
    1,  -- Wanted stars
    2,  -- Weapon icon
    3,  -- Cash
    4,  -- MP cash
    5,  -- MP messages
    6,  -- Vehicle name
    7,  -- Area name
    8,  -- Vehicle class
    9,  -- Street name
    10, -- Native help text
    11, -- Floating help text
    12, -- Floating help text
    13, -- Cash change
    16, -- Radio stations
    17, -- Save game
    19, -- Weapon wheel
    20, -- Weapon stats
    21, -- HUD components
    22, -- HUD weapons
}

local raidState = {
    active = false,
    expiresAt = 0,
    carryValue = 0,
    carryWeight = 0,
    maxCarryWeight = 0,
}

local function shouldShowRadar()
    local config = ExtractionHudConfig and ExtractionHudConfig.Minimap or {}

    if config.enabled == false then
        return false
    end

    if config.showOnlyInRaid ~= false and not raidState.active then
        return false
    end

    if IsPedInAnyVehicle(PlayerPedId(), false) then
        return config.showInVehicle ~= false
    end

    return config.showOnFoot == true
end

local function applyMinimapCleanup(showRadar)
    local config = ExtractionHudConfig and ExtractionHudConfig.Minimap or {}

    DisplayRadar(showRadar)

    if config.forceSmallMap ~= false then
        SetRadarBigmapEnabled(false, false)
    end

    if config.hideNorthBlip ~= false then
        local northBlip = GetNorthRadarBlip()
        if northBlip and northBlip ~= 0 then
            SetBlipAlpha(northBlip, 0)
        end
    end

    if showRadar and config.zoom then
        SetRadarZoom(config.zoom)
    end
end

local function send(action, payload)
    SendNUIMessage({
        action = action,
        payload = payload or {}
    })
end

local function formatNumber(value)
    return tostring(math.floor(value or 0)):reverse():gsub('(%d%d%d)', '%1,'):reverse():gsub('^,', '')
end

local function updateRaidHud()
    if not raidState.active then
        send('raid', { active = false })
        return
    end

    local secondsLeft = math.max(0, math.floor((raidState.expiresAt - GetGameTimer()) / 1000))

    send('raid', {
        active = true,
        secondsLeft = secondsLeft,
        carryValue = raidState.carryValue,
        carryWeight = raidState.carryWeight,
        maxCarryWeight = raidState.maxCarryWeight,
        carryValueText = ('$%s'):format(formatNumber(raidState.carryValue)),
        carryWeightText = ('%s / %s'):format(formatNumber(raidState.carryWeight), formatNumber(raidState.maxCarryWeight)),
    })
end

RegisterNetEvent('extraction_hud:client:notify', function(message, variant)
    send('notify', {
        message = message,
        variant = variant or 'info',
    })
end)

RegisterNetEvent('extraction_hud:client:setHint', function(text)
    send('hint', {
        text = text or '',
    })
end)

RegisterNetEvent('extraction_hud:client:profile', function(profile)
    send('profile', profile or {})
end)

RegisterNetEvent('extraction_hud:client:progress', function(payload)
    send('progress', payload or {})
end)

RegisterNetEvent('standalone_extraction:client:startRaid', function(payload)
    raidState.active = true
    raidState.expiresAt = GetGameTimer() + ((payload.durationSeconds or 0) * 1000)
    raidState.carryValue = 0
    raidState.carryWeight = 0
    raidState.maxCarryWeight = payload.maxCarryWeight or 0
    updateRaidHud()
end)

RegisterNetEvent('standalone_extraction:client:updateCarry', function(payload)
    raidState.carryValue = payload.carryValue or raidState.carryValue
    raidState.carryWeight = payload.carryWeight or raidState.carryWeight
    raidState.maxCarryWeight = payload.maxCarryWeight or raidState.maxCarryWeight
    updateRaidHud()
end)

RegisterNetEvent('standalone_extraction:client:lootResult', function(payload)
    raidState.carryValue = payload.carryValue or raidState.carryValue
    raidState.carryWeight = payload.carryWeight or raidState.carryWeight
    raidState.maxCarryWeight = payload.maxCarryWeight or raidState.maxCarryWeight
    updateRaidHud()
end)

RegisterNetEvent('standalone_extraction:client:endRaid', function()
    raidState.active = false
    send('raid', { active = false })
    send('hint', { text = '' })
    send('progress', { active = false })
end)

CreateThread(function()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    send('boot', {})

    while true do
        for _, componentId in ipairs(hudHiddenComponents) do
            HideHudComponentThisFrame(componentId)
        end

        DisplayAmmoThisFrame(false)

        applyMinimapCleanup(shouldShowRadar())

        Wait(0)
    end
end)

CreateThread(function()
    while true do
        updateRaidHud()
        Wait(500)
    end
end)
