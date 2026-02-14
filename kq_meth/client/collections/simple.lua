if Config.itemCollection and Config.itemCollection.ammonia then
    function SpawnSimpleLoot()
        local simpleConfig = Config.itemCollection.simple
        
        for lootKey, lootData in pairs(simpleConfig) do
            if lootData.enabled then
                local blipConfig = lootData.blip
                
                for locationKey, location in pairs(lootData.locations) do
                    DoRequestModel(lootData.model)
                    local object = CreateObject(lootData.model, location.coords + vector3(0, 0, 0.0), 0, 1, 0)
                    SetEntityRotation(object, location.rotation)
                    SetEntityInvincible(object, true)
                    FreezeEntityPosition(object, true)
                    
                    local keybindConfig = Config.keybinds.interact
                    
                    if location.blip then
                        CreateBlip(location.coords, blipConfig.sprite, blipConfig.color, blipConfig.alpha, blipConfig.scale, blipConfig.label)
                    end
                    
                    Citizen.SetTimeout(1000, function()
                        local promptText = L("~d~[~w~{input}~d~]~w~ Collect {label}")
                            :gsub("{input}", keybindConfig.label)
                            :gsub("{label}", lootData.label)
                        local menuText = L("Collect {label}"):gsub("{label}", lootData.label)
                        local interactionDistance = lootData.interactionDistance or 2.2
                        
                        exports.kq_link:AddInteractionEntity(
                            object,
                            vector(0, 0, 0),
                            promptText,
                            menuText,
                            keybindConfig.input,
                            CollectSimpleLoot,
                            CanCollectSimpleLoot,
                            {
                                lootKey = lootKey,
                                locationKey = locationKey
                            },
                            interactionDistance,
                            "fa fas-hand"
                        )
                    end)
                end
            end
        end
    end
    
    function CollectSimpleLoot(interaction)
        SetCooldown()
        
        local playerPed = PlayerPedId()
        local entity = interaction.GetEntity()
        local meta = interaction.GetMeta()
        local lootKey = meta.lootKey
        local locationKey = meta.locationKey
        
        RemoveHandWeapons()
        FaceCoordinates(GetEntityCoords(entity))
        
        local lootData = Config.itemCollection.simple[lootKey]
        local animation = lootData.animation
        local animDuration = 500
        local attachedObject = nil
        
        if animation then
            local animFlag = 0
            local entityCoords = GetEntityCoords(entity)
            local playerCoords = GetEntityCoords(playerPed)
            
            if playerCoords.z - 0.7 < entityCoords.z then
                animFlag = 16
            end
            
            PlayAnim(animation.dict, animation.name, animFlag)
            animDuration = GetAnimDuration(animation.dict, animation.name) * 1000
            
            local attachment = animation.attachment
            if attachment then
                DoRequestModel(attachment.holdModel)
                Citizen.Wait(attachment.delay)
                animDuration = animDuration - attachment.delay
                
                local bonePosition = GetEntityBonePosition_2(playerPed, GetPedBoneIndex(playerPed, attachment.bone))
                attachedObject = CreateObject(attachment.holdModel, bonePosition, 0, 1, 0)
                
                AttachEntityToEntity(
                    attachedObject,
                    playerPed,
                    GetPedBoneIndex(playerPed, attachment.bone),
                    attachment.offset,
                    attachment.rotation,
                    1, 0, 0, 0, 2, 1
                )
                
                SetEntityAlpha(attachedObject, 60)
                Citizen.Wait(50)
                SetEntityAlpha(attachedObject, 150)
                Citizen.Wait(50)
                ResetEntityAlpha(attachedObject)
            end
        end
        
        Citizen.Wait(animDuration - 225)
        
        if attachedObject then
            SetEntityAlpha(attachedObject, 200)
            Citizen.Wait(25)
            SetEntityAlpha(attachedObject, 150)
            Citizen.Wait(25)
            SetEntityAlpha(attachedObject, 100)
            Citizen.Wait(25)
            SetEntityAlpha(attachedObject, 50)
            Citizen.Wait(25)
            DeleteEntity(attachedObject)
        end
        
        ClearPedTasks(playerPed)
        TriggerServerEvent("kq_meth:server:simpleLoot", lootKey, locationKey)
    end
    
    function CanCollectSimpleLoot()
        return not IsCooldown(5000) and not IsPlayerUnreachable()
    end
    
    Citizen.Wait(1000)
    SpawnSimpleLoot()
end