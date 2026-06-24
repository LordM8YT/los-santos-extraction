if not lib.checkDependency('lsx_core', '0.1.0', true) then return end

local Inventory = require 'modules.inventory.server'

local function getPlayerName(player)
    local metadata = player.metadata or {}
    local operatorName = metadata.operatorName or metadata.callSign

    return operatorName or player.username or GetPlayerName(player.source) or ('Operator %s'):format(player.source)
end

local function setupPlayer(source)
    local player = exports.lsx_core:GetPlayer(source)

    if not player then return end

    server.setPlayerInventory({
        source = player.source,
        identifier = player.identifier,
        name = getPlayerName(player),
        groups = player.getGroups(),
    })
end

AddEventHandler('lsx:playerLoaded', function(source)
    setupPlayer(source)
end)

AddEventHandler('lsx:playerLogout', server.playerDropped)
AddEventHandler('lsx:playerDropped', server.playerDropped)

AddEventHandler('lsx:setGroup', function(source, groupName, grade)
    local inventory = Inventory(source)

    if not inventory or not inventory.player then return end

    if not grade or grade <= 0 then
        inventory.player.groups[groupName] = nil
    else
        inventory.player.groups[groupName] = grade
    end
end)

SetTimeout(750, function()
    for _, playerId in ipairs(GetPlayers()) do
        setupPlayer(tonumber(playerId))
    end
end)

---@diagnostic disable-next-line: duplicate-set-field
function server.setPlayerData(player)
    local lsxPlayer = exports.lsx_core:GetPlayer(player.source)

    return {
        source = player.source,
        name = player.name,
        groups = lsxPlayer and lsxPlayer.getGroups() or player.groups or {},
    }
end

---@diagnostic disable-next-line: duplicate-set-field
function server.hasLicense()
    return false
end

---@diagnostic disable-next-line: duplicate-set-field
function server.buyLicense()
    return false, 'not_supported'
end

---@diagnostic disable-next-line: duplicate-set-field
function server.isPlayerBoss(playerId, group, grade)
    local groupData = GlobalState[('group.%s'):format(group)]

    return groupData and grade >= (groupData.adminGrade or 999)
end

---@diagnostic disable-next-line: duplicate-set-field
function server.getOwnedVehicleId()
    return nil
end
