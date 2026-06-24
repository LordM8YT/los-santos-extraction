LSX = LSX or {}
LSX.Utils = LSX.Utils or {}

function LSX.Utils.Copy(value)
    if type(value) ~= 'table' then
        return value
    end

    local copy = {}

    for key, item in pairs(value) do
        copy[key] = LSX.Utils.Copy(item)
    end

    return copy
end

function LSX.Utils.TableSize(value)
    local count = 0

    if type(value) ~= 'table' then
        return count
    end

    for _ in pairs(value) do
        count = count + 1
    end

    return count
end

function LSX.Utils.Clamp(value, min, max)
    value = tonumber(value) or 0

    if value < min then return min end
    if value > max then return max end

    return value
end

function LSX.Utils.Debug(message, data)
    if not LSXConfig.Debug then return end

    if data ~= nil then
        print(('[lsx_core] %s %s'):format(message, json.encode(data)))
    else
        print(('[lsx_core] %s'):format(message))
    end
end
