serverTimeCheck = 0
serverTimeCheckDone = 0

function EnterCookingMode(vehicle)
    ResetGlobalValues()
    DeleteResources()
    DeleteDevices()
    SetCookingMode(true)
    
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, true)
    
    local vehicleSettings = GetVehicleSettings(vehicle)
    FreezeEntityPosition(vehicle, true)
    
    AttachEntityToEntity(playerPed, vehicle, 0, vehicleSettings.player.offset, vehicleSettings.player.rotation, 0, false, 0, 1, 0, 1)
    
    SetCookingCamera(vehicle)
    CookingThread(vehicle)
    SetEntityAlpha(playerPed, 0, true)
    SpawnBaseResources(vehicle)
    SpawnBaseDevices(vehicle)
    TriggerServerEvent("kq_meth:server:detectDrugCookTypes")
    PlayAnim("anim@amb@business@meth@meth_monitoring_cooking@cooking@", "base_idle_tank_cooker")
end

RegisterNetEvent("kq_meth:client:detectDrugCookTypes")
AddEventHandler("kq_meth:client:detectDrugCookTypes", function(items)
    if items.meth_lab_kit and items.amphetamines_lab_kit then
        SpawnModeSelectors()
    elseif items.meth_lab_kit then
        TriggerSpawnMethItemResources()
    elseif items.amphetamines_lab_kit then
        TriggerSpawnAmphetaminesItemResources()
    end
end)

function ExitCookingFully()
    local playerPed = PlayerPedId()
    FreezeEntityPosition(playerPed, false)
    ClearPedTasksImmediately(playerPed)
    DetachEntity(playerPed)
    ResetEntityAlpha(playerPed)
    ResetCookingCamera()
    Debug("ExitCookingMode", "ExitCookingFully")
    ExitCookingMode()
end

function ExitCookingMode()
    local activeVehicle = GetActiveVehicle()
    SetCookingMode(false)
    Debug(activeVehicle, NetworkGetNetworkIdFromEntity(activeVehicle))
    local refund = {}
    for _, resource in pairs(RESOURCES or {}) do
        if resource and resource.type and resource.type.key and resource.type.refundable and resource.entity and DoesEntityExist(resource.entity) and not resource.inactive then
            refund[resource.type.key] = true
        end
    end
    if next(refund) ~= nil then
        TriggerServerEvent('kq_meth:server:refundResources', refund)
    end
    TriggerServerEvent("kq_meth:server:stoppedCooking", NetworkGetNetworkIdFromEntity(activeVehicle))
    WipeCache("IsInCookingMode")
    FreezeEntityPosition(activeVehicle, false)
    if GetResourceState('_GM') == 'started' then
        exports['_GM']:UTILS():hideHelperKeys()
    end
    
    Citizen.SetTimeout(1000, function()
        DeleteResources(true)
        DeleteDevices()
        SetActiveVan(nil)
    end)
end

function GetVanTableOffsets()
    local vehicleSettings = GetVehicleSettings(GetActiveVehicle())
    if not vehicleSettings then
        return nil
    end
    
    local boundA = vehicleSettings.counter.boundA
    local boundB = vehicleSettings.counter.boundB
    return boundA, boundB
end

function SpawnBaseDevices(vehicle)
    local vehicleSettings = GetVehicleSettings(vehicle)
    
    if vehicleSettings.spawnStove then
        RegisterDevice(vehicle, "stove", {
            coords = vector3(0.047, 0.49, 0.0),
            rotation = vector3(0.0, 0.0, 0.0),
            button = {
                coords = vector3(0.21, 0.53, 0.003),
                rotation = vector3(0.0, 0.0, 0.0)
            }
        })
        
        RegisterDevice(vehicle, "stove", {
            coords = vector3(-0.162, 0.49, 0.0),
            rotation = vector3(0.0, 0.0, 0.0),
            button = {
                coords = vector3(0.21, 0.45, 0.003),
                rotation = vector3(0.0, 0.0, 0.0)
            }
        })
        
        RegisterResource(vehicle, "portable_stove", {
            coords = vector3(-0.064, 0.49, -0.023),
            rotation = vector3(0.0, 0.0, 0.0)
        })
    else
        RegisterDevice(vehicle, "stove", {
            coords = vector3(0.045, 0.49, 0.0),
            rotation = vector3(0.0, 0.0, 0.0),
            button = {
                coords = vector3(0.254, 0.52, 0.003),
                rotation = vector3(0.0, 0.0, 0.0)
            }
        })
        
        RegisterDevice(vehicle, "stove", {
            coords = vector3(-0.165, 0.49, 0.0),
            rotation = vector3(0.0, 0.0, 0.0),
            button = {
                coords = vector3(0.254, 0.42, 0.003),
                rotation = vector3(0.0, 0.0, 0.0)
            }
        })
    end
end

function SpawnBaseResources(vehicle)
    if not Config.removeSponge then
        RegisterResource(vehicle, "sponge", {
            coords = vector3(0.0, 0.8, 0.0),
            rotation = vector3(0.0, 0.0, 0.0)
        })
    end
    
    RegisterResource(vehicle, "lamp", {
        coords = vector3(-0.13, 0.0, 0.8),
        rotation = vector3(0.0, 0.0, 0.0)
    })
end

function SpawnModeSelectors()
    local activeVehicle = GetActiveVehicle()
    
    RegisterDevice(activeVehicle, "select_meth", {
        coords = vector3(-0.05, 0.5, 0.02),
        rotation = vector3(0.0, 0.0, 85.0),
        button = {
            coords = vector3(-0.1, 0.53, 0.01),
            rotation = vector3(0.0, 0.0, 0.0)
        }
    })
    
    RegisterDevice(activeVehicle, "select_amphetamines", {
        coords = vector3(0.0, -0.5, 0.0),
        rotation = vector3(0.0, 0.0, 0.0),
        button = {
            coords = vector3(-0.1, -0.5, 0.0),
            rotation = vector3(0.0, 0.0, 40.0)
        }
    })
end

function TriggerSpawnMethItemResources()
    COOK_TYPE = "meth"
    local activeVehicle = GetActiveVehicle()
    DeleteDevices()
    SpawnBaseDevices(activeVehicle)
    TriggerServerEvent("kq_meth:server:takeBaseMethResources")
end

RegisterNetEvent("kq_meth:client:spawnBaseMethResources")
AddEventHandler("kq_meth:client:spawnBaseMethResources", function(items, timeCheck)
    SpawnCookingItemResources(items)
    serverTimeCheck = timeCheck
    Debug("serverTimeCheck", serverTimeCheck)
    serverTimeCheckDone = 0
end)

function SpawnCookingItemResources(items)
    local activeVehicle = GetActiveVehicle()
    
    if items.meth_lab_kit then
        RegisterResource(activeVehicle, "pot", {
            coords = vector3(-0.15, 0.48, 0.0),
            rotation = vector3(0.0, 0.0, 90.0)
        })
        
        COOKING_TRAY = RegisterResource(activeVehicle, "tray", {
            coords = vector3(0.0, -0.1, 0.0),
            rotation = vector3(0.0, 0.0, 2.0)
        })
    end
    
    if items.acetone then
        local acetoneResource = RegisterResource(activeVehicle, "acetone", {
            coords = vector3(-0.19, -0.8, 0.0),
            rotation = vector3(0.0, 0.0, 100.0)
        })
        acetoneResource.AddLiquid("acetone", 1000)
        acetoneResource.AddLiquid("trash", 10)
    end
    
    if items.pills then
        local pillsResource = RegisterResource(activeVehicle, "pills", {
            coords = vector3(-0.1, -0.7, 0.0),
            rotation = vector3(0.0, 0.0, 100.0)
        })
        pillsResource.AddLiquid("pills", 100)
    end
    
    if items.ammonia then
        local ammoniaResource = RegisterResource(activeVehicle, "ammonia", {
            coords = vector3(-0.23, -0.62, 0.0),
            rotation = vector3(0.0, 0.0, 100.0)
        })
        ammoniaResource.AddLiquid("ammonia", 500)
    end
    
    if items.ethanol then
        local ethanolResource = RegisterResource(activeVehicle, "ethanol", {
            coords = vector3(-0.2, 0.8, 0.0),
            rotation = vector3(0.0, 0.0, 210.0)
        })
        ethanolResource.AddLiquid("ethanol", 400)
    end
    
    if items.lithium then
        local lithiumResource = RegisterResource(activeVehicle, "lithium", {
            coords = vector3(0.0, -0.75, 0.0),
            rotation = vector3(0.0, 0.0, 0.0)
        })
        lithiumResource.AddLiquid("lithium", 100)
        
        if items.lithium.amount >= 2 then
            local lithiumResource2 = RegisterResource(activeVehicle, "lithium", {
                coords = vector3(0.0, -0.775, 0.0),
                rotation = vector3(0.0, 0.0, 0.0)
            })
            lithiumResource2.AddLiquid("lithium", 100)
        end
        
        if items.lithium.amount >= 3 then
            local lithiumResource3 = RegisterResource(activeVehicle, "lithium", {
                coords = vector3(0.0, -0.8, 0.0),
                rotation = vector3(0.0, 0.0, 0.0)
            })
            lithiumResource3.AddLiquid("lithium", 100)
        end
    end
end

function TriggerSpawnAmphetaminesItemResources()
    COOK_TYPE = "amphetamines"
    local activeVehicle = GetActiveVehicle()
    DeleteDevices()
    SpawnBaseDevices(activeVehicle)
    TriggerServerEvent("kq_meth:server:takeBaseAmphetaminesResources")
end

RegisterNetEvent("kq_meth:client:spawnBaseAmphetaminesResources")
AddEventHandler("kq_meth:client:spawnBaseAmphetaminesResources", function(items, timeCheck)
    SpawnAmphetaminesItemResources(items)
    serverTimeCheck = timeCheck
    Debug("serverTimeCheck", serverTimeCheck)
    serverTimeCheckDone = 0
end)

function SpawnAmphetaminesItemResources(items)
    local activeVehicle = GetActiveVehicle()
    
    if items.amphetamines_lab_kit then
        RegisterResource(activeVehicle, "pot", {
            coords = vector3(-0.15, 0.48, 0.0),
            rotation = vector3(0.0, 0.0, 90.0)
        })
        
        COOKING_TRAY = RegisterResource(activeVehicle, "tray", {
            coords = vector3(0.0, -0.1, 0.0),
            rotation = vector3(0.0, 0.0, 2.0)
        })
    end
    
    if items.acetone then
        local acetoneResource = RegisterResource(activeVehicle, "acetone", {
            coords = vector3(-0.19, -0.8, 0.0),
            rotation = vector3(0.0, 0.0, 100.0)
        })
        acetoneResource.AddLiquid("acetone", 1000)
        acetoneResource.AddLiquid("trash", 10)
    end
    
    if items.amphetamines_cut then
        AMPHETAMINES_CUTTING_COUNT = items.amphetamines_cut.amount
    end
    
    if items.ammonia then
        local ammoniaResource = RegisterResource(activeVehicle, "ammonia", {
            coords = vector3(-0.23, -0.62, 0.0),
            rotation = vector3(0.0, 0.0, 100.0)
        })
        ammoniaResource.AddLiquid("ammonia", 500)
    end
    
    if items.sulfuric_acid then
        local sulfuricAcidResource = RegisterResource(activeVehicle, "sulfuric_acid", {
            coords = vector3(-0.1, -0.5, 0.0),
            rotation = vector3(0.0, 0.0, 100.0)
        })
        sulfuricAcidResource.AddLiquid("sulfuric_acid", 500)
    end
    
    if items.sodium then
        local sodiumResource = RegisterResource(activeVehicle, "sodium", {
            coords = vector3(0.1, -0.55, 0.0),
            rotation = vector3(0.0, 0.0, 100.0)
        })
        sodiumResource.AddLiquid("sodium", 500)
    end
end

function CookingThread(vehicle)
    Citizen.CreateThread(function()
        while IsInCookingMode() do
            DisableInputs()
            SetMouseCursorActiveThisFrame()
            SetEntityLocallyInvisible(PlayerPedId())
            Citizen.Wait(1)
        end
    end)
    
    local isDragging = false
    local isHoldingResource = false
    
    Citizen.CreateThread(function()
        while IsInCookingMode() do
            local waitTime = 200
            isDragging, isHoldingResource = HandleDragging()
            
            if isDragging then
                waitTime = 25
            end
            
            HandleInteraction(isDragging, isHoldingResource)
            Citizen.Wait(waitTime)
        end
    end)
    
    Citizen.CreateThread(function()
        while IsInCookingMode() do
            local waitTime = 300
            local deviceInteraction = nil
            
            if not isDragging and not isHoldingResource then
                deviceInteraction = HandleDevices()
            end
            
            if deviceInteraction then
                waitTime = 1
            end
            
            HandleCursorStyle(isDragging, isHoldingResource, deviceInteraction)
            Citizen.Wait(waitTime)
        end
    end)
    
    Debug("enter thread")
    
    Citizen.CreateThread(function()
        while IsInCookingMode() do
            local waitTime = 1000
            
            if Config.smoke.keepSmoking and PROCESS_STARTED then
                CreateMethSmoke(vehicle)
            end
            
            Debug("is cooking")
            HandleInterruptions()
            HandleFinish()
            Citizen.Wait(waitTime)
        end
    end)
end

function HandleInterruptions()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local activeVehicle = GetActiveVehicle()
    local vehicleCoords = GetEntityCoords(activeVehicle)
    local distance = #(playerCoords - vehicleCoords)
    
    if distance > 5.0 then
        ExitCookingFully()
        return
    end
    
    if IsEntityDead(playerPed) or IsPedRagdoll(playerPed) or GetVehicleEngineHealth(activeVehicle) <= 0.0 then
        ExitCookingFully()
        return
    end
end

function HandleDevices()
    local activeVehicle = GetActiveVehicle()
    local cursorX, cursorY, cursorZ = GetCursorCoordinates(activeVehicle)
    local clampedX, clampedCoords = ClampCoordsToCounter(cursorX)
    local nearestDevice = GetNearestDevice(clampedCoords)
    
    for _, device in pairs(GetAllDevices()) do
        if not (nearestDevice and device.entity == nearestDevice.entity) then
            if DoesEntityExist(device.entity) then
                SetEntityDrawOutline(device.entity, false)
            end
            
            if device.button and DoesEntityExist(device.button.entity) then
                SetEntityDrawOutline(device.button.entity, false)
            end
            
            if device.children then
                for _, child in pairs(device.children) do
                    if DoesEntityExist(child.entity) then
                        SetEntityDrawOutline(child.entity, false)
                    end
                end
            end
        end
    end
    
    if nearestDevice then
        if nearestDevice.type.modes and #nearestDevice.type.modes > 0 then
            local currentMode = nearestDevice.type.modes[nearestDevice.mode]
            Draw2DTextTimed(cursorY, cursorZ - 0.05, nearestDevice.type.label .. " [" .. currentMode.label .. "]", 0.3, 30)
            Draw2DTextTimed(cursorY, cursorZ - 0.03, "🖱️ " .. currentMode.nextOption, 0.25, 30)
        end
        
        if nearestDevice.type.trigger then
            Draw2DTextTimed(cursorY, cursorZ - 0.05, nearestDevice.type.trigger.label, 0.3, 30)
            
            if DoesEntityExist(nearestDevice.entity) then
                SetEntityDrawOutline(nearestDevice.entity, true)
            end
            
            if nearestDevice.button and DoesEntityExist(nearestDevice.button.entity) then
                SetEntityDrawOutline(nearestDevice.button.entity, true)
            end
            
            if nearestDevice.children then
                for _, child in pairs(nearestDevice.children) do
                    if DoesEntityExist(child.entity) then
                        SetEntityDrawOutline(child.entity, true)
                    end
                end
            end
            
            SetEntityDrawOutlineColor(255, 255, 255, 240)
            SetEntityDrawOutlineShader(1)
        end
        
        if IsControlJustReleased(0, Config.keybinds.stove.input) or IsDisabledControlJustReleased(0, Config.keybinds.stove.input) then
            nearestDevice.Interact()
        end
        
        return nearestDevice
    end
    
    return nil
end
