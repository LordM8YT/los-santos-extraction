local raidState = {
    active = false,
    raidId = nil,
    lootedSpots = {},
    carry = {},
    carryValue = 0,
    carryWeight = 0,
    maxCarryWeight = Config.Raid.maxCarryWeight,
    expiresAt = 0,
    extractions = {},
    deathDrops = {},
}

local summaryPanel = {
    title = '',
    lines = {},
    visibleUntil = 0,
}

local extractionBlips = {}
local lootBlips = {}
local raidVehicles = {}
local interactionBusy = false
local deathReported = false
local lootSpots = {}
local hasHandledInitialSpawn = false
local spawnManagerConfigured = false
local lobbySpawnReady = false
local lobbyStagingActive = false
local lastHudHint = ''

local function asVec3(coords)
    return vec3(coords.x, coords.y, coords.z)
end

local function getDistance(fromCoords, toCoords)
    return #(asVec3(fromCoords) - asVec3(toCoords))
end

local function notify(message)
    if GetResourceState('extraction_hud') == 'started' then
        TriggerEvent('extraction_hud:client:notify', message, 'info')
        return
    end

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

local function setHudHint(text)
    text = text or ''

    if text == lastHudHint then
        return
    end

    lastHudHint = text

    if GetResourceState('extraction_hud') == 'started' then
        TriggerEvent('extraction_hud:client:setHint', text)
    end
end

local function refreshLootSpots()
    if GetResourceState('extraction_world') ~= 'started' then
        lootSpots = {}
        return
    end

    lootSpots = exports.extraction_world:GetLootSpots() or {}
end

local function formatNumber(value)
    local formatted = tostring(math.floor(value or 0))

    while true do
        local replaced, count = formatted:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
        formatted = replaced
        if count == 0 then
            break
        end
    end

    return formatted
end

local function requestAnimDict(dict)
    if HasAnimDictLoaded(dict) then
        return true
    end

    RequestAnimDict(dict)

    local timeout = GetGameTimer() + 5000
    while not HasAnimDictLoaded(dict) do
        if GetGameTimer() > timeout then
            return false
        end

        Wait(0)
    end

    return true
end

local function requestModel(model)
    local modelHash = type(model) == 'number' and model or joaat(model)

    if HasModelLoaded(modelHash) then
        return modelHash
    end

    RequestModel(modelHash)

    local timeout = GetGameTimer() + 5000
    while not HasModelLoaded(modelHash) do
        if GetGameTimer() > timeout then
            return nil
        end

        Wait(0)
    end

    return modelHash
end

local function drawText2D(x, y, scale, text, r, g, b, a, centered)
    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextCentre(centered or false)
    SetTextOutline()
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function drawHelpText(text)
    setHudHint(text)

    if GetResourceState('extraction_hud') == 'started' or text == '' then
        return
    end

    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, false, -1)
end

local function openLobbyUi(defaultView)
    if GetResourceState('extraction_lobby') ~= 'started' then
        return false
    end

    TriggerEvent('extraction_lobby:client:open', defaultView or 'deploy')
    return true
end

local function configureSpawnManager()
    if spawnManagerConfigured then
        return
    end

    spawnManagerConfigured = true

    if GetResourceState('spawnmanager') == 'started' then
        exports.spawnmanager:setAutoSpawn(false)
    end
end

local function setLobbyStaging(enabled)
    lobbyStagingActive = enabled

    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then
        return
    end

    FreezeEntityPosition(ped, enabled)
    SetEntityInvincible(ped, enabled)
    SetEntityVisible(ped, not enabled, false)
    SetEntityCollision(ped, not enabled, not enabled)
    SetPedCanSwitchWeapon(ped, not enabled)
    SetPlayerControl(PlayerId(), not enabled, 0)

    if enabled then
        ClearPedTasksImmediately(ped)
        SetCurrentPedWeapon(ped, joaat('WEAPON_UNARMED'), true)
    end
end

local function enforceLobbySafety()
    local ped = PlayerPedId()
    if not DoesEntityExist(ped) then
        return
    end

    SetEntityInvincible(ped, true)
    SetPlayerInvincible(PlayerId(), true)
    DisablePlayerFiring(PlayerId(), true)
    SetPedCanSwitchWeapon(ped, false)
    SetCurrentPedWeapon(ped, joaat('WEAPON_UNARMED'), true)

    DisableControlAction(0, 24, true) -- Attack
    DisableControlAction(0, 25, true) -- Aim
    DisableControlAction(0, 37, true) -- Weapon wheel
    DisableControlAction(0, 45, true) -- Reload
    DisableControlAction(0, 58, true) -- Alternate weapon
    DisableControlAction(0, 69, true) -- Vehicle attack
    DisableControlAction(0, 70, true) -- Vehicle attack 2
    DisableControlAction(0, 92, true) -- Vehicle passenger attack
    DisableControlAction(0, 114, true) -- Vehicle fly attack
    DisableControlAction(0, 140, true) -- Melee light
    DisableControlAction(0, 141, true) -- Melee heavy
    DisableControlAction(0, 142, true) -- Melee alternate
    DisableControlAction(0, 257, true) -- Attack 2
    DisableControlAction(0, 263, true) -- Melee attack 1
    DisableControlAction(0, 264, true) -- Melee attack 2
end

local function drawMarkerAt(coords, color, scaleMultiplier)
    local scale = Config.MarkerScale * (scaleMultiplier or 1.0)
    local markerCoords = asVec3(coords)

    DrawMarker(
        Config.MarkerType,
        markerCoords.x,
        markerCoords.y,
        markerCoords.z - 0.95,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        0.0,
        scale.x,
        scale.y,
        scale.z,
        color.r,
        color.g,
        color.b,
        color.a,
        false,
        false,
        2,
        false,
        nil,
        nil,
        false
    )
end

local function makeLootLookup(entries)
    local lookup = {}

    for _, entry in ipairs(entries or {}) do
        lookup[entry.name] = entry.count
    end

    return lookup
end

local function buildLootLines(entries, emptyText)
    local lines = {}

    for _, entry in ipairs(entries or {}) do
        lines[#lines + 1] = ('%s x%s  ($%s)'):format(entry.label, entry.count, formatNumber(entry.count * entry.value))
    end

    if #lines == 0 then
        lines[1] = emptyText
    end

    return lines
end

local function showSummaryPanel(title, lines, durationMs)
    summaryPanel.title = title
    summaryPanel.lines = lines
    summaryPanel.visibleUntil = GetGameTimer() + (durationMs or 10000)
end

local function showProfileSummary(profile)
    local lines = {
        ('Cash: $%s'):format(formatNumber(profile.cash)),
        ('XP / Level: %s / %s'):format(formatNumber(profile.xp), profile.level),
        ('Raids: %s | Extractions: %s | Deaths: %s'):format(profile.raids, profile.extractions, profile.deaths),
        ('Best run value: $%s'):format(formatNumber(profile.bestRunValue)),
        ('Secured stash value: $%s'):format(formatNumber(profile.stashValue)),
        '--- Stash ---',
    }

    for _, line in ipairs(buildLootLines(profile.stash, 'Empty stash')) do
        lines[#lines + 1] = line
    end

    if raidState.active then
        lines[#lines + 1] = '--- Carrying ---'

        for _, line in ipairs(buildLootLines(profile.carry, 'Empty bag')) do
            lines[#lines + 1] = line
        end
    end

    if GetResourceState('extraction_hud') == 'started' then
        TriggerEvent('extraction_hud:client:profile', {
            title = 'Extraction Profile',
            lines = lines,
            duration = 15000,
        })
    else
        showSummaryPanel('Extraction Profile', lines, 15000)
    end
end

local function cleanupRaidVehicles()
    for _, entry in ipairs(raidVehicles) do
        if entry.blip and DoesBlipExist(entry.blip) then
            RemoveBlip(entry.blip)
        end

        if entry.vehicle and DoesEntityExist(entry.vehicle) then
            DeleteEntity(entry.vehicle)
        end
    end

    raidVehicles = {}
end

local function resetRaidState()
    raidState.active = false
    raidState.raidId = nil
    raidState.lootedSpots = {}
    raidState.carry = {}
    raidState.carryValue = 0
    raidState.carryWeight = 0
    raidState.maxCarryWeight = Config.Raid.maxCarryWeight
    raidState.expiresAt = 0
    raidState.extractions = {}
    raidState.deathDrops = {}
    deathReported = false

    for _, blip in ipairs(extractionBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end

    extractionBlips = {}

    for _, blip in pairs(lootBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end

    lootBlips = {}
    cleanupRaidVehicles()
end

local function updateCarryState(payload)
    raidState.carry = makeLootLookup(payload.carry)
    raidState.carryValue = payload.carryValue or 0
    raidState.carryWeight = payload.carryWeight or 0
    raidState.maxCarryWeight = payload.maxCarryWeight or Config.Raid.maxCarryWeight
end

local function teleportTo(coords)
    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(ped, coords.w or GetEntityHeading(ped))
    Wait(200)

    DoScreenFadeIn(500)
end

local function moveToLobbySpawn()
    if not Config.Lobby.spawnOnJoin or raidState.active then
        return false
    end

    configureSpawnManager()
    lobbySpawnReady = false

    local spawn = Config.Lobby.spawn
    DoScreenFadeOut(0)

    local function finishLobbySpawn()
        local ped = PlayerPedId()
        SetEntityCoordsNoOffset(ped, spawn.x, spawn.y, spawn.z, false, false, false)
        SetEntityHeading(ped, spawn.w or 0.0)
        ClearPedTasksImmediately(ped)
        ClearPedBloodDamage(ped)
        SetEntityHealth(ped, 200)
        setLobbyStaging(true)
        lobbySpawnReady = true
        DoScreenFadeIn(500)
    end

    if GetResourceState('spawnmanager') == 'started' then
        exports.spawnmanager:spawnPlayer({
            x = spawn.x,
            y = spawn.y,
            z = spawn.z,
            heading = spawn.w or 0.0,
            model = Config.Lobby.stagingModel or 'mp_m_freemode_01',
            skipFade = true,
        }, finishLobbySpawn)
    else
        NetworkResurrectLocalPlayer(spawn.x, spawn.y, spawn.z, spawn.w or 0.0, true, false)
        finishLobbySpawn()
    end

    return true
end

local function openLobbyAfterFlyIn()
    if not Config.Lobby.openUiOnJoin or raidState.active then
        return
    end

    Wait(Config.Lobby.openUiDelay or 900)

    if raidState.active then
        return
    end

    local timeout = GetGameTimer() + 5000
    while not lobbySpawnReady and GetGameTimer() < timeout do
        Wait(50)
    end

    openLobbyUi('deploy')
end

local function resurrectAt(coords)
    local ped = PlayerPedId()

    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, coords.w or 0.0, true, false)
    ClearPedTasksImmediately(ped)
    ClearPedBloodDamage(ped)
    SetEntityHealth(ped, 200)
    SetEntityInvincible(ped, false)
end

local function applyRaidLoadout(loadout)
    if type(loadout) ~= 'table' then
        return
    end

    local ped = PlayerPedId()

    for _, entry in ipairs(loadout) do
        if entry.weapon then
            local weaponHash = joaat(entry.weapon)
            GiveWeaponToPed(ped, weaponHash, entry.ammo or 0, false, true)
            SetPedAmmo(ped, weaponHash, entry.ammo or 0)
            SetCurrentPedWeapon(ped, weaponHash, true)
        end
    end

    if #loadout > 0 then
        notify(Config.Strings.starter_weapon_given)
    end
end

local function createExtractionBlips()
    if not Config.EnableBlips then
        return
    end

    local mapConfig = Config.Map and Config.Map.extractionBlips or {}
    local activeExtractions = #raidState.extractions > 0 and raidState.extractions or Config.Extractions

    for _, point in ipairs(activeExtractions) do
        local coords = asVec3(point.coords)
        local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(blip, 356)
        SetBlipScale(blip, mapConfig.scale or 0.72)
        SetBlipColour(blip, 2)
        SetBlipAsShortRange(blip, mapConfig.shortRange == true)
        SetBlipRoute(blip, false)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(('Extract: %s'):format(point.label))
        EndTextCommandSetBlipName(blip)
        extractionBlips[#extractionBlips + 1] = blip
    end
end

local function getLootBlipColour(tier)
    if tier == 'high' then
        return 1
    end

    if tier == 'mid' then
        return 5
    end

    return 3
end

local function getLootBlipScale(tier)
    local mapConfig = Config.Map and Config.Map.lootBlips or {}

    if tier == 'high' then
        return mapConfig.highScale or 0.68
    end

    if tier == 'mid' then
        return mapConfig.midScale or 0.56
    end

    return mapConfig.lowScale or 0.48
end

local function isLootBlipShortRange(tier)
    local mapConfig = Config.Map and Config.Map.lootBlips or {}

    if tier == 'high' then
        return mapConfig.highShortRange == true
    end

    if tier == 'mid' then
        return mapConfig.midShortRange ~= false
    end

    return mapConfig.lowShortRange ~= false
end

local function createLootBlips()
    -- Hardcore rule: loot is never exposed on map/minimap. Physical props are the discovery layer.
end

local function removeLootBlip(spotId)
    local blip = lootBlips[spotId]
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end

    lootBlips[spotId] = nil
end

local function shouldSpawnRaidVehicle()
    local chance = tonumber(Config.RaidVehicles.spawnChance) or 1.0
    return chance >= 1.0 or math.random() <= chance
end

local function createRaidVehicleBlip(vehicle, definition)
    if not Config.RaidVehicles.showBlips then
        return nil
    end

    local mapConfig = Config.Map and Config.Map.vehicleBlips or {}
    local blip = AddBlipForEntity(vehicle)
    SetBlipSprite(blip, Config.RaidVehicles.blipSprite or 225)
    SetBlipScale(blip, mapConfig.scale or 0.54)
    SetBlipColour(blip, Config.RaidVehicles.blipColour or 38)
    SetBlipAsShortRange(blip, mapConfig.shortRange ~= false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(('Vehicle: %s'):format(definition.label or definition.id or 'Raid vehicle'))
    EndTextCommandSetBlipName(blip)

    return blip
end

local function spawnRaidVehicles()
    if not Config.RaidVehicles or not Config.RaidVehicles.enabled then
        return
    end

    cleanupRaidVehicles()

    for _, definition in ipairs(Config.RaidVehicles.spawns or {}) do
        if shouldSpawnRaidVehicle() then
            local modelHash = requestModel(definition.model)
            local coords = definition.coords

            if modelHash and coords then
                local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, coords.w or 0.0, true, false)

                if vehicle ~= 0 then
                    SetEntityAsMissionEntity(vehicle, true, true)
                    SetVehicleOnGroundProperly(vehicle)
                    SetVehicleDoorsLocked(vehicle, 1)
                    SetVehicleDirtLevel(vehicle, 8.0)
                    SetVehicleEngineHealth(vehicle, math.random(720, 980) + 0.0)
                    SetVehicleFuelLevel(vehicle, math.random(38, 88) + 0.0)
                    SetVehRadioStation(vehicle, 'OFF')

                    raidVehicles[#raidVehicles + 1] = {
                        vehicle = vehicle,
                        blip = createRaidVehicleBlip(vehicle, definition),
                    }
                end

                SetModelAsNoLongerNeeded(modelHash)
            end
        end
    end
end

local function createLobbyBlips()
    if not Config.EnableBlips then
        return
    end

    local blip = AddBlipForCoord(Config.Lobby.join.coords.x, Config.Lobby.join.coords.y, Config.Lobby.join.coords.z)
    SetBlipSprite(blip, 568)
    SetBlipScale(blip, 0.9)
    SetBlipColour(blip, 3)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Extraction Hub')
    EndTextCommandSetBlipName(blip)

    local traderBlip = AddBlipForCoord(Config.Lobby.trader.coords.x, Config.Lobby.trader.coords.y, Config.Lobby.trader.coords.z)
    SetBlipSprite(traderBlip, 500)
    SetBlipScale(traderBlip, 0.8)
    SetBlipColour(traderBlip, 2)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Extraction Trader')
    EndTextCommandSetBlipName(traderBlip)
end

local function progressAction(label, duration, animDict, animClip)
    local ped = PlayerPedId()
    local startedAt = GetGameTimer()
    local endsAt = startedAt + duration
    interactionBusy = true
    local nextHudUpdate = 0

    if animDict and animClip and requestAnimDict(animDict) then
        TaskPlayAnim(ped, animDict, animClip, 2.0, 2.0, duration, 49, 0.0, false, false, false)
    end

    FreezeEntityPosition(ped, true)
    TriggerEvent('extraction_hud:client:progress', {
        active = true,
        label = label,
        percent = 0,
    })

    while GetGameTimer() < endsAt do
        if IsEntityDead(ped) then
            break
        end

        DisableAllControlActions(0)
        EnableControlAction(0, 249, true)
        EnableControlAction(0, 245, true)

        local progress = math.floor(((GetGameTimer() - startedAt) / duration) * 100.0)
        if GetGameTimer() >= nextHudUpdate then
            TriggerEvent('extraction_hud:client:progress', {
                active = true,
                label = label,
                percent = progress,
            })
            nextHudUpdate = GetGameTimer() + 90
        end

        if IsControlJustReleased(0, Config.CancelControl) then
            ClearPedTasksImmediately(ped)
            FreezeEntityPosition(ped, false)
            interactionBusy = false
            TriggerEvent('extraction_hud:client:progress', { active = false })
            notify(Config.Strings.cancelled)
            return false
        end

        Wait(0)
    end

    ClearPedTasks(ped)
    FreezeEntityPosition(ped, false)
    interactionBusy = false
    TriggerEvent('extraction_hud:client:progress', { active = false })

    return not IsEntityDead(ped)
end

local function getExtractionHoldDuration()
    local extractionConfig = SessionConfig and SessionConfig.Extractions or {}
    return math.max(1000, tonumber(extractionConfig.zoneHoldMs) or tonumber(Config.Raid.extractionTime) or 10000)
end

local function runExtractionZone(extractPoint)
    local holdDuration = getExtractionHoldDuration()
    local zoneRadius = tonumber(extractPoint.radius) or tonumber(Config.ValidationDistance) or 6.0
    local startedAt = GetGameTimer()
    local nextHudUpdate = 0

    interactionBusy = true

    while raidState.active do
        local ped = PlayerPedId()
        if IsEntityDead(ped) then
            notify('Extraction failed. You died before evac arrived.')
            break
        end

        local elapsed = GetGameTimer() - startedAt
        local remainingSeconds = math.max(0, math.ceil((holdDuration - elapsed) / 1000))
        local playerCoords = GetEntityCoords(ped)

        if getDistance(playerCoords, extractPoint.coords) > zoneRadius then
            notify('Extraction cancelled. Stay inside the extraction zone.')
            break
        end

        drawMarkerAt(extractPoint.coords, extractPoint.color, 1.25)
        drawHelpText(('Extraction arriving in %ss'):format(remainingSeconds))

        if GetGameTimer() >= nextHudUpdate then
            TriggerEvent('extraction_hud:client:progress', {
                active = true,
                label = ('Holding extraction zone: %s'):format(extractPoint.label),
                percent = math.min(100, math.floor((elapsed / holdDuration) * 100.0)),
            })

            nextHudUpdate = GetGameTimer() + 90
        end

        if elapsed >= holdDuration then
            TriggerServerEvent('standalone_extraction:server:extract', extractPoint.id)
            interactionBusy = false
            TriggerEvent('extraction_hud:client:progress', { active = false })
            drawHelpText('')
            return true
        end

        Wait(0)
    end

    interactionBusy = false
    TriggerEvent('extraction_hud:client:progress', { active = false })
    drawHelpText('')
    return false
end

RegisterNetEvent('standalone_extraction:client:notify', function(message)
    notify(message)
end)

RegisterNetEvent('standalone_extraction:client:startRaid', function(payload)
    resetRaidState()
    refreshLootSpots()

    raidState.active = true
    raidState.raidId = payload.raidId
    raidState.expiresAt = GetGameTimer() + ((payload.durationSeconds or Config.Raid.durationSeconds) * 1000)
    raidState.maxCarryWeight = payload.maxCarryWeight or Config.Raid.maxCarryWeight
    raidState.extractions = payload.extractions or {}
    raidState.deathDrops = payload.deathDrops or {}

    setLobbyStaging(false)
    createExtractionBlips()
    CreateThread(spawnRaidVehicles)
    teleportTo(payload.spawn)
    applyRaidLoadout(payload.loadout)
    notify(('Raid started. %s loot caches are active across the city.'):format(#lootSpots))
end)

RegisterNetEvent('standalone_extraction:client:lootResult', function(payload)
    raidState.lootedSpots[payload.spotId] = true
    removeLootBlip(payload.spotId)
    updateCarryState(payload)
    notify(('+%sx %s'):format(payload.amount, payload.label))
end)

RegisterNetEvent('standalone_extraction:client:lootSpotEmptied', function(payload)
    if not payload or not payload.spotId then
        return
    end

    raidState.lootedSpots[payload.spotId] = true
    removeLootBlip(payload.spotId)
end)

RegisterNetEvent('standalone_extraction:client:updateCarry', function(payload)
    updateCarryState(payload)
end)

RegisterNetEvent('standalone_extraction:client:updateDeathDrops', function(payload)
    raidState.deathDrops = payload and payload.drops or {}
end)

RegisterNetEvent('standalone_extraction:client:showProfile', function(profile)
    showProfileSummary(profile)
end)

RegisterNetEvent('standalone_extraction:client:lobbyClosedByUser', function()
    if not lobbyStagingActive or raidState.active then
        return
    end

    CreateThread(function()
        Wait(150)
        if lobbyStagingActive and not raidState.active then
            openLobbyUi('deploy')
        end
    end)
end)

RegisterNetEvent('standalone_extraction:client:endRaid', function(payload)
    if payload.status == 'dead' then
        Wait(Config.Raid.deathRespawnDelay)
        resurrectAt(payload.lobby)
    end

    teleportTo(payload.lobby)
    resetRaidState()
    setLobbyStaging(true)

    if payload.message and payload.message ~= '' then
        notify(payload.message)
    end

    if payload.profile then
        showProfileSummary(payload.profile)
    end

    openLobbyAfterFlyIn()
end)

AddEventHandler('playerSpawned', function()
    if hasHandledInitialSpawn then
        return
    end

    hasHandledInitialSpawn = true

    CreateThread(function()
        Wait(Config.Lobby.spawnDelay or 1500)
        if moveToLobbySpawn() then
            openLobbyAfterFlyIn()
        end
    end)
end)

RegisterCommand('extractstats', function()
    TriggerServerEvent('standalone_extraction:server:requestProfile')
end, false)

RegisterCommand('raidleave', function()
    if not raidState.active then
        notify(Config.Strings.not_in_raid)
        return
    end

    TriggerServerEvent('standalone_extraction:server:leaveRaid')
end, false)

RegisterCommand('raidbag', function()
    TriggerServerEvent('standalone_extraction:server:requestProfile')
end, false)

CreateThread(function()
    configureSpawnManager()
    refreshLootSpots()
    createLobbyBlips()

    Wait((Config.Lobby.spawnDelay or 1500) + 1000)

    if not hasHandledInitialSpawn and NetworkIsPlayerActive(PlayerId()) then
        hasHandledInitialSpawn = true
        if moveToLobbySpawn() then
            openLobbyAfterFlyIn()
        end
    end
end)

CreateThread(function()
    while true do
        if raidState.active then
            local ped = PlayerPedId()
            if DoesEntityExist(ped) then
                SetPedCanSwitchWeapon(ped, true)
            end

            SetPlayerInvincible(PlayerId(), false)
            Wait(1000)
        else
            enforceLobbySafety()
            Wait(0)
        end
    end
end)

CreateThread(function()
    while true do
        if summaryPanel.visibleUntil > GetGameTimer() then
            local x = 0.78
            local y = 0.18
            local width = 0.2
            local height = 0.03 + (#summaryPanel.lines * 0.022)

            DrawRect(x, y + (height / 2.0), width, height, 10, 14, 18, 205)
            drawText2D(x - 0.09, y + 0.008, 0.37, summaryPanel.title, 255, 255, 255, 235, false)

            for index, line in ipairs(summaryPanel.lines) do
                drawText2D(x - 0.09, y + 0.01 + (index * 0.021), 0.29, line, 220, 220, 220, 225, false)
            end

            Wait(0)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        if raidState.active and GetResourceState('extraction_hud') ~= 'started' then
            local secondsLeft = math.max(0, math.floor((raidState.expiresAt - GetGameTimer()) / 1000))
            local minutes = math.floor(secondsLeft / 60)
            local seconds = secondsLeft % 60
            local timerText = ('Raid  %02d:%02d'):format(minutes, seconds)
            local bagText = ('Bag value: $%s  |  Weight: %s/%s'):format(
                formatNumber(raidState.carryValue),
                formatNumber(raidState.carryWeight),
                formatNumber(raidState.maxCarryWeight)
            )

            DrawRect(0.5, 0.05, 0.24, 0.05, 8, 12, 16, 180)
            drawText2D(0.5, 0.036, 0.38, timerText, 255, 255, 255, 230, true)
            drawText2D(0.5, 0.058, 0.28, bagText, 205, 235, 255, 220, true)
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    while true do
        if interactionBusy then
            Wait(250)
        else
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)
            local nearestAction
            local sleep = 1000

            if raidState.active then
                for _, spot in ipairs(lootSpots) do
                    if not raidState.lootedSpots[spot.id] then
                        local distance = getDistance(playerCoords, spot.coords)

                        if distance < 12.0 then
                            sleep = 150
                        end

                        if distance < Config.InteractDistance and (not nearestAction or distance < nearestAction.distance) then
                            nearestAction = {
                                distance = distance,
                                label = ('[E] Search %s'):format(spot.label),
                                action = 'loot',
                                id = spot.id
                            }
                        end
                    end
                end

                local activeExtractions = #raidState.extractions > 0 and raidState.extractions or Config.Extractions
                for _, extractPoint in ipairs(activeExtractions) do
                    local distance = getDistance(playerCoords, extractPoint.coords)

                    if distance < Config.DrawDistance then
                        sleep = 0
                        drawMarkerAt(extractPoint.coords, extractPoint.color, 1.15)

                        if distance < Config.InteractDistance and (not nearestAction or distance < nearestAction.distance) then
                            nearestAction = {
                                distance = distance,
                                label = ('[E] Call extraction at %s'):format(extractPoint.label),
                                action = 'extract',
                                id = extractPoint.id,
                                point = extractPoint,
                            }
                        end
                    end
                end

                for _, drop in ipairs(raidState.deathDrops or {}) do
                    local distance = getDistance(playerCoords, drop.coords)

                    if distance < 12.0 then
                        sleep = 150
                    end

                    if distance < Config.InteractDistance and (not nearestAction or distance < nearestAction.distance) then
                        nearestAction = {
                            distance = distance,
                            label = ('[E] Recover death drop ($%s)'):format(formatNumber(drop.value)),
                            action = 'deathdrop',
                            id = drop.id,
                        }
                    end
                end
            elseif Config.Lobby.worldActionsEnabled then
                local lobbyActions = {
                    {
                        id = 'join',
                        label = ('[E] %s'):format(Config.Lobby.join.label),
                        coords = Config.Lobby.join.coords,
                        color = Config.Lobby.join.color,
                    },
                    {
                        id = 'sell',
                        label = ('[E] %s'):format(Config.Lobby.trader.label),
                        coords = Config.Lobby.trader.coords,
                        color = Config.Lobby.trader.color,
                    },
                    {
                        id = 'stats',
                        label = ('[E] %s'):format(Config.Lobby.stats.label),
                        coords = Config.Lobby.stats.coords,
                        color = Config.Lobby.stats.color,
                    }
                }

                for _, action in ipairs(lobbyActions) do
                    local distance = getDistance(playerCoords, action.coords)

                    if distance < Config.DrawDistance then
                        sleep = 0
                        drawMarkerAt(action.coords, action.color, 1.0)

                        if distance < Config.InteractDistance and (not nearestAction or distance < nearestAction.distance) then
                            nearestAction = {
                                distance = distance,
                                label = action.label,
                                action = action.id,
                            }
                        end
                    end
                end
            end

            if nearestAction then
                drawHelpText(nearestAction.label)

                if IsControlJustReleased(0, Config.InteractControl) then
                    if nearestAction.action == 'join' then
                        if not openLobbyUi('deploy') then
                            TriggerServerEvent('standalone_extraction:server:joinRaid')
                        end
                    elseif nearestAction.action == 'sell' then
                        if not openLobbyUi('trader') then
                            TriggerServerEvent('standalone_extraction:server:sellSecuredLoot')
                        end
                    elseif nearestAction.action == 'stats' then
                        if not openLobbyUi('profile') then
                            TriggerServerEvent('standalone_extraction:server:requestProfile')
                        end
                    elseif nearestAction.action == 'loot' then
                        if GetResourceState('extraction_world') == 'started' and exports.extraction_world:HasActiveGuardThreat(nearestAction.id) then
                            notify(Config.Strings.area_hot)
                            Wait(500)
                        else
                            local finished = progressAction(Config.Strings.loot_progress, Config.Raid.lootTime, 'amb@prop_human_bum_bin@base', 'base')

                            if finished then
                                TriggerServerEvent('standalone_extraction:server:lootSpot', nearestAction.id)
                            end
                        end
                    elseif nearestAction.action == 'extract' then
                        runExtractionZone(nearestAction.point)
                    elseif nearestAction.action == 'deathdrop' then
                        local finished = progressAction('Recovering death drop', Config.Raid.lootTime, 'amb@prop_human_bum_bin@base', 'base')

                        if finished then
                            TriggerServerEvent('standalone_extraction:server:lootDeathDrop', nearestAction.id)
                        end
                    end
                end
            else
                drawHelpText('')
            end

            Wait(sleep)
        end
    end
end)

CreateThread(function()
    while true do
        if raidState.active then
            local ped = PlayerPedId()

            if IsEntityDead(ped) and not deathReported then
                deathReported = true
                TriggerServerEvent('standalone_extraction:server:playerDied')
            elseif not IsEntityDead(ped) and deathReported then
                deathReported = false
            end

            Wait(400)
        else
            deathReported = false
            Wait(1000)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    resetRaidState()
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == 'extraction_world' or resourceName == GetCurrentResourceName() then
        refreshLootSpots()
    end
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName == 'extraction_world' then
        lootSpots = {}
    end
end)
