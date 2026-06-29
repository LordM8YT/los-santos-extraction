local CREATOR_CONFIG = {
    Ped = true,
    HeadBlend = true,
    FaceFeatures = true,
    HeadOverlays = true,
    Components = true,
    Props = true,
    Tattoos = true,
}

local function isIlleniumReady()
    return GetResourceState('illenium-appearance') == 'started'
end

local function notify(message)
    if GetResourceState('extraction_hud') == 'started' then
        TriggerEvent('extraction_hud:client:notify', message, 'info')
        return
    end

    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, true)
end

local function openCreator()
    if not isIlleniumReady() then
        notify('Advanced appearance creator is not installed yet. Use Male/Female for now.')
        return false
    end

    local ok = pcall(function()
        exports['illenium-appearance']:startPlayerCustomization(function(appearance)
            if not appearance then
                notify('Appearance edit cancelled.')
                return
            end

            TriggerServerEvent('extraction_character:server:createOrUpdate', {
                model = appearance.model,
                appearance = appearance,
            })
        end, CREATOR_CONFIG)
    end)

    if not ok then
        notify('Could not open advanced appearance creator.')
        return false
    end

    return true
end

RegisterNetEvent('lsx_appearance:client:openCreator', openCreator)

exports('OpenCreator', openCreator)
