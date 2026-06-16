local RESOURCE_NAME = GetCurrentResourceName()
local SAVE_FILE = 'data/players.json'

local profiles = {}
local activeRaids = {}
local raidStartLocks = {}
local nextRaidId = 1
local extractionById = {}
local isPlayerNear

local function asVec3(coords)
    return vec3(coords.x, coords.y, coords.z)
end

local function buildLookups()
    for _, point in ipairs(Config.Extractions) do
        extractionById[point.id] = point
    end
end

local function notify(source, message)
    TriggerClientEvent('standalone_extraction:client:notify', source, message)
end

local function newLootBag()
    local bag = {}

    for itemName in pairs(Config.Items) do
        bag[itemName] = 0
    end

    return bag
end

local function defaultProfile()
    return {
        cash = 0,
        xp = 0,
        raids = 0,
        extractions = 0,
        deaths = 0,
        bestRunValue = 0,
        starterKitGranted = false,
        starterKitVersion = 0,
        stash = newLootBag(),
    }
end

local function grantStarterKit(profile)
    local starterKit = Config.StarterKit
    if not starterKit or not starterKit.enabled then
        return false
    end

    local changed = false
    local starterVersion = tonumber(starterKit.version) or 1

    if not profile.starterKitGranted then
        profile.cash = profile.cash + (tonumber(starterKit.cash) or 0)

        for itemName, count in pairs(starterKit.stash or {}) do
            if Config.Items[itemName] then
                profile.stash[itemName] = (tonumber(profile.stash[itemName]) or 0) + (tonumber(count) or 0)
            end
        end

        profile.starterKitGranted = true
        profile.starterKitVersion = starterVersion
        return true
    end

    if (tonumber(profile.starterKitVersion) or 0) < starterVersion then
        for itemName, count in pairs(starterKit.stash or {}) do
            local itemData = Config.Items[itemName]
            if itemData and (itemData.type == 'weapon' or itemData.type == 'ammo') then
                local current = tonumber(profile.stash[itemName]) or 0
                local minimum = tonumber(count) or 0
                if current < minimum then
                    profile.stash[itemName] = minimum
                    changed = true
                end
            end
        end

        profile.starterKitVersion = starterVersion
        changed = true
    end

    return changed
end

local function ensureProfileShape(profile)
    profile.cash = tonumber(profile.cash) or 0
    profile.xp = tonumber(profile.xp) or 0
    profile.raids = tonumber(profile.raids) or 0
    profile.extractions = tonumber(profile.extractions) or 0
    profile.deaths = tonumber(profile.deaths) or 0
    profile.bestRunValue = tonumber(profile.bestRunValue) or 0
    profile.starterKitVersion = tonumber(profile.starterKitVersion) or 0
    profile.stash = type(profile.stash) == 'table' and profile.stash or {}

    for itemName in pairs(Config.Items) do
        profile.stash[itemName] = tonumber(profile.stash[itemName]) or 0
    end

    return grantStarterKit(profile)
end

local function loadProfiles()
    local raw = LoadResourceFile(RESOURCE_NAME, SAVE_FILE)

    if raw and raw ~= '' then
        local decoded = json.decode(raw)
        profiles = type(decoded) == 'table' and decoded or {}
    else
        profiles = {}
    end

    for _, profile in pairs(profiles) do
        ensureProfileShape(profile)
    end
end

local function saveProfiles()
    SaveResourceFile(RESOURCE_NAME, SAVE_FILE, json.encode(profiles), -1)
end

local function getPrimaryIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    local preferredPrefixes = {
        'license:',
        'license2:',
        'fivem:',
        'steam:',
        'discord:',
    }

    for _, prefix in ipairs(preferredPrefixes) do
        for _, identifier in ipairs(identifiers) do
            if identifier:sub(1, #prefix) == prefix then
                return identifier
            end
        end
    end

    return identifiers[1]
end

local function getProfile(source)
    local identifier = getPrimaryIdentifier(source)
    if not identifier then
        return nil
    end

    local created = false
    if not profiles[identifier] then
        profiles[identifier] = defaultProfile()
        created = true
    end

    local grantedStarterKit = ensureProfileShape(profiles[identifier])
    if created or grantedStarterKit then
        saveProfiles()
    end

    return profiles[identifier], identifier
end

local function getLootValue(loot)
    local total = 0

    for itemName, itemData in pairs(Config.Items) do
        if itemData.type ~= 'weapon' and itemData.type ~= 'ammo' then
            total = total + ((tonumber(loot[itemName]) or 0) * itemData.value)
        end
    end

    return total
end

local function getLootWeight(loot)
    local total = 0

    for itemName, itemData in pairs(Config.Items) do
        total = total + ((tonumber(loot[itemName]) or 0) * itemData.weight)
    end

    return total
end

local function buildLootList(loot)
    local entries = {}

    for itemName, itemData in pairs(Config.Items) do
        local count = tonumber(loot[itemName]) or 0
        if count > 0 then
            entries[#entries + 1] = {
                name = itemName,
                label = itemData.label,
                type = itemData.type or 'loot',
                count = count,
                value = itemData.value,
                weight = itemData.weight,
            }
        end
    end

    table.sort(entries, function(a, b)
        return a.label < b.label
    end)

    return entries
end

local function getLevelFromXp(xp)
    return math.floor((xp or 0) / Config.Progression.xpPerLevel) + 1
end

local function buildProfileSnapshot(source)
    local profile = getProfile(source)
    if not profile then
        return nil
    end

    local raid = activeRaids[source]
    local carryLoot = raid and raid.carry or newLootBag()
    local sellDistance = isPlayerNear(source, Config.Lobby.trader.coords, Config.ValidationDistance + 2.0)

    return {
        cash = profile.cash,
        xp = profile.xp,
        level = getLevelFromXp(profile.xp),
        raids = profile.raids,
        extractions = profile.extractions,
        deaths = profile.deaths,
        bestRunValue = profile.bestRunValue,
        stash = buildLootList(profile.stash),
        stashValue = getLootValue(profile.stash),
        carry = buildLootList(carryLoot),
        carryValue = getLootValue(carryLoot),
        carryWeight = getLootWeight(carryLoot),
        maxCarryWeight = Config.Raid.maxCarryWeight,
        raidActive = raid ~= nil,
        canSell = sellDistance and raid == nil,
    }
end

local function sendInventorySnapshot(source, openUi)
    local eventName = openUi and 'standalone_extraction:client:openInventory' or 'standalone_extraction:client:updateInventory'
    TriggerClientEvent(eventName, source, buildProfileSnapshot(source))
end

local function addLoot(targetLoot, rewardLoot)
    for itemName in pairs(Config.Items) do
        targetLoot[itemName] = (tonumber(targetLoot[itemName]) or 0) + (tonumber(rewardLoot[itemName]) or 0)
    end
end

local function clearLoot(loot)
    for itemName in pairs(Config.Items) do
        loot[itemName] = 0
    end
end

local function clearSellableLoot(loot)
    for itemName, itemData in pairs(Config.Items) do
        if itemData.type ~= 'weapon' and itemData.type ~= 'ammo' then
            loot[itemName] = 0
        end
    end
end

local function getStarterLoadout(profile)
    local loadout = {}

    for itemName, itemData in pairs(Config.Items) do
        if itemData.type == 'weapon' and (tonumber(profile.stash[itemName]) or 0) > 0 then
            local ammoCount = 0
            if itemData.ammoItem then
                ammoCount = tonumber(profile.stash[itemData.ammoItem]) or 0
            end

            loadout[#loadout + 1] = {
                itemName = itemName,
                weapon = itemData.weapon,
                ammo = ammoCount,
            }
        end
    end

    return loadout
end

local function getRaid(source)
    return activeRaids[source]
end

local function getActiveRaidCount()
    local count = 0

    for _ in pairs(activeRaids) do
        count = count + 1
    end

    return count
end

isPlayerNear = function(source, coords, maxDistance)
    local ped = GetPlayerPed(source)
    if ped == 0 then
        return false
    end

    local playerCoords = GetEntityCoords(ped)
    return #(asVec3(playerCoords) - asVec3(coords)) <= maxDistance
end

local function chooseSpawnPoint()
    return Config.Raid.spawnPoints[math.random(1, #Config.Raid.spawnPoints)]
end

local function getWorldLootSpot(spotId)
    if GetResourceState('extraction_world') ~= 'started' then
        return nil
    end

    return exports.extraction_world:GetLootSpot(spotId)
end

local function hasWorldLootSpots()
    if GetResourceState('extraction_world') ~= 'started' then
        return false
    end

    local spots = exports.extraction_world:GetLootSpots()
    return type(spots) == 'table' and next(spots) ~= nil
end

local function rollLootItem(tier)
    local lootTable = Config.LootTables[tier] or Config.LootTables.low
    local totalWeight = 0

    for _, entry in ipairs(lootTable) do
        totalWeight = totalWeight + entry.weight
    end

    local roll = math.random() * totalWeight
    local running = 0

    for _, entry in ipairs(lootTable) do
        running = running + entry.weight
        if roll <= running then
            return entry.name
        end
    end

    return lootTable[#lootTable].name
end

local function cleanupRaid(source)
    activeRaids[source] = nil

    if GetPlayerName(source) then
        SetPlayerRoutingBucket(source, 0)
    end
end

local function endRaid(source, status, message)
    local profileSnapshot = buildProfileSnapshot(source)
    cleanupRaid(source)

    TriggerClientEvent('standalone_extraction:client:endRaid', source, {
        status = status,
        message = message,
        lobby = Config.Lobby.spawn,
        profile = profileSnapshot,
    })
end

RegisterNetEvent('standalone_extraction:server:joinRaid', function()
    local source = source

    if getRaid(source) then
        notify(source, Config.Strings.already_in_raid)
        return
    end

    if raidStartLocks[source] then
        notify(source, Config.Strings.raid_starting)
        return
    end

    if not hasWorldLootSpots() then
        notify(source, Config.Strings.no_loot_spots)
        return
    end

    if not isPlayerNear(source, Config.Lobby.join.coords, Config.ValidationDistance + 2.0) then
        return
    end

    raidStartLocks[source] = true

    local maxConcurrentRaids = tonumber(Config.Raid.maxConcurrentRaids) or 0
    if maxConcurrentRaids > 0 and getActiveRaidCount() >= maxConcurrentRaids then
        raidStartLocks[source] = nil
        notify(source, Config.Strings.too_many_active_raids)
        return
    end

    local profile = getProfile(source)
    if not profile then
        raidStartLocks[source] = nil
        notify(source, 'Could not find a valid player identifier.')
        return
    end

    if Config.Raid.entryFee > 0 then
        if profile.cash < Config.Raid.entryFee then
            raidStartLocks[source] = nil
            notify(source, ('You need $%s to start a raid.'):format(Config.Raid.entryFee))
            return
        end

        profile.cash = profile.cash - Config.Raid.entryFee
    end

    profile.raids = profile.raids + 1
    saveProfiles()

    local raidId = nextRaidId
    nextRaidId = nextRaidId + 1

    activeRaids[source] = {
        id = raidId,
        bucket = Config.Raid.bucketBase + raidId,
        startedAt = os.time(),
        expiresAt = os.time() + Config.Raid.durationSeconds,
        lootedSpots = {},
        carry = newLootBag(),
    }

    SetPlayerRoutingBucket(source, activeRaids[source].bucket)
    raidStartLocks[source] = nil

    TriggerClientEvent('standalone_extraction:client:startRaid', source, {
        raidId = raidId,
        spawn = chooseSpawnPoint(),
        durationSeconds = Config.Raid.durationSeconds,
        maxCarryWeight = Config.Raid.maxCarryWeight,
        loadout = getStarterLoadout(profile),
    })
end)

RegisterNetEvent('standalone_extraction:server:lootSpot', function(spotId)
    local source = source
    local raid = getRaid(source)

    if not raid then
        notify(source, Config.Strings.not_in_raid)
        return
    end

    local spot = getWorldLootSpot(spotId)
    if not spot then
        return
    end

    if raid.lootedSpots[spotId] then
        notify(source, 'This cache is already empty.')
        return
    end

    if not isPlayerNear(source, spot.coords, Config.ValidationDistance) then
        return
    end

    local itemName = rollLootItem(spot.tier)
    local itemData = Config.Items[itemName]
    local amount = math.random(itemData.min, itemData.max)
    local nextWeight = getLootWeight(raid.carry) + (amount * itemData.weight)

    if nextWeight > Config.Raid.maxCarryWeight then
        notify(source, Config.Strings.bag_full)
        return
    end

    raid.lootedSpots[spotId] = true
    raid.carry[itemName] = (raid.carry[itemName] or 0) + amount

    TriggerClientEvent('standalone_extraction:client:lootResult', source, {
        spotId = spotId,
        label = itemData.label,
        amount = amount,
        carry = buildLootList(raid.carry),
        carryValue = getLootValue(raid.carry),
        carryWeight = getLootWeight(raid.carry),
        maxCarryWeight = Config.Raid.maxCarryWeight,
    })

    sendInventorySnapshot(source, false)
end)

RegisterNetEvent('standalone_extraction:server:extract', function(extractId)
    local source = source
    local raid = getRaid(source)

    if not raid then
        notify(source, Config.Strings.not_in_raid)
        return
    end

    local extractPoint = extractionById[extractId]
    if not extractPoint then
        return
    end

    if not isPlayerNear(source, extractPoint.coords, Config.ValidationDistance + 1.0) then
        return
    end

    local profile = getProfile(source)
    if not profile then
        notify(source, 'Could not load your profile.')
        return
    end

    local runValue = getLootValue(raid.carry)
    if runValue <= 0 then
        notify(source, Config.Strings.no_loot_to_extract)
        return
    end

    addLoot(profile.stash, raid.carry)
    profile.extractions = profile.extractions + 1
    profile.xp = profile.xp + math.max(25, math.floor(runValue * Config.Progression.xpPerValue))
    profile.bestRunValue = math.max(profile.bestRunValue, runValue)

    clearLoot(raid.carry)
    saveProfiles()

    endRaid(source, 'extracted', Config.Strings.extracted)
end)

RegisterNetEvent('standalone_extraction:server:sellSecuredLoot', function()
    local source = source

    if getRaid(source) then
        notify(source, 'You cannot sell loot while you are in a raid.')
        return
    end

    if not isPlayerNear(source, Config.Lobby.trader.coords, Config.ValidationDistance + 2.0) then
        return
    end

    local profile = getProfile(source)
    if not profile then
        return
    end

    local stashValue = getLootValue(profile.stash)
    if stashValue <= 0 then
        notify(source, Config.Strings.no_secured_loot)
        return
    end

    clearSellableLoot(profile.stash)
    profile.cash = profile.cash + stashValue
    saveProfiles()

    notify(source, ('You sold secured loot for $%s.'):format(stashValue))
    TriggerClientEvent('standalone_extraction:client:showProfile', source, buildProfileSnapshot(source))
    sendInventorySnapshot(source, false)
end)

RegisterNetEvent('standalone_extraction:server:requestProfile', function()
    local source = source
    TriggerClientEvent('standalone_extraction:client:showProfile', source, buildProfileSnapshot(source))
end)

RegisterNetEvent('standalone_extraction:server:requestInventory', function(openUi)
    local source = source
    sendInventorySnapshot(source, openUi ~= false)
end)

RegisterNetEvent('standalone_extraction:server:discardCarryItem', function(itemName, amount)
    local source = source
    local raid = getRaid(source)

    if not raid then
        notify(source, Config.Strings.not_in_raid)
        return
    end

    local itemData = Config.Items[itemName]
    amount = math.floor(tonumber(amount) or 1)

    if not itemData or amount < 1 then
        return
    end

    local current = tonumber(raid.carry[itemName]) or 0
    if current < amount then
        notify(source, Config.Strings.nothing_to_drop)
        return
    end

    raid.carry[itemName] = current - amount
    notify(source, ('You dropped %sx %s.'):format(amount, itemData.label))

    TriggerClientEvent('standalone_extraction:client:updateCarry', source, {
        carry = buildLootList(raid.carry),
        carryValue = getLootValue(raid.carry),
        carryWeight = getLootWeight(raid.carry),
        maxCarryWeight = Config.Raid.maxCarryWeight,
    })

    sendInventorySnapshot(source, false)
end)

RegisterNetEvent('standalone_extraction:server:leaveRaid', function()
    local source = source
    local raid = getRaid(source)

    if not raid then
        notify(source, Config.Strings.not_in_raid)
        return
    end

    clearLoot(raid.carry)
    endRaid(source, 'left', Config.Strings.left_raid)
end)

RegisterNetEvent('standalone_extraction:server:playerDied', function()
    local source = source
    local raid = getRaid(source)
    if not raid then
        return
    end

    local profile = getProfile(source)
    if profile then
        profile.deaths = profile.deaths + 1
        saveProfiles()
    end

    clearLoot(raid.carry)
    endRaid(source, 'dead', Config.Strings.died)
end)

AddEventHandler('playerDropped', function()
    local source = source

    raidStartLocks[source] = nil

    if activeRaids[source] then
        cleanupRaid(source)
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= RESOURCE_NAME then
        return
    end

    buildLookups()
    loadProfiles()
    saveProfiles()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= RESOURCE_NAME then
        return
    end

    saveProfiles()

    for source in pairs(activeRaids) do
        cleanupRaid(source)
    end
end)

CreateThread(function()
    while true do
        local now = os.time()

        for source, raid in pairs(activeRaids) do
            if now >= raid.expiresAt then
                clearLoot(raid.carry)
                endRaid(source, 'timeout', Config.Strings.timed_out)
            end
        end

        Wait(5000)
    end
end)

CreateThread(function()
    while true do
        saveProfiles()
        Wait(300000)
    end
end)
