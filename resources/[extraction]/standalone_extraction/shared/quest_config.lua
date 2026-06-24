QuestConfig = {}

QuestConfig.StaticContracts = {
    {
        id = 'first_blood_sample',
        title = 'First Blood Sample',
        category = 'Medical',
        description = 'Secure medical supplies and deliver them to the safehouse.',
        objective = {
            type = 'stash_item',
            item = 'meds',
            count = 1,
        },
        rewards = {
            cash = 750,
            xp = 150,
            items = {
                pistol_ammo = 24,
            },
        },
    },
    {
        id = 'find_the_signal',
        title = 'Find The Signal',
        category = 'Intel',
        description = 'Extract Intel from the city and start building network trust.',
        objective = {
            type = 'stash_item',
            item = 'intel',
            count = 1,
        },
        rewards = {
            cash = 1200,
            xp = 260,
            items = {
                meds = 1,
                weapon_parts = 1,
            },
        },
    },
}

QuestConfig.DailyContracts = {
    enabled = true,
    count = 3,
    rotationSeconds = 86400,
    pool = {
        {
            key = 'scrap_drive',
            title = 'Scrap Drive',
            category = 'Daily Salvage',
            description = 'Build material reserves by extracting scrap from low-risk caches.',
            objective = { type = 'stash_item', item = 'scrap', count = 10 },
            rewards = { cash = 650, xp = 120, items = { pistol_ammo = 12 } },
        },
        {
            key = 'clinic_run',
            title = 'Clinic Run',
            category = 'Daily Medical',
            description = 'Stockpile field meds for future deployments.',
            objective = { type = 'stash_item', item = 'meds', count = 3 },
            rewards = { cash = 900, xp = 180, items = { pistol_ammo = 18 } },
        },
        {
            key = 'signal_cache',
            title = 'Signal Cache',
            category = 'Daily Intel',
            description = 'Pull usable intel from guarded city routes.',
            objective = { type = 'stash_item', item = 'intel', count = 2 },
            rewards = { cash = 1400, xp = 280, items = { meds = 1 } },
        },
        {
            key = 'parts_manifest',
            title = 'Parts Manifest',
            category = 'Daily Weapons',
            description = 'Recover weapon parts for the safehouse armoury.',
            objective = { type = 'stash_item', item = 'weapon_parts', count = 3 },
            rewards = { cash = 1250, xp = 240, items = { pistol_ammo = 24 } },
        },
        {
            key = 'electronics_sweep',
            title = 'Electronics Sweep',
            category = 'Daily Tech',
            description = 'Extract electronics before the network loses the trail.',
            objective = { type = 'stash_item', item = 'electronics', count = 4 },
            rewards = { cash = 1100, xp = 220, items = { meds = 1 } },
        },
    },
}
