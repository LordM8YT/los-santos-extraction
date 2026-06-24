if not lib.checkDependency('lsx_core', '0.1.0', true) then return end

local player = exports.lsx_core:GetPlayer()

RegisterNetEvent('lsx:playerLogout', client.onLogout)

RegisterNetEvent('lsx:playerData', function(data)
    if data.groups then
        client.setPlayerData('groups', data.groups)
    end
end)

RegisterNetEvent('lsx:setGroup', function(name, grade)
    local groups = PlayerData.groups or {}

    if not grade or grade <= 0 then
        groups[name] = nil
    else
        groups[name] = grade
    end

    client.setPlayerData('groups', groups)
end)

---@diagnostic disable-next-line: duplicate-set-field
function client.setPlayerStatus(values)
    for name, value in pairs(values) do
        if value > 100 or value < -100 then
            value = value * 0.0001
        end

        player.addStatus(name, value)
    end
end
