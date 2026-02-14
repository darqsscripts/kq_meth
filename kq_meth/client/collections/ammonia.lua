local spawnedTanks = {}

if Config.itemCollection and Config.itemCollection.ammonia then
    function SpawnAmmoniaTanks()
        local ammoniaConfig = Config.itemCollection.ammonia
        local blipConfig = Config.itemCollection.ammonia.blip
        
        for tankIndex, location in pairs(ammoniaConfig.locations) do
            DoRequestModel(ammoniaConfig.model)
            local tankEntity = CreateObject(ammoniaConfig.model, location.coords + vector3(0, 0, -1.05), 0, 1, 0)
            SetEntityRotation(tankEntity, location.rotation)
            SetEntityInvincible(tankEntity, true)
            FreezeEntityPosition(tankEntity, true)
            
            local valveConfig = ammoniaConfig.valve
            DoRequestModel(valveConfig.model)
            local valveEntity = CreateObject(valveConfig.model, GetOffsetFromEntityInWorldCoords(tankEntity, valveConfig.offset.coords), 0, 1, 0)
            SetEntityRotation(valveEntity, GetEntityRotation(tankEntity) + valveConfig.offset.rotation)
            SetEntityInvincible(valveEntity, true)
            FreezeEntityPosition(valveEntity, true)
            
            AddTankInteraction(valveEntity, GetOffsetFromEntityInWorldCoords(tankEntity, valveConfig.offset.coords + vector3(0.9, 0, 1.1)), tankIndex)
            
            if location.blip then
                CreateBlip(location.coords, blipConfig.sprite, blipConfig.color, blipConfig.alpha, blipConfig.scale, blipConfig.label)
            end
            
            spawnedTanks[tankIndex] = {
                tank = tankEntity,
                valve = valveEntity
            }
        end
    end
    
    function AddTankInteraction(valveEntity, interactionCoords, tankIndex)
        local keybindConfig = Config.keybinds.interact
        exports.kq_link:AddInteractionZone(
            interactionCoords,
            GetEntityRotation(valveEntity),
            vector3(1.5, 1.5, 2.3),
            L("~d~[~w~{input}~d~]~w~ Open the valve"):gsub("{input}", keybindConfig.label),
            L("Open the valve"),
            keybindConfig.input,
            InteractWithValve,
            CanInteractWithValve,
            { valve = valveEntity, tankIndex = tankIndex },
            1.5,
            "fa fas-glass"
        )
    end
    
    function InteractWithValve(interactionData)
        SetCooldown()
        local metadata = interactionData.GetMeta()
        local valveEntity = metadata.valve
        local playerPed = PlayerPedId()
        
        local syncScene = NetworkCreateSynchronisedScene(
            GetEntityCoords(valveEntity),
            GetEntityRotation(valveEntity),
            2, true, false, 8.0, 1000.0, 1.0
        )
        
        local animDict = "anim@scripted@freemode@kq_meth_valve@"
        local playerAnim = "action"
        local valveAnim = "action_oilwellhead"
        local timeout = GetGameTimer() + 3000
        
        while not HasAnimDictLoaded(animDict) and GetGameTimer() < timeout do
            RequestAnimDict(animDict)
            Citizen.Wait(1)
        end
        
        local animDuration = 1000
        
        if GetGameTimer() >= timeout then
            Debug("Using an outdated game build. Valve animation not possible. Update to 3095 or newer.")
            TriggerServerEvent("kq_meth:server:takeAmmonia", metadata.tankIndex)
            ClearPedTasks(playerPed)
            return
        end
        
        NetworkAddPedToSynchronisedScene(playerPed, syncScene, animDict, playerAnim, 1000.0, 8.0, 1, 16, 1148846080, 0)
        PlayEntityAnim(valveEntity, valveAnim, animDict, 1000.0, false, false, false, 0, 0)
        NetworkStartSynchronisedScene(syncScene)
        
        animDuration = GetAnimDuration(animDict, playerAnim) * 1000
        
        Citizen.Wait(animDuration / 2)
        TriggerServerEvent("kq_meth:server:takeAmmonia", metadata.tankIndex)
        Citizen.Wait(animDuration / 2)
        
        NetworkStopSynchronisedScene(syncScene)
    end
    
    RegisterNetEvent("kq_meth:client:pourAmmoniaFromValve")
    AddEventHandler("kq_meth:client:pourAmmoniaFromValve", function(tankIndex)
        local tankData = spawnedTanks[tankIndex]
        local pourCoords = GetOffsetFromEntityInWorldCoords(tankData.tank, vector3(2.9, -0.25, 0.4))
        
        local particleDict = "core"
        if not HasNamedPtfxAssetLoaded(particleDict) then
            RequestNamedPtfxAsset(particleDict)
            while not HasNamedPtfxAssetLoaded(particleDict) do
                Citizen.Wait(1)
            end
        end
        
        SetPtfxAssetNextCall(particleDict)
        local particleEffect = StartParticleFxLoopedAtCoord("ent_sht_beer_barrel", pourCoords, 0.0, 0.0, 0.0, 2.0, 1.0, 1.0, 1.0, 0)
        
        Citizen.Wait(4000)
        
        StopParticleFxLooped(particleEffect, 0)
        RemoveParticleFx(particleEffect, true)
    end)
    
    function CanInteractWithValve()
        return not IsCooldown(5000) and not IsPlayerUnreachable()
    end
    
    Citizen.Wait(1000)
    SpawnAmmoniaTanks()
end