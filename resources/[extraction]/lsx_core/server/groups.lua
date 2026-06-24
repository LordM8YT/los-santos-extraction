LSX.Server = LSX.Server or {}
LSX.Server.Groups = {}

local groupPermissions = {}

local function publishGroups()
    local names = {}

    for name, data in pairs(LSXConfig.Groups) do
        names[#names + 1] = name
        GlobalState[('group.%s'):format(name)] = LSX.Utils.Copy(data)
    end

    table.sort(names)
    GlobalState.groups = names
    GlobalState.accountRoles = {}
end

function LSX.Server.Groups.Get(name)
    return name and LSXConfig.Groups[name] or nil
end

function LSX.Server.Groups.GetByType(groupType)
    local groups = {}

    for name, data in pairs(LSXConfig.Groups) do
        if data.type == groupType then
            groups[#groups + 1] = name
        end
    end

    table.sort(groups)
    return groups
end

function LSX.Server.Groups.SetPermission(groupName, grade, permission, value)
    if not LSXConfig.Groups[groupName] or not permission then
        return false
    end

    grade = tonumber(grade) or 0
    groupPermissions[groupName] = groupPermissions[groupName] or {}
    groupPermissions[groupName][grade] = groupPermissions[groupName][grade] or {}
    groupPermissions[groupName][grade][permission] = value == 'allow' and 'allow' or 'deny'

    return true
end

function LSX.Server.Groups.RemovePermission(groupName, grade, permission)
    grade = tonumber(grade) or 0

    if not groupPermissions[groupName] or not groupPermissions[groupName][grade] then
        return false
    end

    groupPermissions[groupName][grade][permission] = nil
    return true
end

function LSX.Server.Groups.HasPermission(groupName, grade, permission)
    local permissions = groupPermissions[groupName]

    if not permissions then
        return false
    end

    grade = tonumber(grade) or 0

    for currentGrade = grade, 0, -1 do
        local value = permissions[currentGrade] and permissions[currentGrade][permission]

        if value == 'allow' then return true end
        if value == 'deny' then return false end
    end

    return false
end

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        publishGroups()
    end
end)
