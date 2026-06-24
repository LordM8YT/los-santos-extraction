LSX.Server = LSX.Server or {}
LSX.Server.Identifiers = {}

local function splitIdentifier(identifier)
    local identifierType = tostring(identifier):match('([^:]+):')
    return identifierType
end

function LSX.Server.Identifiers.GetSnapshot(source)
    local all = GetPlayerIdentifiers(source) or {}
    local byType = {}

    for _, identifier in ipairs(all) do
        local identifierType = splitIdentifier(identifier)

        if identifierType and not byType[identifierType] then
            byType[identifierType] = identifier
        end
    end

    local primary

    for _, identifierType in ipairs(LSXConfig.Identifiers.preferred) do
        if byType[identifierType] then
            primary = byType[identifierType]
            break
        end
    end

    return {
        source = source,
        name = GetPlayerName(source),
        primary = primary or all[1] or ('source:%s'):format(source),
        all = all,
        byType = byType,
    }
end

function LSX.Server.Identifiers.GetPrimary(source)
    return LSX.Server.Identifiers.GetSnapshot(source).primary
end
