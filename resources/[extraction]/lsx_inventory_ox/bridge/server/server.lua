if not lib.checkDependency('lsx_core', '0.1.0', true) then return end

local Inventory = require 'modules.inventory.server'

local function getPlayerName(player)
    local metadata = player.metadata or {}
    local firstName = metadata.firstName or metadata.operatorName
    local lastName = metadata.lastName

    if firstName and lastName then
        return ('%s %s'):format(firstName, lastName)
    end

    return player.username or GetPlayerName(player.source) or ('Player %s'):format(player.source)
end

local function setupPlayer(source)
    local player = exports.lsx_core:GetPlayer(source)

    if not player then return end

    server.setPlayerInventory({
        source = player.source,
        identifier = player.identifier,
        name = getPlayerName(player),
        groups = player.getGroups(),
        sex = player.get('gender'),
        dateofbirth = player.get('dateOfBirth'),
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
        sex = player.sex,
        dateofbirth = player.dateofbirth,
    }
end

---@diagnostic disable-next-line: duplicate-set-field
function server.hasLicense(inv, name)
    local player = exports.lsx_core:GetPlayer(inv.id)

    return player and player.getLicense(name)
end

---@diagnostic disable-next-line: duplicate-set-field
function server.buyLicense(inv, license)
    local player = exports.lsx_core:GetPlayer(inv.id)

    if not player then return end

    if player.getLicense(license.name) then
        return false, 'already_have'
    elseif Inventory.GetItemCount(inv, 'money') < license.price then
        return false, 'can_not_afford'
    end

    Inventory.RemoveItem(inv, 'money', license.price)
    player.addLicense(license.name)

    return true, 'have_purchased'
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
