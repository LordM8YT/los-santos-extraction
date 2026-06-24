LSX.Client = LSX.Client or {}

local playerData = {
    groups = {},
    statuses = {},
    licenses = {},
    metadata = {},
}

local PlayerMethods = {}
PlayerMethods.__index = PlayerMethods

local player = setmetatable(playerData, PlayerMethods)

local dotMethods = {
    'get',
    'getCoords',
    'getGroups',
    'getGroup',
    'getGroupByType',
    'getStatus',
    'getStatuses',
    'addStatus',
    'removeStatus',
    'hasPermission',
    'on',
}

for _, methodName in ipairs(dotMethods) do
    player[methodName] = function(...)
        return PlayerMethods[methodName](player, ...)
    end
end

local function merge(data)
    if type(data) ~= 'table' then return end

    for key, value in pairs(data) do
        playerData[key] = value
    end
end

function PlayerMethods:get(key)
    return self.metadata and self.metadata[key] or nil
end

function PlayerMethods:getCoords()
    return GetEntityCoords(PlayerPedId())
end

function PlayerMethods:getGroups()
    return LSX.Utils.Copy(self.groups or {})
end

function PlayerMethods:getGroup(filter)
    if type(filter) == 'string' then
        return self.groups and self.groups[filter] or nil
    end

    if type(filter) ~= 'table' then
        return nil
    end

    for key, value in pairs(filter) do
        if type(key) == 'number' then
            local grade = self.groups and self.groups[value]
            if grade then return value, grade end
        else
            local grade = self.groups and self.groups[key]
            if grade and grade >= value then return key, grade end
        end
    end

    return nil
end

function PlayerMethods:getGroupByType(groupType)
    for groupName, grade in pairs(self.groups or {}) do
        local group = GlobalState[('group.%s'):format(groupName)]

        if group and group.type == groupType then
            return groupName, grade
        end
    end

    return nil
end

function PlayerMethods:getStatus(statusName)
    return self.statuses and self.statuses[statusName] or 0
end

function PlayerMethods:getStatuses()
    return LSX.Utils.Copy(self.statuses or {})
end

function PlayerMethods:addStatus(statusName, value)
    self.statuses = self.statuses or {}
    self.statuses[statusName] = LSX.Utils.Clamp((self.statuses[statusName] or 0) + (tonumber(value) or 0), 0, 100)
    return true
end

function PlayerMethods:removeStatus(statusName, value)
    return PlayerMethods.addStatus(self, statusName, -(tonumber(value) or 0))
end

function PlayerMethods:hasPermission()
    return false
end

function PlayerMethods:on()
    return false
end

function LSX.Client.SetPlayerData(data)
    merge(data)
end

function LSX.Client.GetPlayer()
    return player
end

RegisterNetEvent(LSXEvents.PlayerLoaded, function(data)
    merge(data)
end)

RegisterNetEvent(LSXEvents.PlayerData, function(data)
    merge(data)
end)

RegisterNetEvent(LSXEvents.SetGroup, function(name, grade)
    playerData.groups = playerData.groups or {}
    playerData.groups[name] = grade
end)
