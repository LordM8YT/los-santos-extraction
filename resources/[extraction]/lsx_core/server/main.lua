local function unsupported()
    return nil
end

exports('GetCoreObject', function()
    return LSX
end)

exports('GetIdentifierSnapshot', function(source)
    return LSX.Server.Identifiers.GetSnapshot(source)
end)

exports('GetPrimaryIdentifier', function(source)
    return LSX.Server.Identifiers.GetPrimary(source)
end)

exports('GetPlayer', function(source)
    return LSX.Server.Players.Get(source)
end)

exports('GetPlayerData', function(source)
    local player = LSX.Server.Players.Get(source)
    return player and player.serialize() or nil
end)

exports('GetInventoryPlayerData', function(source)
    local player = LSX.Server.Players.Get(source)
    return player and player.getInventoryData() or nil
end)

exports('GetPlayerFromUserId', function(userId)
    return LSX.Server.Players.GetFromUserId(userId)
end)

exports('GetPlayerFromCharId', function(charId)
    return LSX.Server.Players.GetFromCharId(charId)
end)

exports('GetPlayerFromFilter', function(filter)
    return LSX.Server.Players.GetFromFilter(filter)
end)

exports('GetPlayers', function(filter)
    return LSX.Server.Players.GetAll(filter)
end)

exports('GetGroup', function(name)
    return LSX.Server.Groups.Get(name)
end)

exports('GetGroupsByType', function(groupType)
    return LSX.Server.Groups.GetByType(groupType)
end)

exports('SetGroupPermission', function(groupName, grade, permission, value)
    return LSX.Server.Groups.SetPermission(groupName, grade, permission, value)
end)

exports('RemoveGroupPermission', function(groupName, grade, permission)
    return LSX.Server.Groups.RemovePermission(groupName, grade, permission)
end)

exports('GetGroupActivePlayers', function(groupName)
    local active = {}

    for _, player in ipairs(LSX.Server.Players.GetAll()) do
        if player.groups[groupName] and player.metadata.activeGroup == groupName then
            active[#active + 1] = player.source
        end
    end

    return active
end)

exports('GetGroupActivePlayersByType', function(groupType)
    local active = {}

    for _, player in ipairs(LSX.Server.Players.GetAll()) do
        local groupName = player.getGroupByType(groupType)

        if groupName and player.metadata.activeGroup == groupName then
            active[#active + 1] = player.source
        end
    end

    return active
end)

exports('GetLicenses', function()
    return {}
end)

exports('GetLicense', function()
    return nil
end)

exports('SaveAllPlayers', function()
    for _, player in ipairs(LSX.Server.Players.GetAll()) do
        player.save()
    end
end)

exports('CreateAccount', unsupported)
exports('GetAccount', unsupported)
exports('GetCharacterAccount', unsupported)
exports('GetGroupAccount', unsupported)
exports('CreateVehicle', unsupported)
exports('SpawnVehicle', unsupported)
exports('GetVehicle', unsupported)
exports('GetVehicleFromFilter', unsupported)
exports('GetVehicleFromNetId', unsupported)
exports('GetVehicleFromVin', unsupported)
exports('GetVehicleFromEntity', unsupported)
exports('GetVehicles', function()
    return {}
end)
exports('SaveAllVehicles', function()
    return true
end)
