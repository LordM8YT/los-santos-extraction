ExtractionCoreShared = {}

function ExtractionCoreShared.DeepCopy(value, seen)
    if type(value) ~= 'table' then
        return value
    end

    seen = seen or {}
    if seen[value] then
        return seen[value]
    end

    local copy = {}
    seen[value] = copy

    for key, item in pairs(value) do
        copy[ExtractionCoreShared.DeepCopy(key, seen)] = ExtractionCoreShared.DeepCopy(item, seen)
    end

    return copy
end

function ExtractionCoreShared.TableSize(value)
    if type(value) ~= 'table' then
        return 0
    end

    local count = 0
    for _ in pairs(value) do
        count = count + 1
    end

    return count
end

function ExtractionCoreShared.Clamp(value, minimum, maximum)
    value = tonumber(value) or minimum

    if value < minimum then
        return minimum
    end

    if value > maximum then
        return maximum
    end

    return value
end
