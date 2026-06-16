ExtractionCoreConfig = {
    Debug = false,

    Runtime = {
        projectName = 'Los Santos Extraction',
        version = '0.1.0',
    },

    Logging = {
        level = 'info',
        includeResource = true,
    },

    Identifiers = {
        preferred = {
            'license',
            'license2',
            'fivem',
            'steam',
            'discord',
        },
    },

    Buckets = {
        lobby = 0,
        raidBase = 7000,
        raidRange = 2000,
    },
}
