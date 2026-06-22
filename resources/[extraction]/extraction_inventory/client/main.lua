local uiOpen = false
local latestSnapshot
local raidActive = false
local closeUi

local function getFallbackSnapshot()
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

local function sendSnapshot(snapshot, shouldOpen)
    latestSnapshot = snapshot or latestSnapshot

    SendNUIMessage({
        action = shouldOpen and 'open' or 'update',
        snapshot = latestSnapshot or getFallbackSnapshot()
    })
end

local function openUi()
    if not raidActive then
        closeUi()
        TriggerEvent('extraction_lobby:client:open', 'loadout')
        return
    end

    if uiOpen then
        TriggerServerEvent('standalone_extraction:server:requestInventory', false)
        return
    end

    uiOpen = true
    SetNuiFocus(true, true)
    sendSnapshot(latestSnapshot or getFallbackSnapshot(), true)
    TriggerServerEvent('standalone_extraction:server:requestInventory', false)
end

function closeUi()
    if not uiOpen then
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        return
    end

    uiOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

RegisterCommand('extractinv', function()
    if uiOpen then
        closeUi()
        return
    end

    -- Server snapshot is authoritative; local raid state can be stale during transitions.
    TriggerServerEvent('standalone_extraction:server:requestInventory', true)
end, false)

RegisterKeyMapping('extractinv', 'Open extraction inventory', 'keyboard', 'I')

RegisterNetEvent('standalone_extraction:client:openInventory', function(snapshot)
    latestSnapshot = snapshot or latestSnapshot

    if latestSnapshot and latestSnapshot.raidActive ~= nil then
        raidActive = latestSnapshot.raidActive == true
    end

    openUi()
end)

RegisterNetEvent('standalone_extraction:client:updateInventory', function(snapshot)
    latestSnapshot = snapshot or latestSnapshot

    if latestSnapshot and latestSnapshot.raidActive ~= nil then
        raidActive = latestSnapshot.raidActive == true
    end

    if uiOpen then
        sendSnapshot(latestSnapshot, false)
    end
end)

RegisterNetEvent('standalone_extraction:client:startRaid', function()
    raidActive = true
end)

RegisterNetEvent('standalone_extraction:client:endRaid', function()
    raidActive = false
    closeUi()
end)

RegisterNUICallback('close', function(_, cb)
    closeUi()
    cb({ ok = true })
end)

RegisterNUICallback('refresh', function(_, cb)
    TriggerServerEvent('standalone_extraction:server:requestInventory', false)
    cb({ ok = true })
end)

RegisterNUICallback('sellAll', function(_, cb)
    TriggerServerEvent('standalone_extraction:server:sellSecuredLoot')
    cb({ ok = true })
end)

RegisterNUICallback('dropItem', function(data, cb)
    TriggerServerEvent('standalone_extraction:server:discardCarryItem', data.itemName, 1)
    cb({ ok = true })
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    closeUi()
end)

CreateThread(function()
    uiOpen = false
    raidActive = false
    latestSnapshot = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end)
