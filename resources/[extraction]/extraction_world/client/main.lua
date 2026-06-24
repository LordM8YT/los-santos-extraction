local raidActive = false
local spawnedProps = {}
local spawnedGuards = {}
local lootSpotsById = {}
local guardZonesById = {}
local relationshipGroupHash = 0

local function buildLookups()
    lootSpotsById = {}
    guardZonesById = {}

    for _, spot in ipairs(WorldConfig.LootSpots) do
        lootSpotsById[spot.id] = spot
    end

    for _, zone in ipairs(WorldConfig.GuardZones) do
        guardZonesById[zone.id] = zone
    end
end

local function loadModel(model)
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

local function ensureRelationshipGroup()
    if relationshipGroupHash ~= 0 then
        return relationshipGroupHash
    end

    AddRelationshipGroup('EXTRACTION_GUARDS')
    relationshipGroupHash = GetHashKey('EXTRACTION_GUARDS')
    SetRelationshipBetweenGroups(5, relationshipGroupHash, joaat('PLAYER'))
    SetRelationshipBetweenGroups(5, joaat('PLAYER'), relationshipGroupHash)

    return relationshipGroupHash
end

local function isGuardAlive(guard)
    return guard and DoesEntityExist(guard) and not IsPedDeadOrDying(guard, true)
end

local function cleanupWorld()
    for _, entity in pairs(spawnedProps) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end

    for _, guards in pairs(spawnedGuards) do
        for _, guard in ipairs(guards) do
            if DoesEntityExist(guard) then
                DeleteEntity(guard)
            end
        end
    end

    spawnedProps = {}
    spawnedGuards = {}
end

local function spawnLootProp(spot)
    if spawnedProps[spot.id] then
        return
    end

    local modelHash = loadModel(spot.model)
    if not modelHash then
        return
    end

    local entity = CreateObjectNoOffset(modelHash, spot.coords.x, spot.coords.y, spot.coords.z, false, false, false)
    if entity == 0 then
        return
    end

    SetEntityHeading(entity, spot.heading or 0.0)
    PlaceObjectOnGroundProperly(entity)
    FreezeEntityPosition(entity, true)
    SetEntityAsMissionEntity(entity, true, true)

    spawnedProps[spot.id] = entity
    SetModelAsNoLongerNeeded(modelHash)
end

local function configureGuardPed(ped, definition)
    SetPedAsEnemy(ped, true)
    SetPedDropsWeaponsWhenDead(ped, false)
    SetPedAccuracy(ped, definition.accuracy or 45)
    SetPedCombatAbility(ped, 2)
    SetPedCombatRange(ped, 2)
    SetPedCombatMovement(ped, 2)
    SetPedAlertness(ped, 3)
    SetPedSeeingRange(ped, 100.0)
    SetPedHearingRange(ped, 90.0)
    SetPedArmour(ped, definition.armor or 50)
    SetEntityHealth(ped, definition.health or 200)
    SetPedRelationshipGroupHash(ped, ensureRelationshipGroup())
    GiveWeaponToPed(ped, joaat(definition.weapon or 'WEAPON_SMG'), 999, false, true)
    SetCurrentPedWeapon(ped, joaat(definition.weapon or 'WEAPON_SMG'), true)
    SetPedCanRagdoll(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 0, true)
    SetPedCombatAttributes(ped, 3, true)
    SetPedCombatAttributes(ped, 5, true)
    SetPedCombatAttributes(ped, 46, true)
    SetPedSuffersCriticalHits(ped, false)
    TaskGuardCurrentPosition(ped, 15.0, 15.0, true)
end

local function spawnGuardZone(zone)
    if spawnedGuards[zone.id] then
        return
    end

    spawnedGuards[zone.id] = {}

    for _, definition in ipairs(zone.guards) do
        local modelHash = loadModel(definition.model)
        if modelHash then
            local ped = CreatePed(30, modelHash, definition.coords.x, definition.coords.y, definition.coords.z - 1.0, definition.coords.w, false, false)
            if ped ~= 0 then
                SetEntityAsMissionEntity(ped, true, true)
                configureGuardPed(ped, definition)
                spawnedGuards[zone.id][#spawnedGuards[zone.id] + 1] = ped
            end

            SetModelAsNoLongerNeeded(modelHash)
        end
    end
end

local function spawnWorld()
    cleanupWorld()

    for _, spot in ipairs(WorldConfig.LootSpots) do
        spawnLootProp(spot)
    end

    for _, zone in ipairs(WorldConfig.GuardZones) do
        spawnGuardZone(zone)
    end
end

local function drawCrateGlow(playerCoords)
    local glow = WorldConfig.CrateGlow
    if not glow or not glow.enabled then
        return false
    end

    local maxDistance = glow.maxDistance or 26.0
    local maxDistanceSquared = maxDistance * maxDistance
    local zOffset = glow.zOffset or 0.35
    local range = glow.range or 1.45
    local intensity = glow.intensity or 0.22
    local pulse = glow.pulse or 0.0
    local pulseValue = pulse > 0.0 and (math.sin(GetGameTimer() * 0.003) * pulse) or 0.0
    local drewGlow = false

    for spotId, entity in pairs(spawnedProps) do
        if DoesEntityExist(entity) then
            local spot = lootSpotsById[spotId]
            local coords = GetEntityCoords(entity)
            local dx = playerCoords.x - coords.x
            local dy = playerCoords.y - coords.y
            local dz = playerCoords.z - coords.z
            local distanceSquared = dx * dx + dy * dy + dz * dz

            if distanceSquared <= maxDistanceSquared then
                local color = (spot and spot.color) or WorldConfig.TierColors.low
                DrawLightWithRange(
                    coords.x,
                    coords.y,
                    coords.z + zOffset,
                    color.r or 120,
                    color.g or 190,
                    color.b or 255,
                    range,
                    math.max(0.01, intensity + pulseValue)
                )

                drewGlow = true
            end
        end
    end

    return drewGlow
end

local function hasActiveGuardThreat(spotId)
    local spot = lootSpotsById[spotId]
    if not spot or not spot.guardZoneId then
        return false
    end

    local guards = spawnedGuards[spot.guardZoneId]
    if not guards then
        return false
    end

    for _, guard in ipairs(guards) do
        if isGuardAlive(guard) then
            return true
        end
    end

    return false
end

exports('GetLootSpots', function()
    return WorldConfig.LootSpots
end)

exports('GetLootZones', function()
    return WorldConfig.LootZones or {}
end)

exports('GetLootSpot', function(spotId)
    return lootSpotsById[spotId]
end)

exports('HasActiveGuardThreat', function(spotId)
    return hasActiveGuardThreat(spotId)
end)

RegisterNetEvent('standalone_extraction:client:startRaid', function()
    raidActive = true
    spawnWorld()
end)

RegisterNetEvent('standalone_extraction:client:lootResult', function(payload)
    local entity = spawnedProps[payload.spotId]
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end

    spawnedProps[payload.spotId] = nil
end)

RegisterNetEvent('standalone_extraction:client:lootSpotEmptied', function(payload)
    local spotId = payload and payload.spotId
    local entity = spotId and spawnedProps[spotId]

    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end

    if spotId then
        spawnedProps[spotId] = nil
    end
end)

RegisterNetEvent('standalone_extraction:client:endRaid', function()
    raidActive = false
    cleanupWorld()
end)

CreateThread(function()
    buildLookups()
end)

CreateThread(function()
    while true do
        if raidActive and next(spawnedProps) then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local drewGlow = drawCrateGlow(playerCoords)

            Wait(drewGlow and 0 or 450)
        else
            Wait(1000)
        end
    end
end)

CreateThread(function()
    while true do
        if raidActive then
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)
            local sleep = 500

            for zoneId, guards in pairs(spawnedGuards) do
                local zone = guardZonesById[zoneId]
                local withinAggro = zone and (#(playerCoords - zone.center) <= (zone.aggroRange or WorldConfig.GuardAggroRange))

                for _, guard in ipairs(guards) do
                    if isGuardAlive(guard) then
                        sleep = 0

                        if withinAggro or HasEntityBeenDamagedByEntity(guard, ped, true) or IsPedInCombat(guard, ped) then
                            if not IsPedInCombat(guard, ped) then
                                TaskCombatPed(guard, ped, 0, 16)
                            end
                        elseif not IsPedInAnyVehicle(guard, false) and not IsPedInCombat(guard, ped) then
                            TaskGuardCurrentPosition(guard, 12.0, 12.0, true)
                        end
                    end
                end
            end

            Wait(sleep)
        else
            Wait(1000)
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    cleanupWorld()
end)
