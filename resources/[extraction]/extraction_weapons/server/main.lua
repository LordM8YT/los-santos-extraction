exports('GetItem', function(itemName)
    return ExtractionWeapons.GetItem(itemName)
end)

exports('GetItems', function()
    return ExtractionWeapons.GetItems()
end)

exports('GetLootTable', function(tier)
    return ExtractionWeapons.GetLootTable(tier)
end)
