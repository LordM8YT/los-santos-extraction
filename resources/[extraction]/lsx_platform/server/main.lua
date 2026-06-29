local function copyTable(value)
    if type(value) ~= 'table' then
        return value
    end

    local copy = {}
    for key, child in pairs(value) do
        copy[key] = copyTable(child)
    end

    return copy
end

local function getWeightedProfile(profiles)
    local totalWeight = 0

    for _, profile in ipairs(profiles) do
        totalWeight = totalWeight + math.max(0, tonumber(profile.weight) or 1)
    end

    if totalWeight <= 0 then
        return profiles[1]
    end

    local roll = math.random() * totalWeight
    local running = 0

    for _, profile in ipairs(profiles) do
        running = running + math.max(0, tonumber(profile.weight) or 1)
        if roll <= running then
            return profile
        end
    end

    return profiles[#profiles]
end

local function normalizeTimecycle(profile)
    local fallback = PlatformConfig.DefaultTimecycle
    profile = type(profile) == 'table' and profile or fallback

    return {
        id = profile.id or fallback.id,
        label = profile.label or fallback.label,
        hour = math.max(0, math.min(23, math.floor(tonumber(profile.hour) or fallback.hour))),
        minute = math.max(0, math.min(59, math.floor(tonumber(profile.minute) or fallback.minute))),
        second = math.max(0, math.min(59, math.floor(tonumber(profile.second) or fallback.second or 0))),
        weather = profile.weather or fallback.weather,
        freezeClock = profile.freezeClock ~= false,
        artificialLights = profile.artificialLights == true,
    }
end

local function selectRaidTimecycle(config)
    config = type(config) == 'table' and config or {}

    if config.enabled == false then
        return normalizeTimecycle(config.default or PlatformConfig.DefaultTimecycle)
    end

    local profiles = type(config.profiles) == 'table' and config.profiles or {}
    if #profiles == 0 then
        return normalizeTimecycle(config.default or PlatformConfig.DefaultTimecycle)
    end

    return normalizeTimecycle(copyTable(getWeightedProfile(profiles)))
end

exports('SelectRaidTimecycle', selectRaidTimecycle)
