local function formatCoords(format)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    if format == "vec4" then
        return ("vec4(%.2f, %.2f, %.2f, %.2f)"):format(coords.x, coords.y, coords.z, heading)
    end

    if format == "table" then
        return ("{ x = %.2f, y = %.2f, z = %.2f, heading = %.2f }"):format(coords.x, coords.y, coords.z, heading)
    end

    return ("vec3(%.2f, %.2f, %.2f)"):format(coords.x, coords.y, coords.z)
end

local function requestCopy(format)
    TriggerServerEvent("extraction_admin:server:copyCoords", formatCoords(format))
end

RegisterCommand("copycoords", function(_, args)
    requestCopy(args[1])
end, false)

RegisterCommand("coords", function(_, args)
    requestCopy(args[1])
end, false)

RegisterNetEvent("extraction_admin:client:copyToClipboard", function(text)
    SendNUIMessage({
        action = "copy",
        text = text
    })
end)

RegisterNetEvent("extraction_admin:client:notify", function(message)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(false, false)
end)
