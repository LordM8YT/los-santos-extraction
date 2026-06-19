exports('GetItem', function(itemName)
    return ExtractionItems.GetItem(itemName)
end)

exports('GetItems', function()
    return ExtractionItems.GetItems()
end)

exports('GetLootTable', function(tier)
    return ExtractionItems.GetLootTable(tier)
end)

exports('GetContainerTemplate', function(templateId)
    return ExtractionItems.GetContainerTemplate(templateId)
end)

exports('GetContainerTemplates', function()
    return ExtractionItems.GetContainerTemplates()
end)