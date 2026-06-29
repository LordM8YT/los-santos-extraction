local activeTimecycle

local function applyWeather(weather)
    weather = weather or PlatformConfig.DefaultTimecycle.weather

    ClearOverrideWeather()
    ClearWeatherTypePersist()
    SetWeatherTypeNow(weather)
    SetWeatherTypeNowPersist(weather)
    SetOverrideWeather(weather)
end

local function applyClock(profile)
    NetworkOverrideClockTime(profile.hour, profile.minute, profile.second)
    PauseClock(profile.freezeClock == true)
    SetArtificialLightsState(profile.artificialLights == true)
end

RegisterNetEvent('lsx_platform:client:applyTimecycle', function(profile)
    profile = type(profile) == 'table' and profile or PlatformConfig.DefaultTimecycle
    activeTimecycle = profile

    applyWeather(profile.weather)
    applyClock(profile)
end)

RegisterNetEvent('lsx_platform:client:resetTimecycle', function()
    activeTimecycle = nil

    PauseClock(false)
    SetArtificialLightsState(false)
    ClearOverrideWeather()
    ClearWeatherTypePersist()
end)

exports('GetActiveTimecycle', function()
    return activeTimecycle
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    TriggerEvent('lsx_platform:client:resetTimecycle')
end)
