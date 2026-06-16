if not Config.Population or not Config.Population.enabled then
    return
end

local population = Config.Population

local function disableDispatchServices()
    if population.dispatchServices ~= false then
        return
    end

    for service = 1, 15 do
        EnableDispatchService(service, false)
    end
end

CreateThread(function()
    SetGarbageTrucks(population.garbageTrucks == true)
    SetRandomBoats(population.randomBoats == true)

    if population.randomCops == false then
        SetCreateRandomCops(false)
        SetCreateRandomCopsOnScenarios(false)
        SetCreateRandomCopsNotOnScenarios(false)
    end

    disableDispatchServices()

    while true do
        SetPedDensityMultiplierThisFrame(population.pedestrianDensity or 0.0)
        SetScenarioPedDensityMultiplierThisFrame(
            population.scenarioPedDensity or 0.0,
            population.scenarioPedDensity or 0.0
        )
        SetVehicleDensityMultiplierThisFrame(population.vehicleDensity or 0.0)
        SetRandomVehicleDensityMultiplierThisFrame(population.randomVehicleDensity or 0.0)
        SetParkedVehicleDensityMultiplierThisFrame(population.parkedVehicleDensity or 0.0)

        if population.randomCops == false then
            SetCreateRandomCops(false)
            SetCreateRandomCopsOnScenarios(false)
            SetCreateRandomCopsNotOnScenarios(false)
            SetDispatchCopsForPlayer(PlayerId(), false)
        end

        if population.dispatchServices == false then
            disableDispatchServices()
        end

        Wait(0)
    end
end)
