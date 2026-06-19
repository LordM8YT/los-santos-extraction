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
    spawnDelay = 1500,
    openUiOnJoin = true,
    openUiDelay = 900,
    worldActionsEnabled = false, -- New lobby UI replaces the old hub E-marker menus.
    spawn = vec4(-1037.76, -2737.83, 20.17, 240.0),
    join = {
        coords = vec3(-1040.31, -2732.27, 20.17),
        label = 'Start raid',
        color = { r = 70, g = 170, b = 255, a = 150 }
    },
    trader = {
        coords = vec3(-1033.18, -2734.17, 20.17),
        label = 'Sell secured loot',
        color = { r = 90, g = 255, b = 125, a = 150 }
    },
    stats = {
        coords = vec3(-1039.58, -2741.08, 20.17),
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
        id = 'airport_service_gate',
        label = 'Airport service gate',
        coords = vec3(-1016.72, -3024.92, 13.95),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'lsia_cargo_road',
        label = 'LSIA cargo road',
        coords = vec3(-1133.88, -2436.26, 13.95),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'vespucci_canals_lot',
        label = 'Vespucci canals lot',
        coords = vec3(-1088.72, -1277.36, 5.86),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'del_perro_service_lot',
        label = 'Del Perro service lot',
        coords = vec3(-1607.23, -1002.82, 13.02),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'little_seoul_gas',
        label = 'Little Seoul gas station',
        coords = vec3(-705.31, -916.15, 19.22),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'rockford_backstreet',
        label = 'Rockford backstreet',
        coords = vec3(-622.29, -232.81, 38.06),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'alta_parking_exit',
        label = 'Alta parking exit',
        coords = vec3(-267.56, -961.44, 31.22),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'legion_square_garage',
        label = 'Legion Square garage',
        coords = vec3(215.65, -810.12, 30.73),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'pillbox_ambulance_bay',
        label = 'Pillbox ambulance bay',
        coords = vec3(322.23, -583.84, 43.28),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'hawick_side_street',
        label = 'Hawick side street',
        coords = vec3(304.18, -202.73, 54.22),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'strawberry_service_station',
        label = 'Strawberry service station',
        coords = vec3(288.59, -1266.26, 29.44),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'davis_mega_mall',
        label = 'Davis mega mall',
        coords = vec3(45.62, -1748.01, 29.60),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'rancho_rail_pullout',
        label = 'Rancho rail pullout',
        coords = vec3(492.16, -1510.72, 29.29),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'cypress_loading_exit',
        label = 'Cypress loading exit',
        coords = vec3(852.24, -2118.46, 30.52),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'la_mesa_service_road',
        label = 'La Mesa service road',
        coords = vec3(945.77, -1255.72, 25.54),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'mirror_park_lakeside',
        label = 'Mirror Park lakeside',
        coords = vec3(1077.18, -711.56, 58.22),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'east_vinewood_depot',
        label = 'East Vinewood depot',
        coords = vec3(889.74, -179.56, 74.70),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'murrieta_heights_store',
        label = 'Murrieta Heights store',
        coords = vec3(1123.74, -475.36, 66.49),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'el_burro_overlook',
        label = 'El Burro overlook',
        coords = vec3(1375.04, -1530.37, 57.12),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'murrieta_oilfield',
        label = 'Murrieta oilfield road',
        coords = vec3(1563.86, -2165.83, 77.42),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'docks_north_gate',
        label = 'Docks north gate',
        coords = vec3(1192.04, -2962.69, 5.90),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'terminal_service_exit',
        label = 'Terminal service exit',
        coords = vec3(884.85, -3186.74, 5.90),
        color = { r = 110, g = 255, b = 150, a = 155 }
    },
    {
        id = 'storm_drain_pullout',
        label = 'Storm drain pullout',
        coords = vec3(1016.65, -2327.69, 30.51),
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
