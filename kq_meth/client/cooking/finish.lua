function HandleFinish()
    local tray = COOKING_TRAY
    if tray then
        local liquidsCount = tray.GetLiquidsCount and tray.GetLiquidsCount() or 0
        if liquidsCount <= 0 or tray.interactingWith then
            return
        end
    else
        return
    end

    if COOK_TYPE == "meth" then
        if tray.liquids.meth then
            local liquidMethAmount = tray.liquids.liquid_meth and tray.liquids.liquid_meth.amount
            if liquidMethAmount and liquidMethAmount <= 10 then
                FinishCookingMeth(tray)
            end
        else
            if TRAY_TIMEOUT == nil then
                TRAY_TIMEOUT = GetGameTimer() + 20000
            end
            if TRAY_TIMEOUT < GetGameTimer() then
                FinishCookingMeth(tray)
                TRAY_TIMEOUT = nil
            end
        end
    end

    if COOK_TYPE == "amphetamines" then
        if not AMPHETAMINES_PROGRESSED then
            if tray.liquids.amphetamines then
                local liquidAmphetaminesAmount = tray.liquids.liquid_amphetamines and tray.liquids.liquid_amphetamines.amount
                if liquidAmphetaminesAmount and liquidAmphetaminesAmount <= 30 then
                    ProgressAmphetaminesCook(tray)
                end
            else
                if TRAY_TIMEOUT == nil then
                    TRAY_TIMEOUT = GetGameTimer() + 20000
                end
                if TRAY_TIMEOUT < GetGameTimer() then
                    FailAmphetaminesCook()
                    TRAY_TIMEOUT = nil
                end
            end
        end
    end
end

local function ProgressAmphetaminesCook(tray)
    AMPHETAMINES_PROGRESSED = true
    local vehicle = GetActiveVehicle()
    
    for resourceId, resource in pairs(RESOURCES) do
        if not resource.type.ignore then
            resource.SetInactive()
        end
    end
    
    RegisterDevice(vehicle, "mixer", {
        coords = vector3(0.0, 0.05, 0.0),
        rotation = vector3(0.0, 0.0, 75.0),
        button = {
            coords = vector3(0.1, -0.01, 0.0),
            rotation = vector3(0.0, 0.0, 0.0)
        }
    })
    
    RegisterDevice(vehicle, "scale", {
        coords = vector3(-0.14, -0.4, 0.0),
        rotation = vector3(0.0, 0.0, 90.0),
        button = {
            coords = vec3(0, 0, 0),
            rotation = vec3(0, 0, 0)
        }
    })
    
    MIXER_RESOURCE = RegisterResource(vehicle, "mixer", {
        coords = vector3(0.07, 0.035, 0.06),
        rotation = vector3(0.0, 0.0, 75.0)
    })
    
    local amphetaminesResource = RegisterResource(vehicle, "amphetamines", {
        coords = vector3(0.1, -0.6, 0.0),
        rotation = vector3(0.0, 0.0, 0.0)
    })
    
    for liquidName, liquidData in pairs(tray.liquids) do
        local amount = math.ceil(liquidData.amount * 0.6666) or 0
        amphetaminesResource.AddLiquid(liquidName, amount)
    end
    
    if AMPHETAMINES_CUTTING_COUNT > 0 then
        RegisterResource(vehicle, "amphetamines_cut_extra", {
            coords = vector3(0.0, 0.75, 0.0),
            rotation = vector3(0.0, 0.0, 342.0)
        })
    end
    
    for i = 1, math.min(20, AMPHETAMINES_CUTTING_COUNT * 10), 1 do
        local cutResource = RegisterResource(vehicle, "amphetamines_cut", {
            coords = vector3(-0.01, 0.75, 0.0),
            rotation = vector3(5.0, 0.0, 5.0)
        })
        cutResource.AddLiquid("amphetamines_cut", 50)
    end
    
    AMPHETAMINES_CUTTING_COUNT = 0
end
ProgressAmphetaminesCook = ProgressAmphetaminesCook

local function FinishAmphetaminesCook()
    local vehicle = GetActiveVehicle()
    local mixerResource = MIXER_RESOURCE
    local purity = 0
    
    if mixerResource.liquids.amphetamines then
        purity = mixerResource.GetLiquidsPurity({"amphetamines", "liquid_amphetamines"})
    end
    
    local totalAmount = 0
    for liquidName, liquidData in pairs(mixerResource.liquids or {}) do
        totalAmount = totalAmount + liquidData.amount
    end
    
    local itemAmount = CalculateAmphetaminesAmount(totalAmount)
    local itemName = GetAmphetaminesItemByPurity(purity)
    

    Debug("time", serverTimeCheck)
    
    if itemName ~= nil then
        DoMissionFinishAlert(true, purity, itemAmount, "amphetamines")
        TriggerServerEvent("kq_meth:server:cookingSuccess", 
            NetworkGetNetworkIdFromEntity(vehicle), 
            totalAmount, 
            purity,
            serverTimeCheck, 
            "amphetamines")
    else
        DoMissionFinishAlert(false, 0, 0, "amphetamines")
    end
    
    Citizen.Wait(3000)
    mixerResource.FadeOutDelete()
    Citizen.Wait(1000)
    StartExitVan(vehicle)
end
FinishAmphetaminesCook = FinishAmphetaminesCook

local function FailAmphetaminesCook()
    local vehicle = GetActiveVehicle()
    DoMissionFinishAlert(false, 0, 0, "amphetamines")
    Citizen.Wait(1000)
    StartExitVan(vehicle)
end
FailAmphetaminesCook = FailAmphetaminesCook

function FinishCookingMeth(tray)
    local vehicle = GetActiveVehicle()
    local methAmount = 0
    local purity = 0
    
    if tray.liquids.meth then
        methAmount = tray.liquids.meth.amount
        purity = tray.GetLiquidsPurity({"liquid_meth", "meth"})
    end
    
    local itemAmount = math.floor((methAmount / 1800) * Config.production.maxItemAmountPerBatch)
    local bestItem = nil
    local bestMinPurity = 0
    for _, purityConfig in pairs(Config.production.itemPerPurity) do
        if purity >= purityConfig.minimumPurity and bestMinPurity < purityConfig.minimumPurity then
            bestItem = purityConfig.item
            bestMinPurity = purityConfig.minimumPurity
        end
    end
    local itemName = bestItem
    

    Debug("time", serverTimeCheck)
    
    if itemName ~= nil then
        DoMissionFinishAlert(true, purity, itemAmount, "meth")
        TriggerServerEvent("kq_meth:server:cookingSuccess", 
            NetworkGetNetworkIdFromEntity(vehicle), 
            methAmount, 
            purity,
            serverTimeCheck, 
            "meth")
    else
        DoMissionFinishAlert(false, 0, 0, "meth")
    end
    
    Citizen.Wait(3000)
    tray.FadeOutDelete()
    Citizen.Wait(1000)
    StartExitVan(vehicle)
end

local function CalculateMethAmount(amount)
    return math.floor(amount / 1800 * Config.production.maxItemAmountPerBatch)
end
CalculateMethAmount = CalculateMethAmount

local function CalculateAmphetaminesAmount(amount)
    return math.floor(amount / 1000 * GetAmphetaminesData().production.itemsPer1000g)
end
CalculateAmphetaminesAmount = CalculateAmphetaminesAmount

local function GetMethItemByPurity(purity)
    local bestItem = nil
    local bestMinPurity = 0
    
    for _, purityConfig in pairs(Config.production.itemPerPurity) do
        if purity >= purityConfig.minimumPurity and bestMinPurity < purityConfig.minimumPurity then
            bestItem = purityConfig.item
            bestMinPurity = purityConfig.minimumPurity
        end
    end
    
    return bestItem, bestMinPurity
end
GetMethItemByPurity = GetMethItemByPurity

local function GetAmphetaminesItemByPurity(purity)
    local bestItem = nil
    local bestMinPurity = 0
    
    for _, purityConfig in pairs(GetAmphetaminesData().production.itemPerPurity) do
        if purity >= purityConfig.minimumPurity and bestMinPurity < purityConfig.minimumPurity then
            bestItem = purityConfig.item
            bestMinPurity = purityConfig.minimumPurity
        end
    end
    
    return bestItem, bestMinPurity
end
GetAmphetaminesItemByPurity = GetAmphetaminesItemByPurity

function DoMissionFinishAlert(success, purity, amount, drugType)
    local message = L("You failed to produce usable meth")
    local purityDisplay = math.floor(purity)
    
    if drugType == "amphetamines" then
        message = L("You failed to produce usable amphetamines")
    end
    
    if success then
        local successMessage = L("You successfully made {amount} grams of meth with purity of {purity}%")
        successMessage = successMessage:gsub("{amount}", amount)
        successMessage = successMessage:gsub("{purity}", purityDisplay)
        message = successMessage
        
        if drugType == "amphetamines" then
            successMessage = L("You successfully made {amount} grams of amphetamines with purity of {purity}%")
            successMessage = successMessage:gsub("{amount}", amount)
            successMessage = successMessage:gsub("{purity}", purityDisplay)
            message = successMessage
        end
    end
    
    Citizen.CreateThread(function()
        if not Config.finish.showBigAnnouncement then
            exports.kq_link:Notify(message, "info")
            return
        end
        
        local displayDuration = 8000
        local fadeTime = 150
        local endTime = GetGameTimer() + displayDuration
        
        local scaleform = RequestScaleformMovie("MIDSIZED_MESSAGE")
        while not HasScaleformMovieLoaded(scaleform) do
            Citizen.Wait(1)
        end
        
        BeginScaleformMovieMethod(scaleform, "SHOW_SHARD_MIDSIZED_MESSAGE")
        
        if drugType == "amphetamines" then
            _ENV["ScaleformMovieMethodAddParamTextureNameString"](L("Amphetamines production finished"))
        else
            _ENV["ScaleformMovieMethodAddParamTextureNameString"](L("Meth production finished"))
        end
        
        _ENV["ScaleformMovieMethodAddParamTextureNameString"](message)
        ScaleformMovieMethodAddParamInt(143)
        ScaleformMovieMethodAddParamBool(false)
        ScaleformMovieMethodAddParamBool(false)
        EndScaleformMovieMethod()
        
        local startTime = GetGameTimer()
        while GetGameTimer() < endTime do
            local currentTime = GetGameTimer()
            local opacity = 1.0
            
            if currentTime < startTime + fadeTime then
                opacity = (currentTime - startTime) / fadeTime
            elseif currentTime > endTime - fadeTime then
                opacity = (endTime - currentTime) / fadeTime
            end
            
            local yOffset = 0.5 - (0.25 * (1.0 - opacity))
            DrawScaleformMovie(scaleform, 0.5, yOffset, 0.9, opacity, 255, 255, 255, 255, 0)
            Citizen.Wait(1)
        end
        
        SetScaleformMovieAsNoLongerNeeded(scaleform)
    end)
end