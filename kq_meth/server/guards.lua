
local spawnedGuards = {}
local initKey = math.random(1000000, 9999999)

GlobalState.kq_meth_init_key = initKey


local function SpawnGuard(guardConfig, guardIndex)
    local ped = CreatePed(4, GetHashKey(guardConfig.model), guardConfig.coords.x, guardConfig.coords.y, guardConfig.coords.z, guardConfig.heading, true, true)
    
    while not DoesEntityExist(ped) do
        Citizen.Wait(10)
    end
    

    Entity(ped).state:set("kq_meth_ped_base", {
        key = guardIndex,
        coords = guardConfig.coords,
        heading = guardConfig.heading,
        weapon = guardConfig.weapon,
        guard = guardConfig.zone,
        animation = guardConfig.animation,
    }, true)
    

    Entity(ped).state:set("kq_meth_ped_state", {
        status = "IDLE",
        targets = {},
        lastUpdate = GetNetworkTime(),
        netOwner = 0
    }, true)
    

    if guardConfig.weapon then
        GiveWeaponToPed(ped, GetHashKey(guardConfig.weapon), 250, false, true)
        SetCurrentPedWeapon(ped, GetHashKey(guardConfig.weapon), true)
    end

    SetPedMaxHealth(ped, 200)
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 100)
    
    SetPedCombatAbility(ped, 100)
    SetPedCombatRange(ped, 2)
    SetPedCombatAttributes(ped, 46, true)
    SetPedCombatAttributes(ped, 5, true) 
    SetPedFleeAttributes(ped, 0, false) 
    
    SetPedRelationshipGroupHash(ped, GetHashKey("HATES_PLAYER"))
    
    spawnedGuards[guardIndex] = {
        entity = ped,
        config = guardConfig,
        respawnTimer = nil
    }
    
    return ped
end


local function RespawnGuard(guardIndex)
    local guardData = spawnedGuards[guardIndex]
    if not guardData then
        return
    end
    

    if guardData.entity and DoesEntityExist(guardData.entity) then
        DeleteEntity(guardData.entity)
    end
    

    if guardData.respawnTimer then
        return
    end
    

    local respawnTime = (guardData.config.respawnTime or 300) * 1000
    
    guardData.respawnTimer = Citizen.SetTimeout(respawnTime, function()
        SpawnGuard(guardData.config, guardIndex)
        spawnedGuards[guardIndex].respawnTimer = nil
    end)
end

RegisterNetEvent("kq_meth:server:ped:respawn")
AddEventHandler("kq_meth:server:ped:respawn", function(guardIndex)
    RespawnGuard(guardIndex)
end)


Citizen.CreateThread(function()
    if not Config.guards or not Config.guards.enabled then
        return
    end
    

    Citizen.Wait(2000)
    

    AddRelationshipGroup("HATES_PLAYER")
    SetRelationshipBetweenGroups(5, GetHashKey("HATES_PLAYER"), GetHashKey("PLAYER"))
    SetRelationshipBetweenGroups(5, GetHashKey("PLAYER"), GetHashKey("HATES_PLAYER"))

    for guardIndex, guardConfig in pairs(Config.guards.peds) do
        SpawnGuard(guardConfig, guardIndex)
    end
end)


AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end
    
    for _, guardData in pairs(spawnedGuards) do
        if guardData.entity and DoesEntityExist(guardData.entity) then
            DeleteEntity(guardData.entity)
        end
    end
end)


if Config.debug then
    RegisterCommand("respawnguards", function(source, args)
        if source == 0 then
            for guardIndex, _ in pairs(spawnedGuards) do
                RespawnGuard(guardIndex)
            end
            print("All guards respawned")
        end
    end, true)
end