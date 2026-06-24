local uiOpen = false
local latestSnapshot
local raidActive = false
local settingsKvpKey = 'extraction_lobby:client_settings'

local clientSettings = {
    minimapMode = 'always',
    hudDensity = 'full',
    firstPersonMode = 'raid',
    crosshairMode = 'dynamic',
    helmetOverlay = 'on',
}

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

local function isOxInventoryActive()
    return GetResourceState('ox_inventory') == 'started'
end

local function loadSettings()
    local encoded = GetResourceKvpString(settingsKvpKey)

    if not encoded or encoded == '' then
        return
    end

    local ok, decoded = pcall(json.decode, encoded)
    if not ok or type(decoded) ~= 'table' then
        return
    end

    clientSettings.minimapMode = decoded.minimapMode or clientSettings.minimapMode
    clientSettings.hudDensity = decoded.hudDensity or clientSettings.hudDensity
    clientSettings.firstPersonMode = decoded.firstPersonMode or clientSettings.firstPersonMode
    clientSettings.crosshairMode = decoded.crosshairMode or clientSettings.crosshairMode
    clientSettings.helmetOverlay = decoded.helmetOverlay or clientSettings.helmetOverlay
end

local function saveSettings()
    SetResourceKvp(settingsKvpKey, json.encode(clientSettings))
end

local function syncHudSettings()
    TriggerEvent('extraction_hud:client:setSettings', clientSettings)
end

local function updateSetting(key, value)
    if key == 'minimapMode' and (value == 'vehicle' or value == 'always' or value == 'off') then
        clientSettings.minimapMode = value
    elseif key == 'hudDensity' and (value == 'full' or value == 'minimal') then
        clientSettings.hudDensity = value
    elseif key == 'firstPersonMode' and (value == 'raid' or value == 'off') then
        clientSettings.firstPersonMode = value
    elseif key == 'crosshairMode' and (value == 'dynamic' or value == 'off') then
        clientSettings.crosshairMode = value
    elseif key == 'helmetOverlay' and (value == 'on' or value == 'off') then
        clientSettings.helmetOverlay = value
    else
        return false
    end

    saveSettings()
    syncHudSettings()
    send('settings', clientSettings)
    return true
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

    if raidActive then
        closeUi()
        TriggerServerEvent('standalone_extraction:server:requestInventory', true)
        return
    end

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
        settings = clientSettings,
        inventoryProvider = isOxInventoryActive() and 'ox' or 'legacy',
    })
    requestSnapshot()
    syncHudSettings()
end

RegisterNetEvent('extraction_lobby:client:open', function(defaultView)
    openUi(defaultView)
end)

RegisterNetEvent('extraction_lobby:client:update', function(snapshot)
    latestSnapshot = snapshot or latestSnapshot
    raidActive = latestSnapshot and latestSnapshot.raidActive == true or raidActive

    if raidActive then
        closeUi()
        TriggerServerEvent('standalone_extraction:server:requestInventory', true)
        return
    end

    if uiOpen then
        send('update', {
            snapshot = latestSnapshot or fallbackSnapshot(),
            inventoryProvider = isOxInventoryActive() and 'ox' or 'legacy',
        })
    end
end)

RegisterNetEvent('standalone_extraction:client:startRaid', function()
    raidActive = true
    closeUi()
end)

RegisterNetEvent('standalone_extraction:client:endRaid', function()
    raidActive = false

    if uiOpen then
        requestSnapshot()
    end
end)

RegisterCommand('extractionlobby', function()
    openUi('deploy')
end, false)

RegisterNUICallback('close', function(_, cb)
    closeUi()
    TriggerEvent('standalone_extraction:client:lobbyClosedByUser')
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

RegisterNUICallback('logout', function(_, cb)
    closeUi()
    TriggerServerEvent('standalone_extraction:server:logout')
    cb({ ok = true })
end)

RegisterNUICallback('openInventory', function(_, cb)
    if isOxInventoryActive() then
        closeUi()
        exports.ox_inventory:openInventory()
    else
        send('setView', { view = 'loadout' })
        requestSnapshot()
    end

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

RegisterNUICallback('buyTraderItem', function(data, cb)
    if data and data.itemName then
        TriggerServerEvent('standalone_extraction:server:buyTraderItem', data.itemName, data.quantity or 1)

        CreateThread(function()
            Wait(350)
            requestSnapshot()
        end)
    end

    cb({ ok = true })
end)

RegisterNUICallback('claimQuest', function(data, cb)
    if data and data.questId then
        TriggerServerEvent('standalone_extraction:server:claimQuestReward', data.questId)

        CreateThread(function()
            Wait(350)
            requestSnapshot()
        end)
    end

    cb({ ok = true })
end)

RegisterNUICallback('setSetting', function(data, cb)
    local ok = updateSetting(data and data.key, data and data.value)
    cb({ ok = ok, settings = clientSettings })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    closeUi()
end)

CreateThread(function()
    loadSettings()
    syncHudSettings()
    closeUi()
end)
