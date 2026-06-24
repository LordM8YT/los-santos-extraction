Config = {}

Config.Debug = false
Config.EnableBlips = true
Config.EnableLootBlips = true
Config.InteractControl = 38 -- E
Config.CancelControl = 177 -- Backspace
Config.DrawDistance = 65.0
Config.InteractDistance = 2.0
Config.ValidationDistance = 6.0
Config.MarkerType = 1
Config.MarkerScale = vec3(0.75, 0.75, 0.35)

Config.Map = {
    extractionBlips = {
        scale = 0.72,
        shortRange = false,
    },
    lootBlips = {
        lowScale = 0.48,
        midScale = 0.56,
        highScale = 0.68,
        lowShortRange = true,
        midShortRange = true,
        highShortRange = false,
    },
    vehicleBlips = {
        scale = 0.54,
        shortRange = true,
    },
}

Config.Population = {
    enabled = true,
    pedestrianDensity = 0.0,
    scenarioPedDensity = 0.0,
    vehicleDensity = 0.0,
    randomVehicleDensity = 0.0,
    parkedVehicleDensity = 0.0,
    randomBoats = false,
    garbageTrucks = false,
    randomCops = false,
    dispatchServices = false,
}

Config.Lobby = {
    spawnOnJoin = true,
    spawnDelay = 250,
    openUiOnJoin = true,
    openUiDelay = 350,
    worldActionsEnabled = false, -- New lobby UI replaces the old hub E-marker menus.
    stagingModel = 'mp_m_freemode_01',
    spawn = vec4(1736.92, 3294.24, 41.14, 194.0),
    join = {
        coords = vec3(1734.82, 3290.77, 41.11),
        label = 'Start raid',
        color = { r = 70, g = 170, b = 255, a = 150 }
    },
    trader = {
        coords = vec3(1742.12, 3292.37, 41.11),
        label = 'Sell secured loot',
        color = { r = 90, g = 255, b = 125, a = 150 }
    },
    stats = {
        coords = vec3(1730.65, 3296.78, 41.11),
        label = 'View stash and stats',
        color = { r = 255, g = 215, b = 95, a = 150 }
    }
}

Config.Raid = {
    bucketBase = 5000,
    maxConcurrentRaids = 0, -- 0 = unlimited private raid instances
    durationSeconds = 1500,
    lootTime = 5500,
    extractionTime = 9000,
    deathRespawnDelay = 5000,
    maxCarryWeight = 3500,
    entryFee = 0,
    spawnPoints = {
        vec4(-959.53, -3074.43, 13.95, 58.0),
        vec4(828.48, -2148.55, 29.31, 1.0),
        vec4(918.39, -1261.82, 25.57, 178.0),
        vec4(1209.46, -1260.52, 35.23, 271.0),
        vec4(1187.24, -2991.10, 5.87, 271.0),
        vec4(903.92, -3205.08, 5.90, 359.0),
    }
}

Config.RaidVehicles = {
    enabled = true,
    showBlips = true,
    spawnChance = 1.0,
    blipSprite = 225,
    blipColour = 38,
    spawns = {
        {
            id = 'airport_utility_truck',
            label = 'Airport utility truck',
            model = 'bison',
            coords = vec4(-985.35, -3001.56, 13.95, 58.0),
        },
        {
            id = 'airport_cargo_pickup',
            label = 'Cargo pickup',
            model = 'bobcatxl',
            coords = vec4(-1078.54, -2361.96, 13.95, 151.0),
        },
        {
            id = 'cypress_boxvan',
            label = 'Cypress box van',
            model = 'burrito3',
            coords = vec4(844.18, -2144.54, 29.31, 83.0),
        },
        {
            id = 'cypress_flatbed',
            label = 'Industrial flatbed',
            model = 'sadler',
            coords = vec4(1008.88, -2513.58, 28.30, 86.0),
        },
        {
            id = 'mesa_worker_car',
            label = 'Worker sedan',
            model = 'asea',
            coords = vec4(930.46, -1245.70, 25.53, 88.0),
        },
        {
            id = 'docks_yard_truck',
            label = 'Docks yard truck',
            model = 'bison',
            coords = vec4(1180.74, -2978.86, 5.90, 271.0),
        },
        {
            id = 'terminal_van',
            label = 'Terminal van',
            model = 'speedo',
            coords = vec4(888.34, -3201.93, 5.90, 181.0),
        },
        {
            id = 'oilfield_rancher',
            label = 'Oilfield rancher',
            model = 'rancherxl',
            coords = vec4(1540.18, -2168.24, 77.30, 270.0),
        },
    }
}

Config.Progression = {
    xpPerValue = 0.18,
    xpPerLevel = 700,
}

Config.StarterKit = {
    enabled = true,
    version = 2,
    cash = 500,
    stash = {
        scrap = 6,
        meds = 2,
        electronics = 1,
        pistol = 1,
        pistol_ammo = 48,
    }
}

Config.Items = {
    pistol = {
        label = 'Pistol',
        type = 'weapon',
        weapon = 'WEAPON_PISTOL',
        ammoItem = 'pistol_ammo',
        weight = 950,
        value = 650,
    },
    pistol_ammo = {
        label = '9mm ammo',
        type = 'ammo',
        ammoFor = 'WEAPON_PISTOL',
        weight = 8,
        value = 4,
    },
    scrap = {
        label = 'Scrap Metal',
        type = 'loot',
        min = 2,
        max = 5,
        weight = 100,
        value = 55,
    },
    electronics = {
        label = 'Electronics',
        type = 'loot',
        min = 1,
        max = 3,
        weight = 180,
        value = 145,
    },
    meds = {
        label = 'Medical Supplies',
        type = 'loot',
        min = 1,
        max = 2,
        weight = 220,
        value = 210,
    },
    intel = {
        label = 'Intel',
        type = 'loot',
        min = 1,
        max = 1,
        weight = 60,
        value = 450,
    },
    weapon_parts = {
        label = 'Weapon Parts',
        type = 'loot',
        min = 1,
        max = 2,
        weight = 250,
        value = 285,
    },
    valuables = {
        label = 'Valuables',
        type = 'loot',
        min = 1,
        max = 2,
        weight = 140,
        value = 320,
    }
}

Config.LootTables = {
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

Config.Extractions = {
    {
        id = 'lsia_service_gate',
        label = 'LSIA service gate',
        coords = vec3(-1031.18, -2734.62, 20.17),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'storm_drain_canal',
        label = 'Storm drain canal',
        coords = vec3(714.28, -2057.53, 29.31),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'la_puerta_channel',
        label = 'La Puerta channel',
        coords = vec3(-794.44, -1286.35, 5.15),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'del_perro_lifeguard_boat',
        label = 'Del Perro lifeguard boat',
        coords = vec3(-1837.87, -1224.21, 13.02),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'great_ocean_highway_ramp',
        label = 'Great Ocean highway ramp',
        coords = vec3(-2194.92, -388.28, 13.31),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'vinewood_hills_escape_road',
        label = 'Vinewood hills escape road',
        coords = vec3(-545.47, 501.19, 105.08),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'east_vinewood_tunnel',
        label = 'East Vinewood tunnel',
        coords = vec3(764.04, -120.34, 74.09),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'olympic_freeway_underpass',
        label = 'Olympic freeway underpass',
        coords = vec3(594.66, -1697.78, 25.95),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'rancho_rail_tunnel',
        label = 'Rancho rail tunnel',
        coords = vec3(431.83, -1770.19, 28.73),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'elysian_island_ferry_ramp',
        label = 'Elysian Island ferry ramp',
        coords = vec3(495.36, -3330.42, 6.07),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'terminal_breakwater',
        label = 'Terminal breakwater',
        coords = vec3(1294.62, -3348.54, 5.90),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'docks_north_gate',
        label = 'Docks north gate',
        coords = vec3(1192.04, -2962.69, 5.90),
        color = { r = 110, g = 255, b = 150, a = 155 }
    }
}

Config.Strings = {
    join_raid = 'Start raid',
    sell_loot = 'Sell secured loot',
    open_stats = 'View stash and stats',
    loot_progress = 'Searching cache',
    extract_progress = 'Extracting loot',
    cancelled = 'Action cancelled.',
    bag_full = 'Your bag is full. Extract or prioritize better loot.',
    not_in_raid = 'You are not in an active raid.',
    already_in_raid = 'You are already in an active raid.',
    raid_starting = 'Your raid is already starting. Wait a moment.',
    too_many_active_raids = 'The server has too many active raids right now. Try again shortly.',
    no_loot_spots = 'Loot system is not ready yet. Make sure extraction_world is started.',
    area_hot = 'The area is still hot. Clear the guards before searching this cache.',
    no_secured_loot = 'You do not have any secured loot to sell.',
    no_loot_to_extract = 'You cannot secure an empty bag. Loot something or use /raidleave.',
    extracted = 'You extracted and secured your loot.',
    died = 'You died in raid and lost everything you were carrying.',
    timed_out = 'Time ran out. You lost any loot you did not secure.',
    left_raid = 'You left the raid and lost carried loot.',
    nothing_to_drop = 'You do not have that many of this item.',
    starter_weapon_given = 'You brought a pistol and ammo into the raid.',
}
