exports('GetCoreObject', function()
    return LSX
end)

exports('GetPlayer', function()
    return LSX.Client.GetPlayer()
end)

exports('GetPlayerData', function()
    local state = LocalPlayer and LocalPlayer.state and LocalPlayer.state.lsxPlayer

    if state then
        LSX.Client.SetPlayerData(state)
    end

    return LSX.Client.GetPlayer()
end)
