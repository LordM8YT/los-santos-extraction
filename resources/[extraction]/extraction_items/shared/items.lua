ExtractionItems = {}

ExtractionItems.Items = {
    pistol = {
        label = 'Pistol',
        type = 'weapon',
        image = 'weapon_pistol.png',
        weapon = 'WEAPON_PISTOL',
        ammoItem = 'pistol_ammo',
        weight = 950,
        value = 650,
        stackSize = 1,
        width = 2,
        height = 2,
    },
    pistol_ammo = {
        label = '9mm ammo',
        type = 'ammo',
        image = 'ammo-9.png',
        ammoFor = 'WEAPON_PISTOL',
        weight = 8,
        value = 4,
        stackSize = 60,
        width = 1,
        height = 1,
    },
    scrap = {
        label = 'Scrap Metal',
        type = 'loot',
        image = 'scrap.svg',
        min = 2,
        max = 5,
        weight = 100,
        value = 55,
        stackSize = 20,
        width = 1,
        height = 1,
    },
    electronics = {
        label = 'Electronics',
        type = 'loot',
        image = 'electronics.svg',
        min = 1,
        max = 3,
        weight = 180,
        value = 145,
        stackSize = 10,
        width = 2,
        height = 1,
    },
    meds = {
        label = 'Medical Supplies',
        type = 'loot',
        image = 'medikit.png',
        min = 1,
        max = 2,
        weight = 220,
        value = 210,
        stackSize = 5,
        width = 1,
        height = 2,
    },
    intel = {
        label = 'Intel',
        type = 'loot',
        image = 'intel.svg',
        min = 1,
        max = 1,
        weight = 60,
        value = 450,
        stackSize = 5,
        width = 1,
        height = 1,
    },
    weapon_parts = {
        label = 'Weapon Parts',
        type = 'loot',
        image = 'weapon_parts.svg',
        min = 1,
        max = 2,
        weight = 250,
        value = 285,
        stackSize = 10,
        width = 2,
        height = 1,
    },
    valuables = {
        label = 'Valuables',
        type = 'loot',
        image = 'valuables.svg',
        min = 1,
        max = 2,
        weight = 140,
        value = 320,
        stackSize = 10,
        width = 1,
        height = 1,
    },
}

ExtractionItems.LootTables = {
    low = {
        { name = 'scrap', weight = 42 },
        { name = 'electronics', weight = 24 },
        { name = 'meds', weight = 14 },
        { name = 'weapon_parts', weight = 10 },
        { name = 'valuables', weight = 8 },
        { name = 'intel', weight = 2 },
    },
    mid = {
        { name = 'scrap', weight = 20 },
        { name = 'electronics', weight = 28 },
        { name = 'meds', weight = 18 },
        { name = 'weapon_parts', weight = 16 },
        { name = 'valuables', weight = 12 },
        { name = 'intel', weight = 6 },
    },
    high = {
        { name = 'scrap', weight = 10 },
        { name = 'electronics', weight = 20 },
        { name = 'meds', weight = 18 },
        { name = 'weapon_parts', weight = 22 },
        { name = 'valuables', weight = 18 },
        { name = 'intel', weight = 12 },
    }
}

ExtractionItems.ContainerTemplates = {
    stash_basic = {
        label = 'Basic Stash',
        width = 10,
        height = 20,
        monetizationTier = nil,
    },
    stash_plus = {
        label = 'Expanded Stash',
        width = 12,
        height = 24,
        monetizationTier = 'stash_tier_plus',
    },
    raid_bag_basic = {
        label = 'Field Bag',
        width = 5,
        height = 6,
        monetizationTier = nil,
    },
    loadout = {
        label = 'Loadout',
        width = 6,
        height = 4,
        monetizationTier = nil,
    },
}

function ExtractionItems.GetItem(itemName)
    return ExtractionItems.Items[itemName]
end

function ExtractionItems.GetItems()
    return ExtractionItems.Items
end

function ExtractionItems.GetLootTable(tier)
    return ExtractionItems.LootTables[tier or 'low'] or ExtractionItems.LootTables.low
end

function ExtractionItems.GetContainerTemplate(templateId)
    return ExtractionItems.ContainerTemplates[templateId]
end

function ExtractionItems.GetContainerTemplates()
    return ExtractionItems.ContainerTemplates
end