LSX.Server = LSX.Server or {}
LSX.Server.Players = {}

local playersBySource = {}
local playersByUserId = {}
local playersByCharId = {}
local nextUserId = 1000
local nextCharId = 1000

local PlayerMethods = {}
PlayerMethods.__index = PlayerMethods

local dotMethods = {
    'serialize',
    'emit',
    'get',
    'set',
    'getCoords',
    'getGroups',
    'getGroup',
    'getGroupByType',
    'setGroup',
    'setActiveGroup',
    'hasPermission',
    'getStatus',
    'getStatuses',
    'setStatus',
    'addStatus',
    'removeStatus',
    'getDisplayName',
    'getInventoryData',
    'save',
    'logout',
    'createCharacter',
    'deleteCharacter',
    'setActiveCharacter',
}

local function getPlayerPedSafe(source)
    local ped = GetPlayerPed(source)
    return ped ~= 0 and ped or nil
end

local function getCoordsSafe(source)
    local ped = getPlayerPedSafe(source)

    if not ped then
        return vector3(0.0, 0.0, 0.0)
    end

    return GetEntityCoords(ped)
end

local function syncState(player)
    local state = Player(player.source).state
    local payload = {
        source = player.source,
        userId = player.userId,
        charId = player.charId,
        stateId = player.stateId,
        identifier = player.identifier,
        username = player.username,
        groups = LSX.Utils.Copy(player.groups),
        statuses = LSX.Utils.Copy(player.statuses),
        metadata = LSX.Utils.Copy(player.metadata),
    }

    state:set('lsxPlayer', payload, true)
    TriggerClientEvent(LSXEvents.PlayerData, player.source, payload)
end

local function createDefaultGroups(source)
    local groups = {
        [LSXConfig.Player.defaultGroup] = LSXConfig.Player.defaultGroupGrade,
    }

    if IsPlayerAceAllowed(source, 'easyadmin') or IsPlayerAceAllowed(source, 'command') then
        groups.admin = 3
    end

    return groups
end

local function attachDotMethods(player)
    for _, methodName in ipairs(dotMethods) do
        player[methodName] = function(...)
            return PlayerMethods[methodName](player, ...)
        end
    end

    return player
end

local function createPlayer(source)
    source = tonumber(source)

    if not source or not GetPlayerName(source) then
        return nil
    end

    if playersBySource[source] then
        return playersBySource[source]
    end

    local identifiers = LSX.Server.Identifiers.GetSnapshot(source)
    nextUserId = nextUserId + 1
    nextCharId = nextCharId + 1

    local player = attachDotMethods(setmetatable({
        source = source,
        ped = getPlayerPedSafe(source) or 0,
        identifier = identifiers.primary,
        userId = nextUserId,
        charId = nextCharId,
        stateId = ('lsx:%s'):format(nextCharId),
        username = identifiers.name or ('Player %s'):format(source),
        metadata = {
            identifiers = identifiers,
            phase = 'lobby',
        },
        groups = createDefaultGroups(source),
        statuses = LSX.Utils.Copy(LSXConfig.Player.defaultStatuses),
    }, PlayerMethods))

    playersBySource[source] = player
    playersByUserId[player.userId] = player
    playersByCharId[player.charId] = player

    syncState(player)
    TriggerEvent(LSXEvents.PlayerLoaded, source, player)
    TriggerClientEvent(LSXEvents.PlayerLoaded, source, player.serialize())

    LSX.Utils.Debug('Player loaded.', {
        source = source,
        userId = player.userId,
        charId = player.charId,
        identifier = player.identifier,
    })

    return player
end

local function removePlayer(source, reason)
    source = tonumber(source)
    local player = source and playersBySource[source]

    if not player then
        return
    end

    playersBySource[source] = nil
    playersByUserId[player.userId] = nil
    playersByCharId[player.charId] = nil

    TriggerEvent(LSXEvents.PlayerDropped, source, reason, player)

    if LSXConfig.Compatibility.emitOxEvents then
        TriggerEvent('ox:playerLogout', source, true)
    end

    LSX.Utils.Debug('Player dropped.', {
        source = source,
        reason = reason,
    })
end

function PlayerMethods:serialize()
    return {
        source = self.source,
        userId = self.userId,
        charId = self.charId,
        stateId = self.stateId,
        identifier = self.identifier,
        username = self.username,
        groups = LSX.Utils.Copy(self.groups),
        statuses = LSX.Utils.Copy(self.statuses),
        metadata = LSX.Utils.Copy(self.metadata),
    }
end

function PlayerMethods:emit(eventName, ...)
    TriggerClientEvent(eventName, self.source, ...)
end

function PlayerMethods:get(key)
    return self.metadata[key]
end

function PlayerMethods:set(key, value, replicated)
    self.metadata[key] = value

    if replicated then
        syncState(self)
    end

    TriggerEvent(LSXEvents.MetadataChanged, self.source, key, value)
end

function PlayerMethods:getCoords()
    return getCoordsSafe(self.source)
end

function PlayerMethods:getGroups()
    return LSX.Utils.Copy(self.groups)
end

function PlayerMethods:getGroup(filter)
    if type(filter) == 'string' then
        return self.groups[filter]
    end

    if type(filter) ~= 'table' then
        return nil
    end

    for key, value in pairs(filter) do
        if type(key) == 'number' then
            local grade = self.groups[value]

            if grade then
                return value, grade
            end
        else
            local grade = self.groups[key]

            if grade and grade >= value then
                return key, grade
            end
        end
    end

    return nil
end

function PlayerMethods:getGroupByType(groupType)
    for groupName, grade in pairs(self.groups) do
        local group = LSX.Server.Groups.Get(groupName)

        if group and group.type == groupType then
            return groupName, grade
        end
    end

    return nil
end

function PlayerMethods:setGroup(groupName, grade)
    if not groupName or not LSX.Server.Groups.Get(groupName) then
        return false
    end

    grade = tonumber(grade) or 0

    if grade <= 0 then
        self.groups[groupName] = nil
    else
        self.groups[groupName] = grade
    end

    syncState(self)
    TriggerEvent(LSXEvents.SetGroup, self.source, groupName, grade)
    TriggerClientEvent(LSXEvents.SetGroup, self.source, groupName, grade)

    if LSXConfig.Compatibility.emitOxEvents then
        TriggerEvent('ox:setGroup', self.source, groupName, grade)
        TriggerClientEvent('ox:setGroup', self.source, groupName, grade)
    end

    return true
end

function PlayerMethods:setActiveGroup(groupName)
    if groupName and not self.groups[groupName] then
        return false
    end

    self.metadata.activeGroup = groupName
    syncState(self)

    return true
end

function PlayerMethods:hasPermission(permission)
    if type(permission) ~= 'string' then
        return false
    end

    local groupName, groupPermission = permission:match('^group%.([^%.]+)%.(.+)$')

    if groupName then
        local grade = self.groups[groupName]
        return grade and LSX.Server.Groups.HasPermission(groupName, grade, groupPermission) or false
    end

    for name, grade in pairs(self.groups) do
        if LSX.Server.Groups.HasPermission(name, grade, permission) then
            return true
        end
    end

    return false
end

function PlayerMethods:getStatus(statusName)
    return self.statuses[statusName] or 0
end

function PlayerMethods:getStatuses()
    return LSX.Utils.Copy(self.statuses)
end

function PlayerMethods:setStatus(statusName, value)
    if not statusName then return false end

    self.statuses[statusName] = LSX.Utils.Clamp(value, 0, 100)
    syncState(self)

    return true
end

function PlayerMethods:addStatus(statusName, value)
    return PlayerMethods.setStatus(self, statusName, PlayerMethods.getStatus(self, statusName) + (tonumber(value) or 0))
end

function PlayerMethods:removeStatus(statusName, value)
    return PlayerMethods.setStatus(self, statusName, PlayerMethods.getStatus(self, statusName) - (tonumber(value) or 0))
end

function PlayerMethods:getDisplayName()
    local metadata = self.metadata or {}

    return metadata.operatorName or metadata.callSign or self.username or ('Operator %s'):format(self.source)
end

function PlayerMethods:getInventoryData()
    return {
        source = self.source,
        identifier = self.identifier,
        userId = self.userId,
        charId = self.charId,
        stateId = self.stateId,
        name = self.getDisplayName(),
        groups = self.getGroups(),
        metadata = {
            operatorName = self.metadata.operatorName,
            callSign = self.metadata.callSign,
            phase = self.metadata.phase,
        },
    }
end

function PlayerMethods:save()
    -- Persistence belongs to lsx_player. The core object exposes save() for ox-style compatibility.
    TriggerEvent('lsx:playerSaveRequested', self.source, self)
end

function PlayerMethods:logout(save, dropped)
    if save ~= false then
        self.save()
    end

    TriggerEvent(LSXEvents.PlayerLogout, self.source, dropped == true, self)

    if LSXConfig.Compatibility.emitOxEvents then
        TriggerEvent('ox:playerLogout', self.source, dropped == true)
    end
end

function PlayerMethods:createCharacter(data)
    self.metadata.characterDraft = data
    return self.charId
end

function PlayerMethods:deleteCharacter(charId)
    return tonumber(charId) == self.charId
end

function PlayerMethods:setActiveCharacter(data)
    if type(data) == 'table' then
        for key, value in pairs(data) do
            self.metadata[key] = value
        end
    end

    syncState(self)

    return {
        charId = self.charId,
        stateId = self.stateId,
        operatorName = self.metadata.operatorName or self.username or ('Operator %s'):format(self.charId),
        callSign = self.metadata.callSign or ('LSX-%s'):format(self.charId),
        isNew = false,
    }
end

function LSX.Server.Players.Create(source)
    return createPlayer(source)
end

function LSX.Server.Players.Remove(source, reason)
    removePlayer(source, reason)
end

function LSX.Server.Players.Get(source)
    return playersBySource[tonumber(source)]
end

function LSX.Server.Players.GetFromUserId(userId)
    return playersByUserId[tonumber(userId)]
end

function LSX.Server.Players.GetFromCharId(charId)
    return playersByCharId[tonumber(charId)]
end

function LSX.Server.Players.GetAll(filter)
    local players = {}

    for _, player in pairs(playersBySource) do
        if not filter or LSX.Server.Players.MatchesFilter(player, filter) then
            players[#players + 1] = player
        end
    end

    return players
end

function LSX.Server.Players.GetFromFilter(filter)
    for _, player in pairs(playersBySource) do
        if LSX.Server.Players.MatchesFilter(player, filter) then
            return player
        end
    end

    return nil
end

function LSX.Server.Players.MatchesFilter(player, filter)
    if not filter then return true end

    for key, expected in pairs(filter) do
        if key == 'groups' then
            if type(expected) == 'string' and not player.groups[expected] then
                return false
            elseif type(expected) == 'table' then
                local matched = false

                for _, groupName in pairs(expected) do
                    if player.groups[groupName] then
                        matched = true
                        break
                    end
                end

                if not matched then return false end
            end
        elseif player[key] ~= expected and player.metadata[key] ~= expected then
            return false
        end
    end

    return true
end

AddEventHandler('playerJoining', function()
    createPlayer(source)
end)

AddEventHandler('playerDropped', function(reason)
    removePlayer(source, reason)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    for _, playerId in ipairs(GetPlayers()) do
        createPlayer(tonumber(playerId))
    end
end)
