local uiOpen = false
local latestSnapshot

local function fallbackSnapshot()
    return {
        cash = 0,
        xp = 0,
        level = 1,
        raids = 0,
        extractions = 0,
        deaths = 0,
        bestRunValue = 0,
        stashValue = 0,
        carryWeight = 0,
        maxCarryWeight = 0,
        stash = {},
        carry = {},
        raidActive = false,
        canSell = false,
        loading = true,
    }
end

local function send(action, payload)
    SendNUIMessage({
        action = action,
        payload = payload or {}
    })
end

local function requestSnapshot()
    TriggerServerEvent('standalone_extraction:server:requestLobbySnapshot')
end

local function closeUi()
    uiOpen = false
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
    send('close')
end

local function openUi(defaultView)
    defaultView = defaultView or 'deploy'

    if uiOpen then
        send('setView', { view = defaultView })
        requestSnapshot()
        return
    end

    uiOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    send('open', {
        snapshot = latestSnapshot or fallbackSnapshot(),
        view = defaultView,
    })
    requestSnapshot()
end

RegisterNetEvent('extraction_lobby:client:open', function(defaultView)
    openUi(defaultView)
end)

RegisterNetEvent('extraction_lobby:client:update', function(snapshot)
    latestSnapshot = snapshot or latestSnapshot

    if uiOpen then
        send('update', {
            snapshot = latestSnapshot or fallbackSnapshot()
        })
    end
end)

RegisterNetEvent('standalone_extraction:client:startRaid', function()
    closeUi()
end)

RegisterNetEvent('standalone_extraction:client:endRaid', function()
    if uiOpen then
        requestSnapshot()
    end
end)

RegisterCommand('extractionlobby', function()
    openUi('deploy')
end, false)

RegisterNUICallback('close', function(_, cb)
    closeUi()
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    requestSnapshot()
    cb({ ok = true })
end)

RegisterNUICallback('startRaid', function(_, cb)
    closeUi()
    TriggerServerEvent('standalone_extraction:server:joinRaid')
    cb({ ok = true })
end)

RegisterNUICallback('openInventory', function(_, cb)
    closeUi()
    TriggerServerEvent('standalone_extraction:server:requestInventory', true)
    cb({ ok = true })
end)

RegisterNUICallback('sellLoot', function(_, cb)
    TriggerServerEvent('standalone_extraction:server:sellSecuredLoot')

    CreateThread(function()
        Wait(350)
        requestSnapshot()
    end)

    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    closeUi()
end)

CreateThread(function()
    closeUi()
end)
