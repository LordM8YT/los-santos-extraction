ExtractionHudConfig = {
    CombatView = {
        defaultFirstPersonMode = 'raid', -- raid | off
        defaultCrosshairMode = 'dynamic', -- dynamic | off
        defaultHelmetOverlay = 'on', -- on | off
        firstPersonEnforceIntervalMs = 300,
    },
    Minimap = {
        enabled = true,
        useNativeRadar = true,
        showOnlyInRaid = true,
        showOnFoot = true,
        showInVehicle = true,
        zoom = 1150,
        hideNorthBlip = true,
        hideNativeHealthArmor = true,
        forceSmallMap = true,
        enforceIntervalMs = 500,
        scannerRangeMeters = 220,
        Layout = {
            enabled = true,
            clipType = 1,
            components = {
                minimap = { alignX = 'L', alignY = 'B', posX = -0.0045, posY = -0.0280, sizeX = 0.1500, sizeY = 0.1889 },
                minimap_mask = { alignX = 'L', alignY = 'B', posX = 0.0200, posY = 0.0260, sizeX = 0.1110, sizeY = 0.1590 },
                minimap_blur = { alignX = 'L', alignY = 'B', posX = -0.0300, posY = -0.0060, sizeX = 0.2660, sizeY = 0.2370 },
            },
        },
    },
}
