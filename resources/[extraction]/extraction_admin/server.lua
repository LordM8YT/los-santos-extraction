local permission = "easyadmin"

RegisterNetEvent("extraction_admin:server:copyCoords", function(text)
    local source = source

    if not IsPlayerAceAllowed(source, permission) then
        TriggerClientEvent("extraction_admin:client:notify", source, "You do not have permission to copy admin coords.")
        return
    end

    TriggerClientEvent("extraction_admin:client:copyToClipboard", source, text)
    TriggerClientEvent("extraction_admin:client:notify", source, ("Copied coords: %s"):format(text))
end)
