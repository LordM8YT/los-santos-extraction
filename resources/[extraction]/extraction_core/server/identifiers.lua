ExtractionCoreServer = ExtractionCoreServer or {}
ExtractionCoreServer.Identifiers = {}

local function splitIdentifier(identifier)
    local identifierType, value = tostring(identifier):match('([^:]+):(.+)')
    return identifierType, value
end

local function getIdentifiersByType(source)
    local byType = {}
    local all = GetPlayerIdentifiers(source) or {}

    for _, identifier in ipairs(all) do
        local identifierType = splitIdentifier(identifier)
        if identifierType and not byType[identifierType] then
            byType[identifierType] = identifier
        end
    end

    return all, byType
end

function ExtractionCoreServer.Identifiers.GetSnapshot(source)
    local all, byType = getIdentifiersByType(source)
    local primary

    for _, identifierType in ipairs(ExtractionCoreConfig.Identifiers.preferred) do
        if byType[identifierType] then
            primary = byType[identifierType]
            break
        end
    end

    primary = primary or all[1]

    return {
        source = source,
        name = GetPlayerName(source),
        primary = primary,
        all = all,
        byType = byType,
    }
end

function ExtractionCoreServer.Identifiers.GetPrimary(source)
    return ExtractionCoreServer.Identifiers.GetSnapshot(source).primary
end

exports('GetIdentifierSnapshot', function(source)
    return ExtractionCoreServer.Identifiers.GetSnapshot(source)
end)

exports('GetPrimaryIdentifier', function(source)
    return ExtractionCoreServer.Identifiers.GetPrimary(source)
end)
