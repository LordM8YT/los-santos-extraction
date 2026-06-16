ExtractionCoreConstants = {
    RaidState = {
        Idle = 'idle',
        Starting = 'starting',
        Active = 'active',
        Extracting = 'extracting',
        Completed = 'completed',
        Failed = 'failed',
    },

    RaidEndReason = {
        Extracted = 'extracted',
        Dead = 'dead',
        Timeout = 'timeout',
        Left = 'left',
        Kicked = 'kicked',
    },

    Events = {
        CoreReady = 'extraction_core:server:ready',
        PlayerReady = 'extraction_core:server:playerReady',
        PlayerDropped = 'extraction_core:server:playerDropped',
    },
}
