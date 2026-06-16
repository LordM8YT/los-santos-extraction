ExtractionCoreServer = ExtractionCoreServer or {}

local levelPriority = {
    debug = 10,
    info = 20,
    warn = 30,
    error = 40,
}

local function shouldLog(level)
    local configured = ExtractionCoreConfig.Logging.level or 'info'
    return (levelPriority[level] or levelPriority.info) >= (levelPriority[configured] or levelPriority.info)
end

local function encodeContext(context)
    if context == nil then
        return nil
    end

    if type(context) ~= 'table' then
        return tostring(context)
    end

    local ok, encoded = pcall(json.encode, context)
    return ok and encoded or '<context_encode_failed>'
end

local function log(level, message, context)
    if not shouldLog(level) then
        return
    end

    local prefix = ('[%s]'):format(level:upper())
    if ExtractionCoreConfig.Logging.includeResource then
        prefix = ('[%s]%s'):format(GetCurrentResourceName(), prefix)
    end

    local encodedContext = encodeContext(context)
    if encodedContext then
        print(('%s %s %s'):format(prefix, tostring(message), encodedContext))
    else
        print(('%s %s'):format(prefix, tostring(message)))
    end
end

ExtractionCoreServer.Logger = {
    Debug = function(message, context) log('debug', message, context) end,
    Info = function(message, context) log('info', message, context) end,
    Warn = function(message, context) log('warn', message, context) end,
    Error = function(message, context) log('error', message, context) end,
}
