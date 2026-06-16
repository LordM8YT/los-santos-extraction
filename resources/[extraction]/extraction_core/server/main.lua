local function buildStatus(source)
    return {
        resource = GetCurrentResourceName(),
        project = ExtractionCoreConfig.Runtime.projectName,
        version = ExtractionCoreConfig.Runtime.version,
        raidStates = ExtractionCoreShared.DeepCopy(ExtractionCoreConstants.RaidState),
        buckets = ExtractionCoreServer.Buckets.GetStats(),
        player = source and ExtractionCoreServer.Identifiers.GetSnapshot(source) or nil,
    }
end

lib.callback.register('extraction_core:server:getStatus', function(source)
    return buildStatus(source)
end)

exports('GetStatus', function()
    return buildStatus()
end)

AddEventHandler('playerDropped', function(reason)
    local source = source

    TriggerEvent(ExtractionCoreConstants.Events.PlayerDropped, source, reason)
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    ExtractionCoreServer.Logger.Info('Core foundation started.', {
        version = ExtractionCoreConfig.Runtime.version,
        bucketBase = ExtractionCoreConfig.Buckets.raidBase,
        bucketRange = ExtractionCoreConfig.Buckets.raidRange,
    })

    TriggerEvent(ExtractionCoreConstants.Events.CoreReady, buildStatus())
end)
