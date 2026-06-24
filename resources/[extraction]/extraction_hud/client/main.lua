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
    14, -- Reticle
    16, -- Radio stations
    17, -- Save game
    19, -- Weapon wheel
    20, -- Weapon stats
    21, -- HUD components
    22, -- HUD weapons
}

local nextMinimapEnforce = 0
local nextCameraEnforce = 0
local minimapScaleform
local send
local settingsKvpKey = 'extraction_hud:client_settings'
local combatViewConfig = ExtractionHudConfig and ExtractionHudConfig.CombatView or {}

local hudSettings = {
    minimapMode = 'always',
    hudDensity = 'full',
    firstPersonMode = combatViewConfig.defaultFirstPersonMode or 'raid',
    crosshairMode = combatViewConfig.defaultCrosshairMode or 'dynamic',
    helmetOverlay = combatViewConfig.defaultHelmetOverlay or 'on',
}

local raidState = {
    active = false,
    expiresAt = 0,
    carryValue = 0,
    carryWeight = 0,
    maxCarryWeight = 0,
}

local lastStatusPayload = ''
local previousPedCamViewMode

local function loadClientSettings()
    local encoded = GetResourceKvpString(settingsKvpKey)

    if not encoded or encoded == '' then
        return
    end

    local ok, decoded = pcall(json.decode, encoded)
    if not ok or type(decoded) ~= 'table' then
        return
    end

    hudSettings.minimapMode = decoded.minimapMode or hudSettings.minimapMode
    hudSettings.hudDensity = decoded.hudDensity or hudSettings.hudDensity
    hudSettings.firstPersonMode = decoded.firstPersonMode or hudSettings.firstPersonMode
    hudSettings.crosshairMode = decoded.crosshairMode or hudSettings.crosshairMode
    hudSettings.helmetOverlay = decoded.helmetOverlay or hudSettings.helmetOverlay
end

local function saveClientSettings()
    SetResourceKvp(settingsKvpKey, json.encode(hudSettings))
end

local function applyClientSettings(settings)
    if type(settings) ~= 'table' then
        return
    end

    if settings.minimapMode == 'vehicle' or settings.minimapMode == 'always' or settings.minimapMode == 'off' then
        hudSettings.minimapMode = settings.minimapMode
    end

    if settings.hudDensity == 'full' or settings.hudDensity == 'minimal' then
        hudSettings.hudDensity = settings.hudDensity
    end

    if settings.firstPersonMode == 'raid' or settings.firstPersonMode == 'off' then
        hudSettings.firstPersonMode = settings.firstPersonMode
    end

    if settings.crosshairMode == 'dynamic' or settings.crosshairMode == 'off' then
        hudSettings.crosshairMode = settings.crosshairMode
    end

    if settings.helmetOverlay == 'on' or settings.helmetOverlay == 'off' then
        hudSettings.helmetOverlay = settings.helmetOverlay
    end

    saveClientSettings()
    send('settings', hudSettings)
end

local function shouldShowCustomMinimap()
    local config = ExtractionHudConfig and ExtractionHudConfig.Minimap or {}

    if config.enabled == false then
        return false
    end

    if hudSettings.minimapMode == 'off' then
        return false
    end

    if config.showOnlyInRaid ~= false and not raidState.active then
        return false
    end

    if hudSettings.minimapMode == 'always' then
        return true
    end

    if IsPedInAnyVehicle(PlayerPedId(), false) then
        return config.showInVehicle ~= false
    end

    return config.showOnFoot == true
end

local function shouldShowNativeRadar()
    local config = ExtractionHudConfig and ExtractionHudConfig.Minimap or {}

    if config.useNativeRadar ~= true then
        return false
    end

    return shouldShowCustomMinimap()
end

local function applyMinimapCleanup(showRadar)
    local config = ExtractionHudConfig and ExtractionHudConfig.Minimap or {}
    local now = GetGameTimer()
    local shouldEnforce = now >= nextMinimapEnforce

    DisplayRadar(showRadar)

    if showRadar and config.hideNativeHealthArmor ~= false and minimapScaleform and HasScaleformMovieLoaded(minimapScaleform) then
        BeginScaleformMovieMethod(minimapScaleform, 'SETUP_HEALTH_ARMOUR')
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
    end

    if shouldEnforce then
        nextMinimapEnforce = now + (config.enforceIntervalMs or 500)

        if config.forceSmallMap ~= false then
            SetRadarBigmapEnabled(false, false)
        end
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

local function shouldForceFirstPerson()
    if hudSettings.firstPersonMode ~= 'raid' or not raidState.active then
        return false
    end

    local ped = PlayerPedId()

    return DoesEntityExist(ped)
        and not IsEntityDead(ped)
        and not IsPedInAnyVehicle(ped, false)
end

local function applyCombatCameraProfile()
    local config = ExtractionHudConfig and ExtractionHudConfig.CombatView or {}
    local now = GetGameTimer()

    if now < nextCameraEnforce then
        return
    end

    nextCameraEnforce = now + (config.firstPersonEnforceIntervalMs or 300)

    if shouldForceFirstPerson() and GetFollowPedCamViewMode() ~= 4 then
        SetFollowPedCamViewMode(4)
    end
end

function send(action, payload)
    SendNUIMessage({
        action = action,
        payload = payload or {}
    })
end

local function getHeadingCardinal(heading)
    local directions = { 'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW' }
    local index = math.floor(((heading + 22.5) % 360) / 45) + 1
    return directions[index] or 'N'
end

local function getPlayerStatus()
    local config = ExtractionHudConfig and ExtractionHudConfig.Minimap or {}
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash) or ''
    local crossingName = crossingHash and crossingHash ~= 0 and (GetStreetNameFromHashKey(crossingHash) or '') or ''
    local heading = GetGameplayCamRot(2).z

    if heading < 0 then
        heading = heading + 360
    end

    return {
        active = raidState.active,
        health = math.max(0, GetEntityHealth(ped) - 100),
        armor = GetPedArmour(ped),
        stamina = math.floor(GetPlayerSprintStaminaRemaining(PlayerId())),
        armed = IsPedArmed(ped, 4),
        aiming = IsPlayerFreeAiming(PlayerId()),
        sprinting = IsPedSprinting(ped),
        firstPerson = GetFollowPedCamViewMode() == 4,
        heading = math.floor(heading),
        cardinal = getHeadingCardinal(heading),
        location = streetName ~= '' and streetName or 'Unknown Sector',
        crossing = crossingName,
        inVehicle = IsPedInAnyVehicle(ped, false),
        speed = math.floor(GetEntitySpeed(ped) * 3.6),
        coords = {
            x = math.floor(coords.x),
            y = math.floor(coords.y),
            z = math.floor(coords.z),
        },
        minimapVisible = shouldShowCustomMinimap(),
        minimapRangeMeters = config.scannerRangeMeters or 220,
        combatView = {
            helmetOverlay = hudSettings.helmetOverlay == 'on',
            crosshairMode = hudSettings.crosshairMode,
            forceFirstPerson = shouldForceFirstPerson(),
        },
    }
end

local function updateStatusHud()
    local status = getPlayerStatus()
    local encoded = json.encode(status)

    if encoded == lastStatusPayload then
        return
    end

    lastStatusPayload = encoded
    send('status', status)
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
        density = hudSettings.hudDensity,
    })
end

RegisterNetEvent('extraction_hud:client:setSettings', function(settings)
    applyClientSettings(settings)
    updateRaidHud()
end)

RegisterNetEvent('extraction_hud:client:requestSettings', function()
    send('settings', hudSettings)
end)

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
    previousPedCamViewMode = GetFollowPedCamViewMode()
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

    if previousPedCamViewMode and previousPedCamViewMode ~= 4 and GetFollowPedCamViewMode() == 4 then
        SetFollowPedCamViewMode(previousPedCamViewMode)
    end

    previousPedCamViewMode = nil
end)

CreateThread(function()
    loadClientSettings()
    minimapScaleform = RequestScaleformMovie('minimap')
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    send('boot', {})
    send('settings', hudSettings)

    while true do
        for _, componentId in ipairs(hudHiddenComponents) do
            HideHudComponentThisFrame(componentId)
        end

        DisplayAmmoThisFrame(false)
        if HudWeaponWheelIgnoreSelection then
            HudWeaponWheelIgnoreSelection()
        end

        applyMinimapCleanup(shouldShowNativeRadar())
        applyCombatCameraProfile()

        Wait(0)
    end
end)

CreateThread(function()
    while true do
        updateRaidHud()
        Wait(500)
    end
end)

CreateThread(function()
    while true do
        updateStatusHud()
        Wait(250)
    end
end)
