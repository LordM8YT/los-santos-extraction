local lootSpotsById = {}
local guardZonesById = {}

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

exports('GetLootSpots', function()
    return WorldConfig.LootSpots
end)

exports('GetLootSpot', function(spotId)
    return lootSpotsById[spotId]
end)

exports('GetGuardZone', function(zoneId)
    return guardZonesById[zoneId]
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    buildLookups()
end)
