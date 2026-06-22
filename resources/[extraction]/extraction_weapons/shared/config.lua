ExtractionWeapons = ExtractionWeapons or {}

-- Vanilla GTA weapons first. Add-on weapon packs can be added here later without
-- changing the raid, trader or inventory resources.
ExtractionWeapons.Items = {
    combat_pistol = {
        label = 'Combat Pistol',
        type = 'weapon',
        image = 'lsx_combat_pistol.png',
        weapon = 'WEAPON_COMBATPISTOL',
        ammoItem = 'pistol_ammo',
        weight = 1050,
        value = 950,
        min = 1,
        max = 1,
        stackSize = 1,
        width = 2,
        height = 2,
        weaponClass = 'sidearm',
        lootTier = 'mid',
    },
    smg = {
        label = 'SMG',
        type = 'weapon',
        image = 'lsx_smg.png',
        weapon = 'WEAPON_SMG',
        ammoItem = 'smg_ammo',
        weight = 2400,
        value = 1850,
        min = 1,
        max = 1,
        stackSize = 1,
        width = 3,
        height = 2,
        weaponClass = 'primary',
        lootTier = 'high',
    },
    pump_shotgun = {
        label = 'Pump Shotgun',
        type = 'weapon',
        image = 'lsx_shotgun.png',
        weapon = 'WEAPON_PUMPSHOTGUN',
        ammoItem = 'shotgun_ammo',
        weight = 2900,
        value = 2300,
        min = 1,
        max = 1,
        stackSize = 1,
        width = 4,
        height = 2,
        weaponClass = 'primary',
        lootTier = 'high',
    },
    carbine_rifle = {
        label = 'Carbine Rifle',
        type = 'weapon',
        image = 'lsx_rifle.png',
        weapon = 'WEAPON_CARBINERIFLE',
        ammoItem = 'rifle_ammo',
        weight = 3100,
        value = 3200,
        min = 1,
        max = 1,
        stackSize = 1,
        width = 4,
        height = 2,
        weaponClass = 'primary',
        lootTier = 'high',
    },
    smg_ammo = {
        label = 'SMG Ammo',
        type = 'ammo',
        image = 'lsx_smg_ammo.png',
        ammoFor = 'WEAPON_SMG',
        weight = 10,
        value = 6,
        min = 18,
        max = 36,
        stackSize = 90,
        width = 1,
        height = 1,
        lootTier = 'mid',
    },
    shotgun_ammo = {
        label = 'Shotgun Shells',
        type = 'ammo',
        image = 'lsx_shotgun_ammo.png',
        ammoFor = 'WEAPON_PUMPSHOTGUN',
        weight = 18,
        value = 9,
        min = 6,
        max = 14,
        stackSize = 40,
        width = 1,
        height = 1,
        lootTier = 'high',
    },
    rifle_ammo = {
        label = 'Rifle Ammo',
        type = 'ammo',
        image = 'lsx_rifle_ammo.png',
        ammoFor = 'WEAPON_CARBINERIFLE',
        weight = 12,
        value = 8,
        min = 20,
        max = 40,
        stackSize = 120,
        width = 1,
        height = 1,
        lootTier = 'high',
    },
}

ExtractionWeapons.LootTables = {
    low = {
        { name = 'pistol_ammo', weight = 7 },
    },
    mid = {
        { name = 'combat_pistol', weight = 4 },
        { name = 'pistol_ammo', weight = 12 },
        { name = 'smg_ammo', weight = 6 },
    },
    high = {
        { name = 'combat_pistol', weight = 8 },
        { name = 'smg', weight = 5 },
        { name = 'pump_shotgun', weight = 4 },
        { name = 'carbine_rifle', weight = 2 },
        { name = 'pistol_ammo', weight = 10 },
        { name = 'smg_ammo', weight = 10 },
        { name = 'shotgun_ammo', weight = 8 },
        { name = 'rifle_ammo', weight = 6 },
    },
}

function ExtractionWeapons.GetItem(itemName)
    return ExtractionWeapons.Items[itemName]
end

function ExtractionWeapons.GetItems()
    return ExtractionWeapons.Items
end

function ExtractionWeapons.GetLootTable(tier)
    return ExtractionWeapons.LootTables[tier or 'low'] or {}
end
