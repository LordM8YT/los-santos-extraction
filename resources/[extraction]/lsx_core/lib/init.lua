if LSXImport then return LSXImport end

local context = IsDuplicityVersion() and 'server' or 'client'

if not lib then
    if GetResourceState('ox_lib') ~= 'started' then
        error('ox_lib must be started before lsx_core.', 0)
    end

    local chunk = LoadResourceFile('ox_lib', 'init.lua')

    if not chunk then
        error('failed to load resource file @ox_lib/init.lua', 0)
    end

    load(chunk, '@@ox_lib/init.lua', 't')()
end

LSXImport = setmetatable({}, {
    __index = function(self, index)
        self[index] = function(...)
            return exports.lsx_core[index](...)
        end

        return self[index]
    end,
})

require(('@lsx_core.lib.%s.init'):format(context))

return LSXImport
