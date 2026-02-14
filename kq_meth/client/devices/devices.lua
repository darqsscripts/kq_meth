DEVICES = {}

DeviceTypes = {}

DeviceTypes.stove = {
    label = L("Stove"),
    model = nil,
    button = {
        entity = nil,
        model = "kq_stove_button",
        size = 0.01
    },
    modes = {
        {
            nextOption = L("Set heat to low"),
            label = L("~b~Off"),
            particleSize = 0.0,
            rotation = vector3(0, 0, 0)
        },
        {
            nextOption = L("Set heat to high"),
            label = L("~y~Low heat"),
            temperature = {
                temp = Config.recipe.cookingTemperature - math.random(5, 10),
                maxTemp = Config.recipe.cookingTemperature + math.random(30, 40),
                power = 0.2
            },
            particleSize = 0.15,
            particleAlpha = 0.2,
            rotation = vector3(0, 0, -25)
        },
        {
            nextOption = L("Turn off"),
            label = L("~r~High heat"),
            temperature = {
                temp = Config.recipe.cookingTemperature + math.random(10, 20),
                maxTemp = 200,
                power = 0.7
            },
            particleSize = 0.25,
            particleAlpha = 0.4,
            rotation = vector3(0, 0, -80)
        }
    }
}

DeviceTypes.scale = {
    label = L("Scale"),
    model = "kq_meth_scale",
    offset = vec3(0, 0, 0),
    scale = true,
    snaps = vec3(0.01, -0.01, 0.04)
}

DeviceTypes.mixer = {
    label = L("Start the mixer (End cutting)"),
    model = "kq_meth_mixer",
    offset = vec3(0, 0, 0),
    button = {
        entity = nil,
        model = "kq_stove_button",
        size = 0.06
    },
    trigger = {
        label = L("Start the mixer (End cutting)"),
        callback = function(device)
            local animDict = "anim@kq_amph_mixer"
            local animName = "kq_amph_mixer"
            local timeout = GetGameTimer() + 3000
            
            while not HasAnimDictLoaded(animDict) and GetGameTimer() < timeout do
                RequestAnimDict(animDict)
                Citizen.Wait(1)
            end
            
            PlayEntityAnim(device.entity, animName, animDict, 1000.0, false, true, false, 0, 1)
            SetEntityAnimSpeed(device.entity, animDict, animName, 4.0)
            
            Citizen.SetTimeout(4000, function()
                FinishAmphetaminesCook()
            end)
        end
    }
}

DeviceTypes.select_meth = {
    label = L("Cook Meth"),
    model = "kq_tray",
    offset = vec3(0, 0, 0.0),
    button = {
        entity = nil,
        model = "kq_pot",
        size = 0.3
    },
    children = {
        {
            model = "kq_thermometer",
            coords = vec3(0.15, -0.06, 0.015),
            rotation = vec3(90, 200, 180)
        }
    },
    trigger = {
        label = L("Cook Meth"),
        callback = function()
            DeleteDevices()
            TriggerSpawnMethItemResources()
        end
    }
}

DeviceTypes.select_amphetamines = {
    label = L("Cook Amphetamines"),
    model = nil,
    offset = vec3(0, 0, 0),
    button = {
        entity = nil,
        model = "kq_meth_mixer",
        size = 0.3
    },
    children = {
        {
            model = "kq_pot",
            coords = vec3(0.09, 0.14, 0.023),
            rotation = vec3(0, 0, 100)
        },
        {
            model = "kq_meth_scale",
            coords = vec3(0.13, 0.13, 0.0),
            rotation = vec3(0, 0, 80)
        }
    },
    trigger = {
        label = L("Cook Amphetamines"),
        callback = function()
            DeleteDevices()
            TriggerSpawnAmphetaminesItemResources()
        end
    }
}

function DeleteDevices()
    for _, device in pairs(DEVICES) do
        device.Delete()
    end
    
    DEVICES = {}
    
    for _, object in pairs(GetGamePool("CObject")) do
        if Entity(object).state.kq_meth_device or Entity(object).state.kq_meth_device_child then
            SetEntityAsMissionEntity(object, 1, 1)
            DeleteEntity(object)
        end
    end
end

function GetAllDevices()
    return DEVICES
end

function GetNearestDevice(position)
    return UseCache("GetNearestDeviceButton", function()
        local nearestDevice = nil
        local minDistance = 0.05
        
        for _, device in pairs(DEVICES) do
            if DoesEntityExist(device.button.entity) then
                local buttonPosition = GetOffsetFromEntityInWorldCoords(
                    device.button.entity,
                    device.type.offset or vec3(0, 0, 0)
                )
                local distance = #(position - buttonPosition) - device.type.button.size
                
                if distance < minDistance then
                    minDistance = distance
                    nearestDevice = device
                end
            end
        end
        
        return nearestDevice, minDistance
    end, 150)
end

function RegisterDevice(vehicle, deviceType, deviceData)
    local type = DeviceTypes[deviceType]
    if not type then
        error("Invalid device type:", deviceType)
        return nil
    end
    
    local device = {}
    device.id = GetGameTimer() .. "-" .. deviceType .. "-" .. math.random(0, 9999)
    device.type = DeviceTypes[deviceType]
    device.vehicle = vehicle
    device.mode = 1
    device.coords = deviceData.coords
    device.rotation = deviceData.rotation
    device.button = {
        coords = deviceData.button.coords,
        rotation = deviceData.button.rotation
    }
    device.children = {}
    device.entity = nil
    device.type.key = deviceType
    
    device.Setup = function()
        if device.entity and DoesEntityExist(device.entity) then
            DeleteEntity(device.entity)
            device.entity = nil
        end
        
        if device.type.model then
            local model = device.type.model
            DoRequestModel(model)
            
            device.entity = CreateObject(
                model,
                GetOffsetFromEntityInWorldCoords(device.vehicle, device.button.coords),
                false, 1, 0
            )
            
            Entity(device.entity).state:set("kq_meth_device", true)
            Entity(device.entity).state:set("kq_meth_device_vehicle", NetworkGetNetworkIdFromEntity(device.vehicle))
            
            SetEntityAsMissionEntity(device.entity, 1, 1)
            AttachEntityToEntity(
                device.entity,
                device.vehicle,
                0,
                CounterCoordsToVehicleCoords(device.coords),
                device.rotation,
                0, 0, false, 0, 5, 1
            )
        end
        
        device.SetupButton()
        device.SetupChildren()
    end
    
    device.SetupButton = function()
        if not device.type.button then
            return
        end
        
        if device.button.entity and DoesEntityExist(device.button.entity) then
            DeleteEntity(device.button.entity)
            device.button.entity = nil
        end
        
        local model = device.type.button.model
        DoRequestModel(model)
        
        device.button.entity = CreateObject(
            model,
            GetOffsetFromEntityInWorldCoords(device.vehicle, device.button.coords),
            false, 1, 0
        )
        
        Entity(device.button.entity).state:set("kq_meth_device", true)
        Entity(device.button.entity).state:set("kq_meth_device_vehicle", NetworkGetNetworkIdFromEntity(device.vehicle))
        
        SetEntityAsMissionEntity(device.button.entity, 1, 1)
        AttachEntityToEntity(
            device.button.entity,
            device.vehicle,
            0,
            CounterCoordsToVehicleCoords(device.button.coords),
            device.button.rotation,
            0, 0, false, 0, 5, 1
        )
    end
    
    device.SetupChildren = function()
        for index, childData in pairs(device.type.children or {}) do
            if device.children[index] and DoesEntityExist(device.children[index].entity) then
                DeleteEntity(device.children[index].entity)
                device.children[index].entity = nil
            end
            
            device.children[index] = {}
            
            local model = childData.model
            DoRequestModel(model)
            
            device.children[index].entity = CreateObject(
                model,
                GetOffsetFromEntityInWorldCoords(device.vehicle, childData.coords),
                false, 1, 0
            )
            
            Entity(device.button.entity).state:set("kq_meth_device", true)
            Entity(device.button.entity).state:set("kq_meth_device_vehicle", NetworkGetNetworkIdFromEntity(device.vehicle))
            
            SetEntityAsMissionEntity(device.children[index].entity, 1, 1)
            AttachEntityToEntity(
                device.children[index].entity,
                device.vehicle,
                0,
                CounterCoordsToVehicleCoords(childData.coords + device.coords),
                childData.rotation,
                0, 0, false, 0, 5, 1
            )
        end
    end
    
    device.Interact = function()
        if not device.type.button then
            return
        end
        
        if device.type.modes and #device.type.modes > 0 then
            device.mode = device.mode + 1
            if device.mode > #device.type.modes then
                device.mode = 1
            end
            
            local currentMode = device.type.modes[device.mode]
            AttachEntityToEntity(
                device.button.entity,
                device.vehicle,
                0,
                CounterCoordsToVehicleCoords(device.button.coords),
                device.button.rotation + currentMode.rotation,
                0, 0, false, 0, 5, 1
            )
        end
        
        if device.type.trigger and device.type.trigger.callback then
            device.type.trigger.callback(device)
        end
    end
    
    device.GeneralThread = function()
        while device do
            local waitTime = 200
            
            if device.type.snaps then
                local nearestResource = GetNearestResource(
                    GetOffsetFromEntityInWorldCoords(device.vehicle, CounterCoordsToVehicleCoords(device.coords)),
                    false,
                    nil,
                    device.id
                )
                
                local isAttached = device.snappedEntity and IsEntityAttachedToEntity(device.snappedEntity, device.entity)
                
                if not isAttached and nearestResource and not nearestResource.beingUsed and not nearestResource.beingDragged then
                    AttachEntityToEntity(
                        nearestResource.entity,
                        device.entity,
                        0,
                        device.type.snaps,
                        vec3(0, 0, 0),
                        0, 0, false, 0, 5, 1
                    )
                    device.snappedEntity = nearestResource.entity
                end
            end
            
            if device.type.scale then
                local nearestResource = GetNearestResource(
                    GetOffsetFromEntityInWorldCoords(device.vehicle, CounterCoordsToVehicleCoords(device.coords)),
                    false,
                    nil,
                    device.id
                )
                
                if nearestResource then
                    local displayPosition = GetOffsetFromEntityInWorldCoords(device.entity, vector3(-0.016, -0.074, 0.0))
                    local screenX, screenY, onScreen = UseCache(
                        "screenEntityCoords" .. device.coords.x .. "-" .. device.coords.y,
                        function()
                            return GetScreenCoordFromWorldCoord(table.unpack(displayPosition))
                        end,
                        10
                    )
                    
                    local totalWeight = 0
                    for _, liquid in pairs(nearestResource.liquids or {}) do
                        totalWeight = totalWeight + liquid.amount
                    end
                    
                    waitTime = 1
                    DrawDisplayText(
                        screenX,
                        screenY,
                        displayPosition,
                        L("{weight}g"):gsub("{weight}", totalWeight)
                    )
                end
            elseif device.type.modes and #device.type.modes > 0 then
                local currentMode = device.type.modes[device.mode]
                
                if currentMode.particleSize > 0.0 then
                    device.DrawFlamesInCircle(10, 0.03, currentMode)
                    device.CreateParticles(
                        "veh_thruster",
                        "veh_xm_thruster_afterburner",
                        0.7,
                        vector3(0.0, 0.0, 0.045),
                        200,
                        currentMode.particleAlpha,
                        false
                    )
                end
                
                if currentMode.temperature then
                    local nearestResource = GetNearestResource(
                        GetOffsetFromEntityInWorldCoords(device.vehicle, CounterCoordsToVehicleCoords(device.coords)),
                        false,
                        nil,
                        device.id
                    )
                    
                    if nearestResource and not nearestResource.type.cantHeat then
                        if currentMode.temperature.temp > nearestResource.temperature then
                            nearestResource.temperature = nearestResource.temperature + currentMode.temperature.power + 0.375
                        elseif currentMode.temperature.maxTemp > nearestResource.temperature then
                            nearestResource.temperature = nearestResource.temperature + (currentMode.temperature.power * 0.5) + 0.375
                        end
                    end
                end
            end
            
            Citizen.Wait(waitTime)
        end
    end
    
    device.DrawFlamesInCircle = function(numFlames, radius, mode)
        local angleStep = (2 * math.pi) / numFlames
        
        for i = 0, numFlames - 1, 1 do
            local angle = i * angleStep
            local x = radius * math.cos(angle)
            local y = radius * math.sin(angle)
            
            device.CreateParticles(
                "core",
                "ent_amb_candle_flame",
                mode.particleSize,
                vector3(x, y, 0.0),
                400,
                mode.particleAlpha,
                false
            )
        end
    end
    
    device.CreateParticles = function(assetName, particleName, scale, offset, duration, alpha, networked)
        Citizen.CreateThread(function()
            if not HasNamedPtfxAssetLoaded(assetName) then
                RequestNamedPtfxAsset(assetName)
                while not HasNamedPtfxAssetLoaded(assetName) do
                    Citizen.Wait(1)
                end
            end
            
            if not device then
                return
            end
            
            local particleHandle = nil
            
            if networked then
                SetPtfxAssetNextCall(assetName)
                particleHandle = StartNetworkedParticleFxLoopedOnEntity(
                    particleName,
                    device.vehicle,
                    CounterCoordsToVehicleCoords(device.coords + offset),
                    0.0, 0.0, 0.0,
                    scale,
                    0, 0, 0
                )
            else
                SetPtfxAssetNextCall(assetName)
                particleHandle = StartParticleFxLoopedOnEntity(
                    particleName,
                    device.vehicle,
                    CounterCoordsToVehicleCoords(device.coords + offset),
                    0.0, 0.0, 0.0,
                    scale,
                    0, 0, 0
                )
            end
            
            SetParticleFxLoopedAlpha(particleHandle, alpha or 1.0)
            SetParticleFxLoopedColour(particleHandle, 1.0, 1.0, 0.0, 0)
            
            Citizen.Wait(duration)
            
            StopParticleFxLooped(particleHandle, 0)
            RemoveParticleFx(particleHandle, true)
        end)
    end
    
    device.Delete = function()
        if not device then
            return
        end
        
        if device.entity then
            DeleteEntity(device.entity)
        end
        
        if device.button.entity then
            DeleteEntity(device.button.entity)
        end
        
        for _, child in pairs(device.children or {}) do
            DeleteEntity(child.entity)
        end
        
        device = nil
        return true
    end
    
    Citizen.CreateThread(function()
        device.GeneralThread()
    end)
    
    table.insert(DEVICES, device)
    device.Setup()
    
    return device
end