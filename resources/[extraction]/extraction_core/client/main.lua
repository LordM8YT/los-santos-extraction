ExtractionCoreClient = {}

function ExtractionCoreClient.GetSharedConfig()
    return ExtractionCoreShared.DeepCopy(ExtractionCoreConfig)
end

function ExtractionCoreClient.GetConstants()
    return ExtractionCoreShared.DeepCopy(ExtractionCoreConstants)
end

exports('GetSharedConfig', function()
    return ExtractionCoreClient.GetSharedConfig()
end)

exports('GetConstants', function()
    return ExtractionCoreClient.GetConstants()
end)

AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName ~= GetCurrentResourceName() or not ExtractionCoreConfig.Debug then
        return
    end

    print(('[%s] Client foundation started.'):format(GetCurrentResourceName()))
end)
