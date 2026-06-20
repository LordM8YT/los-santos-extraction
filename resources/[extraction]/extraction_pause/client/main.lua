local uiOpen = false

local function send(action, payload)
    SendNUIMessage({
        action = action,
        payload = payload or {}
    })
end

local function closePause()
    uiOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    send('close')
end

local function openPause()
    if uiOpen then
        return
    end

    uiOpen = true
    SetPauseMenuActive(false)
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    send('open')
end

RegisterCommand('extractionpause', function()
    openPause()
end, false)

RegisterNUICallback('close', function(_, cb)
    closePause()
    cb({ ok = true })
end)

RegisterNUICallback('openLobby', function(_, cb)
    closePause()
    TriggerEvent('extraction_lobby:client:open', 'deploy')
    cb({ ok = true })
end)

RegisterNUICallback('openInventory', function(_, cb)
    closePause()
    TriggerServerEvent('standalone_extraction:server:requestInventory', true)
    cb({ ok = true })
end)

RegisterNUICallback('leaveRaid', function(_, cb)
    closePause()
    TriggerServerEvent('standalone_extraction:server:leaveRaid')
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        closePause()
    end
end)

CreateThread(function()
    closePause()

    while true do
        DisableControlAction(0, 199, true) -- Pause menu
        DisableControlAction(0, 200, true) -- ESC pause
        DisableControlAction(0, 244, true) -- Interaction/menu fallback

        if IsDisabledControlJustPressed(0, 199) or IsDisabledControlJustPressed(0, 200) then
            if uiOpen then
                closePause()
            else
                openPause()
            end
        end

        if IsPauseMenuActive() then
            SetPauseMenuActive(false)
        end

        Wait(0)
    end
end)
