
local gmHelperShown = false
Citizen.CreateThread(function()
    while true do
        local sleep = 3000
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        if IsInCookingMode() then
            sleep = 1
            if not gmHelperShown and GetResourceState('_GM') == 'started' then
                exports['_GM']:UTILS():showHelperKeys({ ['F'] = 'Maintenir F pour sortir' })
                gmHelperShown = true
            end
            local holdTime = 0
            local exiting = false
            
            while IsDisabledControlPressed(0, Config.keybinds.exit.input) and not exiting do
                if holdTime > 1000 then
                    exiting = true
                    StartExitVan(GetActiveVehicle())
                end
                holdTime = holdTime + 50
                Citizen.Wait(50)
            end
            
            if not exiting and holdTime > 0 then
            end
        else
            if gmHelperShown and GetResourceState('_GM') == 'started' then
                exports['_GM']:UTILS():hideHelperKeys()
                gmHelperShown = false
            end
            local vehicle, distance, model = GetClosestCookingVehicle(5.0)
            local vehicleSettings = Settings.vehicles[model]
            
            sleep = 1000
            if vehicle and CanEnterVan(vehicle) and NetworkGetEntityIsNetworked(vehicle) then
                sleep = 500
                local enterZone = UseCache('enterZone' .. vehicle, function()
                    return GetOffsetFromEntityInWorldCoords(vehicle, vehicleSettings.enterZone.offset)
                end)
                
                local enterDistance = #(playerCoords - enterZone)
                
                if enterDistance < vehicleSettings.enterZone.radius then
                    sleep = 1
                    if IsControlJustPressed(0, Config.keybinds.enter.input) then
                        if not IsVanOccupied(vehicle) and GetPedInVehicleSeat(vehicle, -1) == 0 then
                            if not IsVehicleUnderground(vehicle) then
                                SetEntityAsMissionEntity(vehicle, false, false)
                                NetworkRegisterEntityAsNetworked(vehicle)
                                StartEnterVan(vehicle)
                            else
                                exports.kq_link:Notify(L('You can not cook when underground'), 'error')
                                Citizen.Wait(500)
                            end
                        else
                            Debug('Someone else is inside in this vehicle already')
                        end
                    end
                end
            end
        end
        
        Citizen.Wait(sleep)
    end
end)

function GetClosestCookingVehicle(maxDistance)
    return UseCache('GetClosestCookingVehicle' .. maxDistance, function()
        local closestDist = maxDistance
        local closestVehicle = nil
        local closestModel = nil
        
        for model, settings in pairs(Settings.vehicles) do
            if settings.enabled then
                local vehicle, distance = GetClosestVehicleWithModel(model, maxDistance)
                if distance < closestDist then
                    closestVehicle = vehicle
                    closestDist = distance
                    closestModel = model
                end
            end
        end
        
        return closestVehicle, closestDist, closestModel
    end, 1000)
end

function CreateBlip(coords, sprite, color, alpha, scale, message)
    local blip = AddBlipForCoord(coords)
    
    SetBlipSprite(blip, sprite)
    SetBlipHighDetail(blip, true)
    SetBlipColour(blip, color)
    SetBlipAlpha(blip, alpha)
    SetBlipScale(blip, scale)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(message)
    EndTextCommandSetBlipName(blip)
    SetBlipAsShortRange(blip, true)
    
    return blip
end

function CanEnterVan(vehicle)
    return UseCache('canEnterVan' .. vehicle, function()
        local playerPed = PlayerPedId()
        
        if GetEntitySpeed(vehicle) > 0.5 then
            return false
        end
        
        if IsPlayerUnreachable(playerPed) or GetVehicleEngineHealth(vehicle) <= 0.0 then
            return false
        end
        
        if Contains({2, 3, 4, 10}, GetVehicleDoorLockStatus(vehicle)) then
            return false
        end
        
        return true
    end, 200)
end

function IsPlayerUnreachable()
    local playerPed = PlayerPedId()
    return IsPedInAnyVehicle(playerPed) or IsPedRagdoll(playerPed) or IsEntityDead(playerPed)
end

function IsVehicleUnderground(vehicle)
    if Config.production.disallowCookingWhenUnderground == false then
        return false
    end
    
    local coords = GetEntityCoords(vehicle)
    
    local tunnels = {9, 12, 6, 15, 7, 3, 21, 4, 18, 5}
    if Contains(tunnels, GetInteriorGroupId(GetInteriorAtCoords(coords))) then
        return true
    end
    
    local _, z = GetGroundZFor_3dCoord(coords.x, coords.y, 900.0, true)
    if z == 0.0 then
        z = GetHeightmapTopZForPosition(coords.x, coords.y)
    end
    
    return (z - 6) > coords.z
end


function IsWearingAGasMask()
    return UseCache('IsWearingAGasMask', function()

        for model, masks in pairs(Config.gasMask.ids) do
            Config.gasMask.ids[GetHashKey(model)] = masks
        end
        
        local playerPed = PlayerPedId()
        local playerMask = GetPedDrawableVariation(playerPed, 1)
        
        local model = GetEntityModel(playerPed)
        local maskIds = Config.gasMask.ids[model]
        return Contains(maskIds or {}, playerMask)
    end, 5000)
end

function ShowTooltip(message)
    SetTextComponentFormat("STRING")
    AddTextComponentString(message)
    EndTextCommandDisplayHelp(0, 0, 1, 2500)
end


function DrawMissionText(text, time)
    SetTextEntry_2("STRING")
    AddTextComponentString(text)
    DrawSubtitleTimed(time or 30000, 1)
end

function Draw2DText(x, y, text, scale)
    scale = scale * (Config.textScale or 1)
    SetTextFont(Config.textFont or 4)
    SetTextProportional(1)
    SetTextScale(scale, scale)
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    EndTextCommandDisplayText(x, y)
end

function DrawDisplayText(x, y, coords, text)
    SetTextFont(Config.textFont or 4)
    
    local camCoords = GetGameplayCamCoords()
    local dist = #(camCoords - coords)
    local scale = (1 / dist) * 0.39
    
    SetTextProportional(1)
    SetTextScale(scale, scale)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    SetTextJustification(0)
    SetTextCentre(1)
    SetTextColour(255, 0, 0, 120)
    EndTextCommandDisplayText(x, y)
end

function Draw3DText(coords, textInput, scaleX)
    scaleX = scaleX * (Config.textScale or 1)
    local camCoords = GetGameplayCamCoords()
    local dist = #(camCoords - coords)
    local scale = (1 / dist) * 20
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov
    
    SetTextScale(scaleX * scale, scaleX * scale)
    SetTextFont(Config.textFont or 4)
    SetTextProportional(1)
    SetTextDropshadow(1, 1, 1, 1, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(textInput)
    SetDrawOrigin(coords, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

function Draw3DFlatText(coords, textInput, scaleX)
    scaleX = scaleX * (Config.textScale or 1)
    local camCoords = GetGameplayCamCoords()
    local dist = #(camCoords - coords)
    local scale = (1 / dist) * 20
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov
    
    SetTextScale(scaleX * scale, scaleX * scale)
    SetTextFont(Config.textFont or 4)
    SetTextProportional(1)
    SetTextDropshadow(1, 1, 1, 1, 255)
    SetTextEdge(2, 0, 0, 0, 150)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(textInput)
    SetDrawOrigin(coords, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end
