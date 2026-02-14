local smokeColors = {
    cyan = {0.0, 4.0, 10.0},
    blue = {0.0, 2.0, 15.0},
    red = {15.0, 0.0, 0.0},
    green = {1.0, 10.0, 0.0},
    pink = {4.0, 0.0, 4.0},
    purple = {1.0, 0.0, 5.0},
    yellow = {2.0, 4.0, 0.0},
    white = {15.0, 15.0, 15.0},
    black = {0.05, 0.05, 0.05}
}

local activeSmokes = {}
local lastSmokeTime = 0

function CreateMethSmoke(vehicle)
    if not Config.smoke.enabled then
        return
    end
    
    PROCESS_STARTED = true
    Debug("perform meth smoke")
    
    local previousTime = lastSmokeTime
    lastSmokeTime = GetGameTimer() + 5000
    
    if previousTime >= GetGameTimer() then
        return
    end
    
    if not NetworkGetEntityIsNetworked(vehicle) then
        print("^1Entity not networked. Could not create smoke")
        return
    end
    
    Citizen.CreateThread(function()
        local networkId = NetworkGetNetworkIdFromEntity(vehicle)
        TriggerServerEvent("kq_meth:server:startVanSmoke", networkId, GetEntityCoords(vehicle), COOK_TYPE)
        StartPedPoliceAlert()
        Citizen.Wait(5000)
        
        while lastSmokeTime >= GetGameTimer() do
            Citizen.Wait(100)
        end
        
        TriggerServerEvent("kq_meth:server:stopVanSmoke", networkId)
    end)
end

if Config.debug then
    RegisterCommand("methsmoke", function()
        local vehicle = GetClosestCookingVehicle(10.0)
        local networkId = NetworkGetNetworkIdFromEntity(vehicle)
        TriggerServerEvent("kq_meth:server:startVanSmoke", networkId, GetEntityCoords(vehicle), "meth")
        StartPedPoliceAlert()
    end)
    
    RegisterCommand("amphsmoke", function()
        local vehicle = GetClosestCookingVehicle(10.0)
        local networkId = NetworkGetNetworkIdFromEntity(vehicle)
        TriggerServerEvent("kq_meth:server:startVanSmoke", networkId, GetEntityCoords(vehicle), "amphetamines")
        StartPedPoliceAlert()
    end)
end

RegisterNetEvent("kq_meth:client:startVanSmoke")
AddEventHandler("kq_meth:client:startVanSmoke", function(networkId, coords, cookType)
    StartVanSmoke(networkId, coords, cookType)
end)

function StartVanSmoke(networkId, coords, cookType)
    if not NetworkDoesNetworkIdExist(networkId) then
        Debug("Network id not exists")
        return
    end
    
    Debug("starting smoke from net event")
    
    local particleAsset = "kq_meth"
    if not HasNamedPtfxAssetLoaded(particleAsset) then
        RequestNamedPtfxAsset(particleAsset)
        while not HasNamedPtfxAssetLoaded(particleAsset) do
            Citizen.Wait(1)
        end
    end
    
    UseParticleFxAsset(particleAsset)
    
    local particle = StartParticleFxLoopedAtCoord(
        "kq_meth_smoke",
        coords + vector3(0, 0, 1.8),
        vector3(0, 0, 0),
        Config.smoke.scale,
        0, 0, 0
    )
    
    Debug("Smoke started")
    SetParticleFxLoopedFarClipDist(particle, 500.0)
    
    local colorName = Config.smoke.color
    local color = smokeColors[colorName] or smokeColors.cyan
    
    if cookType == "amphetamines" then
        local alternativeColorName = Config.smoke.alternativeColor
        color = smokeColors[alternativeColorName] or smokeColors.white
    end
    
    SetParticleFxLoopedColour(particle, color[1], color[2], color[3], 0)
    
    activeSmokes[networkId] = particle
    
    Citizen.SetTimeout(300000, function()
        StopVanSmoke(networkId)
    end)
end

RegisterNetEvent("kq_meth:client:stopVanSmoke")
AddEventHandler("kq_meth:client:stopVanSmoke", function(networkId)
    StopVanSmoke(networkId)
end)

function StopVanSmoke(networkId)
    local particle = activeSmokes[networkId]
    if particle then
        StopParticleFxLooped(particle, 0)
        RemoveParticleFx(particle, true)
    end
    activeSmokes[networkId] = nil
end

function StartPedPoliceAlert()
    if not Config.policeAlerts.enabled then
        return
    end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    for i = 1, 4 do
        local alertPed = FindPedForPoliceAlert()
        if alertPed == nil then
            return
        end
        
        local policeAlerted = false
        
        Citizen.CreateThread(function()
            Citizen.Wait(math.random(5000, 15000))
            
            local endTime = GetGameTimer() + math.random(30000, 50000)
            local pedReachedPlayer = false
            local approachDistance = math.random(5, 15) + 0.0
            
            SetEntityAsMissionEntity(alertPed, 1, 1)
            
            while GetGameTimer() < endTime and DoesEntityExist(alertPed) and not IsPedDeadOrDying(alertPed) do
                local distance = #(playerCoords - GetEntityCoords(alertPed))
                Debug("ped coming", distance)
                
                if distance > approachDistance + 3.0 then
                    TaskGoToEntity(alertPed, PlayerPedId(), 60000, approachDistance, 1.75, 1073741824, 0)
                elseif not pedReachedPlayer then
                    pedReachedPlayer = true
                    
                    local scenarios = {
                        "WORLD_HUMAN_STAND_MOBILE_FACILITY",
                        "WORLD_HUMAN_MOBILE_FILM_SHOCKING",
                        "WORLD_HUMAN_TOURIST_MOBILE"
                    }
                    
                    TaskStartScenarioInPlace(alertPed, scenarios[math.random(1, #scenarios)], 0, 1)
                    Citizen.Wait(4000)
                    
                    if not IsPedDeadOrDying(alertPed) and not policeAlerted then
                        policeAlerted = true
                        
                        local dispatchTitles = Config.policeAlerts.dispatchTitles
                        local title = dispatchTitles[math.random(1, #dispatchTitles)]
                        
                        local dispatchMessages = Config.policeAlerts.dispatchMessages
                        local description = dispatchMessages[math.random(1, #dispatchMessages)]
                        
                        exports.kq_link:SendDispatchMessage({
                            coords = GetEntityCoords(alertPed),
                            jobs = Config.policeAlerts.policeJobs,
                            message = title,
                            description = description,
                            code = L("10-35"),
                            blip = Config.policeAlerts.blip
                        })
                    end
                end
                
                Citizen.Wait(2000)
            end
            
            if DoesEntityExist(alertPed) then
                ClearPedTasks(alertPed)
                TaskWanderStandard(alertPed, 10.0, 10)
            end
        end)
    end
end

local checkedPeds = {}

function FindPedForPoliceAlert()
    local peds = GetGamePool("CPed")
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    for _, ped in pairs(peds) do
        if IsPedHuman(ped) and not IsPedDeadOrDying(ped) and not IsPedAPlayer(ped) and not IsEntityAMissionEntity(ped) then
            local distance = #(playerCoords - GetEntityCoords(ped))
            local maxDistance = Config.policeAlerts.maxDistance or 100.0
            
            if distance < maxDistance then
                math.randomseed(ped)
                local chancePerPed = Config.policeAlerts.chancePerPed
                
                if chancePerPed > math.random(0, 100) then
                    if not checkedPeds[ped] then
                        checkedPeds[ped] = true
                        return ped, distance
                    end
                end
            end
        end
    end
    
    return nil
end