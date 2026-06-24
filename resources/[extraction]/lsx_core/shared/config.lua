LSXConfig = {
    Debug = GetConvarInt('lsx:debug', 0) == 1,

    Project = {
        name = 'Los Santos Extraction',
        version = '0.1.0',
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

    Player = {
        defaultGroup = 'survivor',
        defaultGroupGrade = 1,
        defaultStatuses = {
            health = 100,
            armour = 0,
            stamina = 100,
        },
    },

    Compatibility = {
        -- Keep this false until we intentionally replace/bridge ox_core.
        emitOxEvents = GetConvarInt('lsx:emitOxEvents', 0) == 1,
    },

    Groups = {
        survivor = {
            name = 'survivor',
            label = 'Survivor',
            type = 'player',
            grades = {
                [1] = 'Operator',
            },
            principal = 'group.survivor',
            adminGrade = 99,
        },
        admin = {
            name = 'admin',
            label = 'Admin',
            type = 'staff',
            grades = {
                [1] = 'Moderator',
                [2] = 'Admin',
                [3] = 'Owner',
            },
            principal = 'group.admin',
            adminGrade = 2,
        },
    },
}
