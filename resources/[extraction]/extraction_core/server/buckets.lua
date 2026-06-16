ExtractionCoreServer = ExtractionCoreServer or {}
ExtractionCoreServer.Buckets = {}

local allocatedByKey = {}
local keyByBucket = {}

local function normalizeKey(key)
    if key == nil or key == '' then
        return nil
    end

    return tostring(key)
end

local function getConfig()
    return ExtractionCoreConfig.Buckets
end

local function findFreeBucket()
    local config = getConfig()

    for offset = 0, config.raidRange - 1 do
        local bucket = config.raidBase + offset

        if not keyByBucket[bucket] then
            return bucket
        end
    end
end

function ExtractionCoreServer.Buckets.Allocate(key)
    key = normalizeKey(key)
    if not key then
        return nil, 'missing_key'
    end

    if allocatedByKey[key] then
        return allocatedByKey[key]
    end

    local bucket = findFreeBucket()
    if not bucket then
        return nil, 'bucket_pool_exhausted'
    end

    allocatedByKey[key] = bucket
    keyByBucket[bucket] = key

    ExtractionCoreServer.Logger.Debug('Allocated routing bucket.', {
        key = key,
        bucket = bucket,
    })

    return bucket
end

function ExtractionCoreServer.Buckets.Release(key)
    key = normalizeKey(key)
    if not key or not allocatedByKey[key] then
        return false
    end

    local bucket = allocatedByKey[key]
    allocatedByKey[key] = nil
    keyByBucket[bucket] = nil

    ExtractionCoreServer.Logger.Debug('Released routing bucket.', {
        key = key,
        bucket = bucket,
    })

    return true
end

function ExtractionCoreServer.Buckets.Get(key)
    key = normalizeKey(key)
    return key and allocatedByKey[key] or nil
end

function ExtractionCoreServer.Buckets.SetPlayerBucket(source, bucket)
    if not GetPlayerName(source) then
        return false, 'invalid_player'
    end

    SetPlayerRoutingBucket(source, bucket)
    return true
end

function ExtractionCoreServer.Buckets.MovePlayerToLobby(source)
    return ExtractionCoreServer.Buckets.SetPlayerBucket(source, getConfig().lobby)
end

function ExtractionCoreServer.Buckets.GetStats()
    return {
        allocated = ExtractionCoreShared.TableSize(allocatedByKey),
        base = getConfig().raidBase,
        range = getConfig().raidRange,
        lobby = getConfig().lobby,
    }
end

exports('AllocateBucket', function(key)
    return ExtractionCoreServer.Buckets.Allocate(key)
end)

exports('ReleaseBucket', function(key)
    return ExtractionCoreServer.Buckets.Release(key)
end)

exports('GetBucket', function(key)
    return ExtractionCoreServer.Buckets.Get(key)
end)

exports('SetPlayerBucket', function(source, bucket)
    return ExtractionCoreServer.Buckets.SetPlayerBucket(source, bucket)
end)

exports('MovePlayerToLobby', function(source)
    return ExtractionCoreServer.Buckets.MovePlayerToLobby(source)
end)

exports('GetBucketStats', function()
    return ExtractionCoreServer.Buckets.GetStats()
end)
