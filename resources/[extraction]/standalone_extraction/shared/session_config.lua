SessionConfig = {}

SessionConfig.Matchmaking = {
    enabled = true,
    minPlayers = 1,
    maxPlayers = 4,
    queueTickMs = 1500,
}

SessionConfig.Extractions = {
    pointsPerSession = 3,
    zoneHoldMs = 10000,
    defaultRadius = 6.0,
    pointOverrides = {
        Cargo_Ship = {
            durationMs = 22000,
            radius = 7.5,
            danger = 'medium',
        },
        Motorway_Drain = {
            durationMs = 14000,
            radius = 5.5,
            danger = 'low',
        },
        Motor_Way = {
            durationMs = 18000,
            radius = 7.0,
            danger = 'medium',
        },
    },
}

SessionConfig.Spawning = {
    avoidHighTierLoot = true,
    avoidGuardZones = true,
    avoidExtractions = true,
    highTierMinDistance = 260.0,
    guardZoneMinDistance = 180.0,
    extractionMinDistance = 180.0,
    fallbackToBestScoredSpawn = true,
}

SessionConfig.DeathDrops = {
    enabled = true,
    ttlSeconds = 900,
    crateModel = 'prop_box_wood02a_pu',
    crateGroundOffset = 0.95,
    signal = {
        enabled = true,
        durationSeconds = 75,
        blipSprite = 161,
        blipColour = 1,
        blipScale = 0.95,
        markerDrawDistance = 650.0,
        flareWeapon = 'WEAPON_FLAREGUN',
        flareHeight = 85.0,
        flareSpeed = 145.0,
    },
}
