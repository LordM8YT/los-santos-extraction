local uiOpen = false
local raidActive = false
local currentView = 'menu'
local activeExtractions = {}
local lootZones = {}
local deathSignals = {}
local nativeMapOpen = false
local nativeMapOpenedAt = 0

local mapBounds = {
    minX = -2800.0,
    maxX = 1900.0,
    minY = -3900.0,
    maxY = 1600.0,
}

local function send(action, payload)
    SendNUIMessage({
        action = action,
        payload = payload or {}
    })
end

local function coordsToPayload(coords)
    if type(coords) ~= 'vector3' and type(coords) ~= 'vector4' and type(coords) ~= 'table' then
        return nil
    end

    return {
        x = coords.x,
        y = coords.y,
        z = coords.z,
    }
end

local function normalizeExtractions(extractions)
    local normalized = {}

    for _, point in ipairs(extractions or {}) do
        local coords = coordsToPayload(point.coords)

        if coords then
            normalized[#normalized + 1] = {
                id = point.id or ('extract_' .. (#normalized + 1)),
                label = point.label or 'Extraction',
                coords = coords,
            }
        end
    end

    return normalized
end

local function normalizeLootZones(zones)
    local normalized = {}

    for _, zone in ipairs(zones or {}) do
        local center = coordsToPayload(zone.center)

        if center then
            normalized[#normalized + 1] = {
                id = zone.id or ('loot_zone_' .. (#normalized + 1)),
                label = zone.label or 'Loot Zone',
                tier = zone.tier or 'low',
                radius = zone.radius or 350.0,
                intel = zone.intel or '',
                center = center,
            }
        end
    end

    return normalized
end

local function addDeathSignal(payload)
    if not payload or not payload.coords then
        return
    end

    local coords = coordsToPayload(payload.coords)
    if not coords then
        return
    end

    local signalId = payload.id or ('death_signal_' .. GetGameTimer())

    deathSignals[signalId] = {
        id = signalId,
        coords = coords,
        value = payload.value or 0,
        expiresAt = GetGameTimer() + ((tonumber(payload.durationSeconds) or 75) * 1000),
    }
end

local function cleanupDeathSignals()
    local now = GetGameTimer()

    for signalId, signal in pairs(deathSignals) do
        if now >= signal.expiresAt then
            deathSignals[signalId] = nil
        end
    end
end

local function getDeathSignalPayload()
    cleanupDeathSignals()

    local signals = {}
    for _, signal in pairs(deathSignals) do
        signals[#signals + 1] = signal
    end

    return signals
end

local function refreshLootZones()
    if GetResourceState('extraction_world') ~= 'started' then
        lootZones = {}
        return
    end

    lootZones = normalizeLootZones(exports.extraction_world:GetLootZones() or {})
end

local function closePause()
    uiOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    send('close')
end

local function openNativeMap()
    closePause()
    nativeMapOpen = true
    nativeMapOpenedAt = GetGameTimer()
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    ActivateFrontendMenu(joaat('FE_MENU_VERSION_MP_PAUSE'), false, -1)

    if PauseMenuceptionGoDeeper then
        PauseMenuceptionGoDeeper(0)
    end
end

local function getMapPayload()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash) or ''
    local crossingName = crossingHash and crossingHash ~= 0 and (GetStreetNameFromHashKey(crossingHash) or '') or ''

    return {
        raidActive = raidActive,
        bounds = mapBounds,
        extractions = raidActive and activeExtractions or {},
        lootZones = raidActive and lootZones or {},
        deathSignals = raidActive and getDeathSignalPayload() or {},
        player = {
            x = coords.x,
            y = coords.y,
            z = coords.z,
            heading = heading,
            speed = math.floor(GetEntitySpeed(ped) * 3.6),
            location = streetName ~= '' and streetName or 'Unknown Sector',
            crossing = crossingName,
        }
    }
end

local function sendMapData()
    send('mapData', getMapPayload())
end

local function openPause(view)
    if uiOpen then
        currentView = view or currentView
        send('setView', { view = currentView })
        sendMapData()
        return
    end

    uiOpen = true
    currentView = view or 'menu'
    SetPauseMenuActive(false)
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    send('open', {
        view = currentView,
        map = getMapPayload(),
    })
end

RegisterCommand('extractionpause', function()
    openPause('menu')
end, false)

RegisterCommand('extractionmap', function()
    openNativeMap()
end, false)

RegisterKeyMapping('extractionmap', 'Open GTA tactical map', 'keyboard', 'M')

RegisterNUICallback('close', function(_, cb)
    closePause()
    cb({ ok = true })
end)

RegisterNUICallback('setView', function(data, cb)
    currentView = data and data.view or 'menu'
    send('setView', { view = currentView })

    if currentView == 'map' then
        sendMapData()
    end

    cb({ ok = true })
end)

RegisterNUICallback('openNativeMap', function(_, cb)
    openNativeMap()
    cb({ ok = true })
end)

RegisterNUICallback('openLobby', function(_, cb)
    closePause()
    TriggerEvent('extraction_lobby:client:open', 'deploy')
    cb({ ok = true })
end)

RegisterNUICallback('openInventory', function(_, cb)
    closePause()
    TriggerServerEvent('standalone_extraction:server:requestInventory', true)
    cb({ ok = true })
end)

RegisterNUICallback('leaveRaid', function(_, cb)
    closePause()
    TriggerServerEvent('standalone_extraction:server:leaveRaid')
    cb({ ok = true })
end)

RegisterNetEvent('standalone_extraction:client:startRaid', function(payload)
    raidActive = true
    activeExtractions = normalizeExtractions(payload and payload.extractions or {})
    refreshLootZones()
end)

RegisterNetEvent('standalone_extraction:client:endRaid', function()
    raidActive = false
    activeExtractions = {}
    deathSignals = {}
    closePause()
end)

RegisterNetEvent('standalone_extraction:client:deathSignal', function(payload)
    addDeathSignal(payload)

    if uiOpen and currentView == 'map' then
        sendMapData()
    end
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == 'extraction_world' then
        refreshLootZones()
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        closePause()
    end
end)

CreateThread(function()
    closePause()
    refreshLootZones()

    while true do
        if nativeMapOpen then
            if not IsPauseMenuActive() and GetGameTimer() - nativeMapOpenedAt > 750 then
                nativeMapOpen = false
            end

            Wait(0)
        else
            DisableControlAction(0, 199, true) -- Pause menu
            DisableControlAction(0, 200, true) -- ESC pause
            DisableControlAction(0, 244, true) -- Interaction/menu fallback

            if IsDisabledControlJustPressed(0, 199) or IsDisabledControlJustPressed(0, 200) then
                if uiOpen then
                    closePause()
                else
                    openPause('menu')
                end
            end

            if IsPauseMenuActive() then
                SetPauseMenuActive(false)
            end

            Wait(0)
        end
    end
end)

CreateThread(function()
    while true do
        if uiOpen and currentView == 'map' then
            sendMapData()
            Wait(500)
        else
            Wait(1000)
        end
    end
end)
