local RESOURCE_NAME = GetCurrentResourceName()
local SAVE_FILE = 'data/players.json'

local profiles = {}
local activeRaids = {}
local activeSessions = {}
local queuedPlayers = {}
local queuedLookup = {}
local raidStartLocks = {}
local nextRaidId = 1
local nextDropId = 1
local extractionById = {}
local isPlayerNear

local QUEST_DEFINITIONS = {
    {
        id = 'first_blood_sample',
        title = 'First Blood Sample',
        description = 'Secure medical supplies and deliver them to the safehouse.',
        requiredItem = 'meds',
        requiredCount = 1,
        rewards = {
            cash = 750,
            xp = 150,
            items = {
                pistol_ammo = 24,
            }
        }
    },
    {
        id = 'find_the_signal',
        title = 'Find The Signal',
        description = 'Extract Intel from the city and start building faction trust.',
        requiredItem = 'intel',
        requiredCount = 1,
        rewards = {
            cash = 1200,
            xp = 260,
            items = {
                meds = 1,
                weapon_parts = 1,
            }
        }
    }
}

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
        mia = 0,
        bestRunValue = 0,
        starterKitGranted = false,
        starterKitVersion = 0,
        questClaims = {},
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

local function grantStarterLoadout(profile)
    local starterKit = Config.StarterKit
    if not profile or not starterKit or not starterKit.enabled then
        return false
    end

    local changed = false

    for itemName, count in pairs(starterKit.stash or {}) do
        local itemData = Config.Items[itemName]
        if itemData and (itemData.type == 'weapon' or itemData.type == 'ammo') then
            local current = tonumber(profile.stash[itemName]) or 0
            local minimum = tonumber(count) or 0

            if minimum > 0 and current < minimum then
                profile.stash[itemName] = minimum
                changed = true
            end
        end
    end

    return changed
end

local function ensureProfileShape(profile)
    profile.cash = tonumber(profile.cash) or 0
    profile.xp = tonumber(profile.xp) or 0
    profile.raids = tonumber(profile.raids) or 0
    profile.extractions = tonumber(profile.extractions) or 0
    profile.deaths = tonumber(profile.deaths) or 0
    profile.mia = tonumber(profile.mia) or 0
    profile.bestRunValue = tonumber(profile.bestRunValue) or 0
    profile.starterKitVersion = tonumber(profile.starterKitVersion) or 0
    profile.questClaims = type(profile.questClaims) == 'table' and profile.questClaims or {}
    profile.stash = type(profile.stash) == 'table' and profile.stash or {}

    for itemName in pairs(Config.Items) do
        profile.stash[itemName] = tonumber(profile.stash[itemName]) or 0
    end

    return grantStarterKit(profile)
end

local function getItemMetadata(itemName)
    local configItem = Config.Items[itemName] or {}
    local registryItem

    if GetResourceState('extraction_items') == 'started' then
        registryItem = exports.extraction_items:GetItem(itemName)
    end

    registryItem = type(registryItem) == 'table' and registryItem or {}

    return {
        width = tonumber(registryItem.width or configItem.width) or 1,
        height = tonumber(registryItem.height or configItem.height) or 1,
        stackSize = tonumber(registryItem.stackSize or configItem.stackSize) or 99,
        image = registryItem.image or configItem.image,
    }
end

local function getContainerTemplate(templateId, fallback)
    local template

    if GetResourceState('extraction_items') == 'started' then
        template = exports.extraction_items:GetContainerTemplate(templateId)
    end

    template = type(template) == 'table' and template or {}

    return {
        id = templateId,
        label = template.label or fallback.label,
        width = tonumber(template.width or fallback.width) or fallback.width,
        height = tonumber(template.height or fallback.height) or fallback.height,
    }
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

local function getProfileByIdentifier(identifier)
    if not identifier then
        return nil
    end

    if not profiles[identifier] then
        profiles[identifier] = defaultProfile()
    end

    ensureProfileShape(profiles[identifier])
    return profiles[identifier]
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
            local metadata = getItemMetadata(itemName)

            entries[#entries + 1] = {
                name = itemName,
                label = itemData.label,
                type = itemData.type or 'loot',
                count = count,
                value = itemData.value,
                weight = itemData.weight,
                width = metadata.width,
                height = metadata.height,
                stackSize = metadata.stackSize,
                image = metadata.image,
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

local function buildQuestSnapshots(profile)
    local quests = {}

    for _, quest in ipairs(QUEST_DEFINITIONS) do
        local current = tonumber(profile.stash[quest.requiredItem]) or 0
        local required = tonumber(quest.requiredCount) or 1
        local claimed = profile.questClaims[quest.id] == true

        quests[#quests + 1] = {
            id = quest.id,
            title = quest.title,
            description = quest.description,
            progress = math.min(current, required),
            required = required,
            ready = current >= required and not claimed,
            claimed = claimed,
            rewards = quest.rewards,
        }
    end

    return quests
end

local function getTraderCatalog()
    if GetResourceState('extraction_traders') ~= 'started' then
        return {}
    end

    local shopItems = exports.extraction_traders:GetShopItems('quartermaster')
    if type(shopItems) ~= 'table' then
        return {}
    end

    local catalog = {}

    for _, offer in ipairs(shopItems) do
        local itemName = offer.item
        local itemData = Config.Items[itemName]

        if itemData then
            local metadata = getItemMetadata(itemName)

            catalog[#catalog + 1] = {
                item = itemName,
                label = offer.label or itemData.label,
                category = offer.category or itemData.type or 'Gear',
                description = offer.description or itemData.label,
                price = math.max(0, math.floor(tonumber(offer.price) or 0)),
                quantity = math.max(1, math.floor(tonumber(offer.quantity) or 1)),
                limit = math.max(0, math.floor(tonumber(offer.limit) or 0)),
                owned = 0,
                image = metadata.image,
                type = itemData.type or 'loot',
                weight = itemData.weight,
                value = itemData.value,
            }
        end
    end

    return catalog
end

local function getTraderOffer(itemName)
    if GetResourceState('extraction_traders') ~= 'started' then
        return nil
    end

    local shopItems = exports.extraction_traders:GetShopItems('quartermaster')
    if type(shopItems) ~= 'table' then
        return nil
    end

    for _, offer in ipairs(shopItems) do
        if offer.item == itemName then
            return offer
        end
    end

    return nil
end

local function getQuestDefinition(questId)
    for _, quest in ipairs(QUEST_DEFINITIONS) do
        if quest.id == questId then
            return quest
        end
    end

    return nil
end

local function buildProfileSnapshot(source)
    local profile = getProfile(source)
    if not profile then
        return nil
    end

    local raid = activeRaids[source]
    local carryLoot = raid and raid.carry or newLootBag()
    local sellDistance = isPlayerNear(source, Config.Lobby.trader.coords, Config.ValidationDistance + 2.0)
    local traderCatalog = getTraderCatalog()

    for _, offer in ipairs(traderCatalog) do
        offer.owned = tonumber(profile.stash[offer.item]) or 0
    end

    return {
        cash = profile.cash,
        xp = profile.xp,
        level = getLevelFromXp(profile.xp),
        raids = profile.raids,
        extractions = profile.extractions,
        deaths = profile.deaths,
        mia = profile.mia,
        bestRunValue = profile.bestRunValue,
        stash = buildLootList(profile.stash),
        stashValue = getLootValue(profile.stash),
        carry = buildLootList(carryLoot),
        carryValue = getLootValue(carryLoot),
        carryWeight = getLootWeight(carryLoot),
        maxCarryWeight = Config.Raid.maxCarryWeight,
        quests = buildQuestSnapshots(profile),
        containers = {
            stash = getContainerTemplate('stash_basic', { label = 'Basic Stash', width = 10, height = 20 }),
            raidBag = getContainerTemplate('raid_bag_basic', { label = 'Field Bag', width = 5, height = 6 }),
            loadout = getContainerTemplate('loadout', { label = 'Loadout', width = 6, height = 4 }),
        },
        trader = {
            label = 'Quartermaster',
            items = traderCatalog,
        },
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

local function removeLoot(targetLoot, lootToRemove)
    local changed = false

    for itemName in pairs(Config.Items) do
        local removeCount = tonumber(lootToRemove[itemName]) or 0
        if removeCount > 0 then
            local current = tonumber(targetLoot[itemName]) or 0
            targetLoot[itemName] = math.max(0, current - removeCount)
            changed = changed or targetLoot[itemName] ~= current
        end
    end

    return changed
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

local function buildLoadoutLoot(profile)
    local loadoutLoot = newLootBag()

    for itemName, itemData in pairs(Config.Items) do
        if itemData.type == 'weapon' and (tonumber(profile.stash[itemName]) or 0) > 0 then
            loadoutLoot[itemName] = 1

            if itemData.ammoItem then
                loadoutLoot[itemData.ammoItem] = tonumber(profile.stash[itemData.ammoItem]) or 0
            end
        end
    end

    return loadoutLoot
end

local function deletePersistedLoadout(profile, loadoutLoot)
    -- Current persistence is players.json. Swap this adapter for oxmysql once DB-backed loadouts land.
    if not profile or getLootWeight(loadoutLoot) <= 0 then
        return false
    end

    return removeLoot(profile.stash, loadoutLoot)
end

local function getRaid(source)
    return activeRaids[source]
end

local function getSession(sessionId)
    return sessionId and activeSessions[sessionId] or nil
end

local function getActiveRaidCount()
    local count = 0

    for _, session in pairs(activeSessions) do
        if next(session.players) ~= nil then
            count = count + 1
        end
    end

    return count
end

local function removeFromQueue(source)
    if not queuedLookup[source] then
        return
    end

    queuedLookup[source] = nil

    for index = #queuedPlayers, 1, -1 do
        if queuedPlayers[index] == source then
            table.remove(queuedPlayers, index)
            return
        end
    end
end

local function copyLoot(loot)
    local copy = newLootBag()

    for itemName in pairs(Config.Items) do
        copy[itemName] = tonumber(loot[itemName]) or 0
    end

    return copy
end

local function hasLoot(loot)
    return getLootWeight(loot) > 0
end

local function buildExtractionPayload(extractionIds)
    local points = {}

    for _, extractId in ipairs(extractionIds or {}) do
        local point = extractionById[extractId]
        if point then
            points[#points + 1] = point
        end
    end

    return points
end

local function sessionHasExtraction(session, extractId)
    if not session then
        return false
    end

    for _, sessionExtractId in ipairs(session.extractionIds or {}) do
        if sessionExtractId == extractId then
            return true
        end
    end

    return false
end

local function chooseSessionExtractions()
    local ids = {}
    local pool = {}

    for _, point in ipairs(Config.Extractions) do
        pool[#pool + 1] = point.id
    end

    local extractionConfig = SessionConfig.Extractions or {}
    local wanted = tonumber(extractionConfig.pointsPerSession) or #pool
    wanted = math.max(1, math.min(wanted, #pool))

    while #ids < wanted and #pool > 0 do
        local index = math.random(1, #pool)
        ids[#ids + 1] = pool[index]
        table.remove(pool, index)
    end

    return ids
end

local function broadcastSession(session, eventName, payload)
    if not session then
        return
    end

    for playerId in pairs(session.players) do
        if GetPlayerName(playerId) then
            TriggerClientEvent(eventName, playerId, payload)
        end
    end
end

local function buildDeathDropPayload(session)
    local drops = {}
    local now = os.time()

    if not session then
        return drops
    end

    for dropId, drop in pairs(session.deathDrops) do
        if drop.expiresAt > now then
            drops[#drops + 1] = {
                id = dropId,
                coords = drop.coords,
                value = getLootValue(drop.loot),
                weight = getLootWeight(drop.loot),
            }
        else
            if drop.crate and DoesEntityExist(drop.crate) then
                DeleteEntity(drop.crate)
            end

            session.deathDrops[dropId] = nil
        end
    end

    return drops
end

local function createDeathDropCrate(session, coords)
    local dropConfig = SessionConfig.DeathDrops or {}
    local model = dropConfig.crateModel or 'prop_box_wood02a_pu'
    local groundOffset = tonumber(dropConfig.crateGroundOffset) or 0.95
    local crate = CreateObject(joaat(model), coords.x, coords.y, coords.z - groundOffset, true, true, false)

    if not crate or crate == 0 then
        return nil
    end

    SetEntityRoutingBucket(crate, session.bucket)
    FreezeEntityPosition(crate, true)

    return crate
end

local function getRaidFallbackCoords(source, raid)
    if raid and raid.lastCoords then
        return raid.lastCoords
    end

    local ped = GetPlayerPed(source)
    if ped ~= 0 then
        local coords = GetEntityCoords(ped)
        return vec3(coords.x, coords.y, coords.z)
    end

    return nil
end

local function deleteDeathDropCrate(drop)
    if drop and drop.crate and DoesEntityExist(drop.crate) then
        DeleteEntity(drop.crate)
    end
end

local function deleteSessionDeathDrops(session)
    if not session then
        return
    end

    for _, drop in pairs(session.deathDrops) do
        deleteDeathDropCrate(drop)
    end

    session.deathDrops = {}
end

local function broadcastDeathSignal(session, dropId, coords, dropLoot)
    local signalConfig = SessionConfig.DeathDrops and SessionConfig.DeathDrops.signal or {}

    if signalConfig.enabled == false then
        return
    end

    broadcastSession(session, 'standalone_extraction:client:deathSignal', {
        id = dropId,
        coords = vec3(coords.x, coords.y, coords.z),
        value = getLootValue(dropLoot),
        durationSeconds = tonumber(signalConfig.durationSeconds) or 75,
    })
end

local function createDeathDrop(source, raid, dropCoords)
    local dropLoot = copyLoot(raid.carry)
    addLoot(dropLoot, raid.loadout or {})

    if not (SessionConfig.DeathDrops and SessionConfig.DeathDrops.enabled) or not hasLoot(dropLoot) then
        clearLoot(raid.carry)
        clearLoot(raid.loadout or {})
        return
    end

    local session = getSession(raid.sessionId)
    if not session then
        clearLoot(raid.carry)
        clearLoot(raid.loadout or {})
        return
    end

    local coords = dropCoords or getRaidFallbackCoords(source, raid)
    if not coords then
        clearLoot(raid.carry)
        clearLoot(raid.loadout or {})
        return
    end

    local dropId = nextDropId
    nextDropId = nextDropId + 1

    session.deathDrops[dropId] = {
        id = dropId,
        owner = source,
        coords = vec3(coords.x, coords.y, coords.z),
        crate = createDeathDropCrate(session, coords),
        loot = dropLoot,
        createdAt = os.time(),
        expiresAt = os.time() + (tonumber(SessionConfig.DeathDrops.ttlSeconds) or 900),
    }

    clearLoot(raid.carry)
    clearLoot(raid.loadout or {})
    broadcastSession(session, 'standalone_extraction:client:updateDeathDrops', {
        drops = buildDeathDropPayload(session),
    })
    broadcastDeathSignal(session, dropId, coords, dropLoot)
end

isPlayerNear = function(source, coords, maxDistance)
    local ped = GetPlayerPed(source)
    if ped == 0 then
        return false
    end

    local playerCoords = GetEntityCoords(ped)
    return #(asVec3(playerCoords) - asVec3(coords)) <= maxDistance
end

local function getWorldLootSpot(spotId)
    if GetResourceState('extraction_world') ~= 'started' then
        return nil
    end

    return exports.extraction_world:GetLootSpot(spotId)
end

local function getWorldLootSpots()
    if GetResourceState('extraction_world') ~= 'started' then
        return {}
    end

    return exports.extraction_world:GetLootSpots() or {}
end

local function getWorldGuardZone(zoneId)
    if GetResourceState('extraction_world') ~= 'started' then
        return nil
    end

    return exports.extraction_world:GetGuardZone(zoneId)
end

local function hasWorldLootSpots()
    if GetResourceState('extraction_world') ~= 'started' then
        return false
    end

    local spots = getWorldLootSpots()
    return type(spots) == 'table' and next(spots) ~= nil
end

local function getNearestDistance(coords, points, getPointCoords)
    local nearest

    for _, point in ipairs(points or {}) do
        local pointCoords = getPointCoords(point)

        if pointCoords then
            local distance = #(asVec3(coords) - asVec3(pointCoords))
            nearest = nearest and math.min(nearest, distance) or distance
        end
    end

    return nearest
end

local function buildSpawnThreats(extractionIds)
    local spawnConfig = SessionConfig.Spawning or {}
    local threats = {
        highTierLoot = {},
        guardZones = {},
        extractions = buildExtractionPayload(extractionIds),
    }

    if spawnConfig.avoidHighTierLoot ~= false or spawnConfig.avoidGuardZones ~= false then
        for _, spot in ipairs(getWorldLootSpots()) do
            if spot.tier == 'high' and spawnConfig.avoidHighTierLoot ~= false then
                threats.highTierLoot[#threats.highTierLoot + 1] = spot
            end

            if spot.guardZoneId and spawnConfig.avoidGuardZones ~= false then
                local guardZone = getWorldGuardZone(spot.guardZoneId)
                if guardZone then
                    threats.guardZones[#threats.guardZones + 1] = guardZone
                end
            end
        end
    end

    return threats
end

local function scoreSpawnPoint(spawn, threats)
    local spawnConfig = SessionConfig.Spawning or {}
    local score = 0
    local blocked = false
    local spawnCoords = vec3(spawn.x, spawn.y, spawn.z)

    local highTierDistance = getNearestDistance(spawnCoords, threats.highTierLoot, function(spot)
        return spot.coords
    end)

    if highTierDistance then
        if highTierDistance < (tonumber(spawnConfig.highTierMinDistance) or 260.0) then
            blocked = true
        end

        score = score + highTierDistance
    end

    local guardDistance = getNearestDistance(spawnCoords, threats.guardZones, function(zone)
        return zone.center
    end)

    if guardDistance then
        if guardDistance < (tonumber(spawnConfig.guardZoneMinDistance) or 180.0) then
            blocked = true
        end

        score = score + guardDistance
    end

    if spawnConfig.avoidExtractions ~= false then
        local extractionDistance = getNearestDistance(spawnCoords, threats.extractions, function(point)
            return point.coords
        end)

        if extractionDistance then
            if extractionDistance < (tonumber(spawnConfig.extractionMinDistance) or 180.0) then
                blocked = true
            end

            score = score + (extractionDistance * 0.5)
        end
    end

    return score, blocked
end

local function chooseSpawnPoint(extractionIds)
    local spawnConfig = SessionConfig.Spawning or {}
    local threats = buildSpawnThreats(extractionIds)
    local safeSpawns = {}
    local bestSpawn
    local bestScore = -1

    for _, spawn in ipairs(Config.Raid.spawnPoints) do
        local score, blocked = scoreSpawnPoint(spawn, threats)

        if score > bestScore then
            bestScore = score
            bestSpawn = spawn
        end

        if not blocked then
            safeSpawns[#safeSpawns + 1] = spawn
        end
    end

    if #safeSpawns > 0 then
        return safeSpawns[math.random(1, #safeSpawns)]
    end

    if spawnConfig.fallbackToBestScoredSpawn ~= false and bestSpawn then
        return bestSpawn
    end

    return Config.Raid.spawnPoints[math.random(1, #Config.Raid.spawnPoints)]
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
    local raid = activeRaids[source]
    if raid then
        local session = getSession(raid.sessionId)
        if session then
            session.players[source] = nil

            if next(session.players) == nil then
                buildDeathDropPayload(session)

                if next(session.deathDrops) == nil then
                    deleteSessionDeathDrops(session)
                    activeSessions[raid.sessionId] = nil
                end
            else
                broadcastSession(session, 'standalone_extraction:client:updateDeathDrops', {
                    drops = buildDeathDropPayload(session),
                })
            end
        end
    end

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

local function startSession(players)
    local sessionId = nextRaidId
    nextRaidId = nextRaidId + 1

    local session = {
        id = sessionId,
        bucket = Config.Raid.bucketBase + sessionId,
        startedAt = os.time(),
        expiresAt = os.time() + Config.Raid.durationSeconds,
        players = {},
        lootedSpots = {},
        deathDrops = {},
        extractionIds = chooseSessionExtractions(),
    }

    activeSessions[sessionId] = session

    local shouldSave = false

    for _, playerId in ipairs(players) do
        if GetPlayerName(playerId) and not activeRaids[playerId] then
            local profile, identifier = getProfile(playerId)

            if profile then
                local loadout = getStarterLoadout(profile)
                local loadoutLoot = buildLoadoutLoot(profile)
                local spawn = chooseSpawnPoint(session.extractionIds)

                if Config.Raid.entryFee > 0 then
                    profile.cash = profile.cash - Config.Raid.entryFee
                end

                profile.raids = profile.raids + 1
                shouldSave = true

                session.players[playerId] = true
                activeRaids[playerId] = {
                    id = sessionId,
                    sessionId = sessionId,
                    bucket = session.bucket,
                    startedAt = session.startedAt,
                    expiresAt = session.expiresAt,
                    carry = newLootBag(),
                    loadout = loadoutLoot,
                    lastCoords = vec3(spawn.x, spawn.y, spawn.z),
                    identifier = identifier,
                }

                SetPlayerRoutingBucket(playerId, session.bucket)
                TriggerClientEvent('standalone_extraction:client:startRaid', playerId, {
                    raidId = sessionId,
                    spawn = spawn,
                    durationSeconds = Config.Raid.durationSeconds,
                    maxCarryWeight = Config.Raid.maxCarryWeight,
                    loadout = loadout,
                    extractions = buildExtractionPayload(session.extractionIds),
                    deathDrops = buildDeathDropPayload(session),
                })
            end
        end
    end

    if next(session.players) == nil then
        activeSessions[sessionId] = nil
        return
    end

    if shouldSave then
        saveProfiles()
    end
end

local function processMatchmakingQueue()
    local matchmaking = SessionConfig.Matchmaking or {}
    local minPlayers = math.max(1, tonumber(matchmaking.minPlayers) or 1)
    local maxPlayers = math.max(minPlayers, tonumber(matchmaking.maxPlayers) or minPlayers)

    while #queuedPlayers >= minPlayers do
        local maxConcurrentRaids = tonumber(Config.Raid.maxConcurrentRaids) or 0
        if maxConcurrentRaids > 0 and getActiveRaidCount() >= maxConcurrentRaids then
            return
        end

        local group = {}

        while #group < maxPlayers and #queuedPlayers > 0 do
            local playerId = table.remove(queuedPlayers, 1)
            queuedLookup[playerId] = nil

            if GetPlayerName(playerId) and not activeRaids[playerId] then
                group[#group + 1] = playerId
            end
        end

        if #group >= minPlayers then
            startSession(group)
        else
            for index = #group, 1, -1 do
                local playerId = group[index]
                table.insert(queuedPlayers, 1, playerId)
                queuedLookup[playerId] = true
            end

            return
        end
    end
end

RegisterNetEvent('standalone_extraction:server:joinRaid', function()
    local source = source

    if getRaid(source) then
        notify(source, Config.Strings.already_in_raid)
        return
    end

    if queuedLookup[source] then
        notify(source, 'You are already queued for deployment.')
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
    end

    raidStartLocks[source] = nil

    local matchmaking = SessionConfig.Matchmaking or {}
    local minPlayers = math.max(1, tonumber(matchmaking.minPlayers) or 1)
    if not matchmaking.enabled or minPlayers <= 1 then
        startSession({ source })
        return
    end

    queuedLookup[source] = true
    queuedPlayers[#queuedPlayers + 1] = source

    notify(source, ('Queued for deployment (%s/%s).'):format(#queuedPlayers, tonumber(SessionConfig.Matchmaking.maxPlayers) or 1))
    processMatchmakingQueue()
end)

RegisterNetEvent('standalone_extraction:server:lootSpot', function(spotId)
    local source = source
    local raid = getRaid(source)

    if not raid then
        notify(source, Config.Strings.not_in_raid)
        return
    end

    local session = getSession(raid.sessionId)
    if not session then
        endRaid(source, 'error', 'Raid session expired.')
        return
    end

    local spot = getWorldLootSpot(spotId)
    if not spot then
        return
    end

    if session.lootedSpots[spotId] then
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

    session.lootedSpots[spotId] = true
    raid.carry[itemName] = (raid.carry[itemName] or 0) + amount

    broadcastSession(session, 'standalone_extraction:client:lootSpotEmptied', {
        spotId = spotId,
    })

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

    local session = getSession(raid.sessionId)
    if not session or not sessionHasExtraction(session, extractId) then
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

RegisterNetEvent('standalone_extraction:server:lootDeathDrop', function(dropId)
    local source = source
    local raid = getRaid(source)

    if not raid then
        notify(source, Config.Strings.not_in_raid)
        return
    end

    local session = getSession(raid.sessionId)
    if not session then
        endRaid(source, 'error', 'Raid session expired.')
        return
    end

    dropId = tonumber(dropId)
    local drop = dropId and session.deathDrops[dropId]
    if not drop then
        notify(source, 'This death drop is already gone.')
        return
    end

    if drop.expiresAt <= os.time() then
        deleteDeathDropCrate(drop)
        session.deathDrops[dropId] = nil
        broadcastSession(session, 'standalone_extraction:client:updateDeathDrops', {
            drops = buildDeathDropPayload(session),
        })
        notify(source, 'This death drop has expired.')
        return
    end

    if not isPlayerNear(source, drop.coords, Config.ValidationDistance) then
        return
    end

    local nextWeight = getLootWeight(raid.carry) + getLootWeight(drop.loot)
    if nextWeight > Config.Raid.maxCarryWeight then
        notify(source, Config.Strings.bag_full)
        return
    end

    addLoot(raid.carry, drop.loot)
    deleteDeathDropCrate(drop)
    session.deathDrops[dropId] = nil

    TriggerClientEvent('standalone_extraction:client:updateCarry', source, {
        carry = buildLootList(raid.carry),
        carryValue = getLootValue(raid.carry),
        carryWeight = getLootWeight(raid.carry),
        maxCarryWeight = Config.Raid.maxCarryWeight,
    })

    notify(source, ('Recovered death drop worth $%s.'):format(getLootValue(drop.loot)))
    sendInventorySnapshot(source, false)
    broadcastSession(session, 'standalone_extraction:client:updateDeathDrops', {
        drops = buildDeathDropPayload(session),
    })
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

RegisterNetEvent('standalone_extraction:server:buyTraderItem', function(itemName, quantity)
    local source = source

    if getRaid(source) then
        notify(source, 'You cannot buy gear while you are in a raid.')
        return
    end

    local profile = getProfile(source)
    local itemData = Config.Items[itemName]
    local offer = getTraderOffer(itemName)

    if not profile or not itemData or not offer then
        return
    end

    quantity = math.max(1, math.min(10, math.floor(tonumber(quantity) or 1)))

    local stackAmount = math.max(1, math.floor(tonumber(offer.quantity) or 1))
    local price = math.max(0, math.floor(tonumber(offer.price) or 0))
    local totalCost = price * quantity
    local totalItems = stackAmount * quantity
    local limit = math.max(0, math.floor(tonumber(offer.limit) or 0))
    local current = tonumber(profile.stash[itemName]) or 0

    if limit > 0 and current + totalItems > limit then
        notify(source, ('Quartermaster limit reached for %s.'):format(itemData.label))
        TriggerClientEvent('extraction_lobby:client:update', source, buildProfileSnapshot(source))
        return
    end

    if profile.cash < totalCost then
        notify(source, 'Not enough cash for this purchase.')
        TriggerClientEvent('extraction_lobby:client:update', source, buildProfileSnapshot(source))
        return
    end

    profile.cash = profile.cash - totalCost
    profile.stash[itemName] = current + totalItems
    saveProfiles()

    notify(source, ('Purchased %sx %s for $%s.'):format(totalItems, itemData.label, totalCost))
    TriggerClientEvent('extraction_lobby:client:update', source, buildProfileSnapshot(source))
    sendInventorySnapshot(source, false)
end)

RegisterNetEvent('standalone_extraction:server:claimQuestReward', function(questId)
    local source = source

    if getRaid(source) then
        notify(source, 'Claim rewards from the safehouse after extraction.')
        return
    end

    local quest = getQuestDefinition(questId)
    if not quest then
        return
    end

    local profile = getProfile(source)
    if not profile then
        return
    end

    if profile.questClaims[quest.id] then
        notify(source, 'Quest reward already claimed.')
        TriggerClientEvent('extraction_lobby:client:update', source, buildProfileSnapshot(source))
        return
    end

    local current = tonumber(profile.stash[quest.requiredItem]) or 0
    local required = tonumber(quest.requiredCount) or 1
    if current < required then
        notify(source, 'Quest objective is not complete yet.')
        TriggerClientEvent('extraction_lobby:client:update', source, buildProfileSnapshot(source))
        return
    end

    local rewards = quest.rewards or {}
    profile.cash = profile.cash + (tonumber(rewards.cash) or 0)
    profile.xp = profile.xp + (tonumber(rewards.xp) or 0)

    for itemName, count in pairs(rewards.items or {}) do
        if Config.Items[itemName] then
            profile.stash[itemName] = (tonumber(profile.stash[itemName]) or 0) + (tonumber(count) or 0)
        end
    end

    profile.questClaims[quest.id] = true
    saveProfiles()

    notify(source, ('Claimed quest reward: %s.'):format(quest.title))
    TriggerClientEvent('extraction_lobby:client:update', source, buildProfileSnapshot(source))
    sendInventorySnapshot(source, false)
end)

RegisterNetEvent('standalone_extraction:server:requestProfile', function()
    local source = source
    TriggerClientEvent('standalone_extraction:client:showProfile', source, buildProfileSnapshot(source))
end)

RegisterNetEvent('standalone_extraction:server:requestLobbySnapshot', function()
    local source = source
    TriggerClientEvent('extraction_lobby:client:update', source, buildProfileSnapshot(source))
end)

RegisterNetEvent('standalone_extraction:server:requestInventory', function(openUi)
    local source = source
    sendInventorySnapshot(source, openUi ~= false)
end)

RegisterCommand('lsx_fixkit', function(source, args)
    if source ~= 0 and not IsPlayerAceAllowed(source, 'command.lsx_fixkit') then
        notify(source, 'You do not have permission to repair starter kits.')
        return
    end

    local target = tonumber(args[1]) or source
    if target == 0 or not GetPlayerName(target) then
        print('[standalone_extraction] Usage: lsx_fixkit <server id>')
        return
    end

    if getRaid(target) then
        if source == 0 then
            print(('[standalone_extraction] Cannot repair kit for %s while they are in a raid.'):format(GetPlayerName(target)))
        else
            notify(source, 'Starter kit repair can only be used from the safehouse.')
        end
        return
    end

    local profile = getProfile(target)
    if not profile then
        return
    end

    if grantStarterLoadout(profile) then
        saveProfiles()
        notify(target, 'Starter loadout repaired: pistol and ammo restored.')
        TriggerClientEvent('extraction_lobby:client:update', target, buildProfileSnapshot(target))
        sendInventorySnapshot(target, false)
        print(('[standalone_extraction] Repaired starter loadout for %s.'):format(GetPlayerName(target)))
    else
        notify(target, 'Starter loadout already has the minimum pistol and ammo.')
    end
end, false)

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

local function onPlayerDeath(source)
    local raid = getRaid(source)
    if not raid then
        return
    end

    local profile = getProfile(source) or getProfileByIdentifier(raid.identifier)
    if profile then
        deletePersistedLoadout(profile, raid.loadout or {})
        profile.deaths = profile.deaths + 1
        saveProfiles()
    end

    createDeathDrop(source, raid)
    endRaid(source, 'dead', Config.Strings.died)
end

local function onPlayerDroppedInRaid(source)
    local raid = getRaid(source)
    if not raid then
        return
    end

    local profile = getProfile(source) or getProfileByIdentifier(raid.identifier)
    if profile then
        deletePersistedLoadout(profile, raid.loadout or {})
        profile.mia = profile.mia + 1
        saveProfiles()
    end

    createDeathDrop(source, raid, getRaidFallbackCoords(source, raid))
    cleanupRaid(source)
end

local function markPlayerMia(source)
    local raid = getRaid(source)
    if not raid then
        return
    end

    local profile = getProfile(source) or getProfileByIdentifier(raid.identifier)
    if profile then
        deletePersistedLoadout(profile, raid.loadout or {})
        profile.mia = profile.mia + 1
        saveProfiles()
    end

    clearLoot(raid.carry)
    clearLoot(raid.loadout or {})
    endRaid(source, 'mia', 'You went MIA. Your carried equipment was lost.')
end

RegisterNetEvent('standalone_extraction:server:playerDied', function()
    onPlayerDeath(source)
end)

AddEventHandler('playerDropped', function()
    local source = source

    raidStartLocks[source] = nil
    removeFromQueue(source)

    if activeRaids[source] then
        onPlayerDroppedInRaid(source)
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
    local queueTickMs = tonumber(SessionConfig.Matchmaking and SessionConfig.Matchmaking.queueTickMs) or 1500

    while true do
        if #queuedPlayers > 0 then
            processMatchmakingQueue()
            Wait(queueTickMs)
        else
            Wait(2500)
        end
    end
end)

CreateThread(function()
    while true do
        local now = os.time()
        local timedOutPlayers = {}

        for source, raid in pairs(activeRaids) do
            local ped = GetPlayerPed(source)
            if ped ~= 0 then
                local coords = GetEntityCoords(ped)
                raid.lastCoords = vec3(coords.x, coords.y, coords.z)
            end

            if now >= raid.expiresAt then
                timedOutPlayers[#timedOutPlayers + 1] = source
            end
        end

        for _, source in ipairs(timedOutPlayers) do
            markPlayerMia(source)
        end

        for sessionId, session in pairs(activeSessions) do
            buildDeathDropPayload(session)

            if next(session.players) == nil and next(session.deathDrops) == nil then
                activeSessions[sessionId] = nil
            end
        end

        Wait(2500)
    end
end)

CreateThread(function()
    while true do
        saveProfiles()
        Wait(300000)
    end
end)
